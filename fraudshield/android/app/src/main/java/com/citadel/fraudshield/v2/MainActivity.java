package com.citadel.fraudshield.v2;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.work.Constraints;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.NetworkType;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;

import com.google.android.play.core.integrity.IntegrityManager;
import com.google.android.play.core.integrity.IntegrityManagerFactory;
import com.google.android.play.core.integrity.IntegrityTokenRequest;
import com.google.android.play.core.integrity.IntegrityTokenResponse;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/**
 * MainActivity sets up platform channels and native Android integrations.
 * Converted from Kotlin to Java to bypass K2 compiler bug
 * (FirIncompatibleClassExpressionChecker crash on anonymous objects).
 */
public class MainActivity extends FlutterActivity {

    private static final String SETTINGS_CHANNEL = "com.citadel.fraudshield/settings";
    private static final String CALL_ATTESTATION_CHANNEL = "com.citadel.fraudshield/call_attestation";
    private static final String SCANNER_CHANNEL = "com.citadel.fraudshield/scanner";
    private static final String ATTESTATION_CHANNEL = "com.citadel.fraudshield/attestation";
    private static final String CALL_SCREENING_CHANNEL = "com.citadel.fraudshield/call_screening";
    private static final String SYSTEM_CHANNEL = "com.citadel.fraudshield/system";
    private static final String ROLE_CHANNEL = "com.citadel.fraudshield/role";
    private static final String SCANNER_PROGRESS_CHANNEL = "com.citadel.fraudshield/scanner_progress";
    private static final int REQUEST_CODE_CALL_SCREENING_ROLE = 1001;

    private EventChannel.EventSink progressEventSink = null;
    private final HashMap<String, Integer> lastVerificationStatus = new HashMap<>();
    private MethodChannel.Result pendingRoleResult = null;

    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (TelephonyManager.ACTION_PHONE_STATE_CHANGED.equals(action)) {
                String state = intent.getStringExtra(TelephonyManager.EXTRA_STATE);
                if (TelephonyManager.EXTRA_STATE_RINGING.equals(state)) {
                    @SuppressWarnings("deprecation")
                    String incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER);
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        String extraVerificationStatus = "android.telecom.extra.VERIFICATION_STATUS";
                        if (intent.hasExtra(extraVerificationStatus)) {
                            int status = intent.getIntExtra(extraVerificationStatus,
                                    android.telecom.Connection.VERIFICATION_STATUS_NOT_VERIFIED);
                            if (incomingNumber != null) {
                                lastVerificationStatus.put(incomingNumber, status);
                            }
                        }
                    }
                }
            } else if (Intent.ACTION_PACKAGE_ADDED.equals(action)) {
                if (intent.getData() != null) {
                    String packageName = intent.getData().getSchemeSpecificPart();
                    if (packageName != null) {
                        Log.d("FraudShield", "New app installed: " + packageName + ". Triggering scan...");
                    }
                }
            }
        }
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        IntentFilter filter = new IntentFilter();
        filter.addAction(TelephonyManager.ACTION_PHONE_STATE_CHANGED);
        filter.addAction(Intent.ACTION_PACKAGE_ADDED);
        filter.addDataScheme("package");
        registerReceiver(receiver, filter);
        scheduleBackgroundScan();
    }

    private void scheduleBackgroundScan() {
        Constraints constraints = new Constraints.Builder()
                .setRequiredNetworkType(NetworkType.UNMETERED)
                .setRequiresCharging(true)
                .build();

        PeriodicWorkRequest scanRequest = new PeriodicWorkRequest.Builder(ScanWorker.class, 24, TimeUnit.HOURS)
                .setConstraints(constraints)
                .build();

        WorkManager.getInstance(getApplicationContext()).enqueueUniquePeriodicWork(
                "DailySecurityScan",
                ExistingPeriodicWorkPolicy.KEEP,
                scanRequest
        );
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(receiver);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Settings channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SETTINGS_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("openNotificationListenerSettings".equals(call.method)) {
                        try {
                            Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
                            startActivity(intent);
                            result.success(true);
                        } catch (Exception e) {
                            result.error("INTENT_ERROR", e.getMessage(), null);
                        }
                    } else {
                        result.notImplemented();
                    }
                });

        // Call attestation channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CALL_ATTESTATION_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("getVerificationStatus".equals(call.method)) {
                        String number = call.argument("phoneNumber");
                        if (number != null) {
                            Integer screeningStatus = CallScreeningServiceImpl.lastVerificationStatus.get(number);
                            if (screeningStatus != null) {
                                result.success(screeningStatus);
                            } else if (lastVerificationStatus.containsKey(number)) {
                                result.success(lastVerificationStatus.get(number));
                            } else {
                                result.success(0);
                            }
                        } else {
                            result.success(0);
                        }
                    } else {
                        result.notImplemented();
                    }
                });

        // Scanner progress event channel
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SCANNER_PROGRESS_CHANNEL)
                .setStreamHandler(new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        progressEventSink = events;
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        progressEventSink = null;
                    }
                });

        // Scanner channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SCANNER_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "startFullScan":
                            Executors.newSingleThreadExecutor().execute(() -> {
                                try {
                                    Map<String, Object> scanResults = performFullScan();
                                    runOnUiThread(() -> result.success(scanResults));
                                } catch (Exception e) {
                                    runOnUiThread(() -> result.error("SCAN_ERROR", e.getMessage(), null));
                                }
                            });
                            break;
                        case "uninstallApp": {
                            String packageName = call.argument("packageName");
                            if (packageName != null) {
                                try {
                                    Intent intent = new Intent(Intent.ACTION_DELETE);
                                    intent.setData(Uri.parse("package:" + packageName));
                                    startActivity(intent);
                                    result.success(true);
                                } catch (Exception e) {
                                    result.error("UNINSTALL_ERROR", e.getMessage(), null);
                                }
                            } else {
                                result.error("INVALID_ARGUMENT", "Package name is required", null);
                            }
                            break;
                        }
                        case "openAppSettings": {
                            String packageName = call.argument("packageName");
                            if (packageName != null) {
                                try {
                                    Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                                    intent.setData(Uri.parse("package:" + packageName));
                                    startActivity(intent);
                                    result.success(true);
                                } catch (Exception e) {
                                    result.error("SETTINGS_ERROR", e.getMessage(), null);
                                }
                            } else {
                                result.error("INVALID_ARGUMENT", "Package name is required", null);
                            }
                            break;
                        }
                        default:
                            result.notImplemented();
                            break;
                    }
                });

        // Attestation channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ATTESTATION_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "getIntegrityToken": {
                            String nonce = call.argument("nonce");
                            String cloudProjectNumberStr = call.argument("cloudProjectNumber");
                            if (nonce == null || cloudProjectNumberStr == null) {
                                result.error("INVALID_ARGUMENT", "Nonce and CloudProjectNumber are required", null);
                                return;
                            }
                            long cloudProjectNumber = Long.parseLong(cloudProjectNumberStr);
                            requestIntegrityToken(nonce, cloudProjectNumber, result);
                            break;
                        }
                        case "getSecuritySignals":
                            Map<String, Object> signals = getSecuritySignals();
                            result.success(signals);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });

        // Call screening event channel
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CALL_SCREENING_CHANNEL)
                .setStreamHandler(new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        CallScreeningServiceImpl.eventSink = events;
                        Log.d("FraudShield", "CallScreening EventChannel: Flutter listening");
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        CallScreeningServiceImpl.eventSink = null;
                        Log.d("FraudShield", "CallScreening EventChannel: Flutter cancelled");
                    }
                });

        // System channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SYSTEM_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("getAndroidVersion".equals(call.method)) {
                        result.success(Build.VERSION.SDK_INT);
                    } else {
                        result.notImplemented();
                    }
                });

        // Role channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ROLE_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "isRoleHeld":
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                android.app.role.RoleManager roleManager =
                                        (android.app.role.RoleManager) getSystemService(Context.ROLE_SERVICE);
                                boolean isHeld = roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_CALL_SCREENING);
                                result.success(isHeld);
                            } else {
                                result.success(false);
                            }
                            break;
                        case "requestRole":
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                android.app.role.RoleManager roleManager =
                                        (android.app.role.RoleManager) getSystemService(Context.ROLE_SERVICE);
                                if (!roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_CALL_SCREENING)) {
                                    Intent intent = roleManager.createRequestRoleIntent(
                                            android.app.role.RoleManager.ROLE_CALL_SCREENING);
                                    startActivityForResult(intent, REQUEST_CODE_CALL_SCREENING_ROLE);
                                    pendingRoleResult = result;
                                } else {
                                    result.success(true);
                                }
                            } else {
                                result.success(false);
                            }
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_CALL_SCREENING_ROLE) {
            boolean granted = resultCode == Activity.RESULT_OK;
            if (pendingRoleResult != null) {
                pendingRoleResult.success(granted);
                pendingRoleResult = null;
            }
        }
    }

    private void requestIntegrityToken(String nonce, long cloudProjectNumber, MethodChannel.Result result) {
        IntegrityManager integrityManager = IntegrityManagerFactory.create(getApplicationContext());

        IntegrityTokenRequest integrityTokenRequest = IntegrityTokenRequest.builder()
                .setNonce(nonce)
                .setCloudProjectNumber(cloudProjectNumber)
                .build();

        com.google.android.gms.tasks.Task<IntegrityTokenResponse> integrityTokenResponse =
                integrityManager.requestIntegrityToken(integrityTokenRequest);

        integrityTokenResponse.addOnSuccessListener(response -> {
            result.success(response.token());
        }).addOnFailureListener(exception -> {
            Log.e("FraudShield", "Integrity Error: " + exception.getMessage());
            result.error("INTEGRITY_ERROR", exception.getMessage(), null);
        });
    }

    private Map<String, Object> performFullScan() {
        return ScannerEngine.performFullScan(getApplicationContext(), (processed, total) -> {
            runOnUiThread(() -> {
                if (progressEventSink != null) {
                    Map<String, Object> progress = new HashMap<>();
                    progress.put("processed", processed);
                    progress.put("total", total);
                    progress.put("progress", (double) processed / (double) total);
                    progressEventSink.success(progress);
                }
            });
        });
    }

    private Map<String, Object> getSecuritySignals() {
        return ScannerEngine.getSecuritySignals(getApplicationContext());
    }
}
