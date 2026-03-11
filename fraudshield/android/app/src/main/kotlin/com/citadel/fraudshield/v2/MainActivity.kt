package com.citadel.fraudshield.v2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.TelephonyManager
import android.app.Activity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import android.util.Log
import kotlinx.coroutines.*
import java.security.MessageDigest
import java.util.*
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import com.google.android.play.core.integrity.IntegrityManager
import com.google.android.gms.tasks.Task
import androidx.work.*
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.citadel.fraudshield/settings"
    private val CALL_ATTESTATION_CHANNEL = "com.citadel.fraudshield/call_attestation"
    private val SCANNER_CHANNEL = "com.citadel.fraudshield/scanner"
    private val ATTESTATION_CHANNEL = "com.citadel.fraudshield/attestation"
    private val CALL_SCREENING_CHANNEL = "com.citadel.fraudshield/call_screening"
    private val SYSTEM_CHANNEL = "com.citadel.fraudshield/system"
    private val ROLE_CHANNEL = "com.citadel.fraudshield/role"
    private val SCANNER_PROGRESS_CHANNEL = "com.citadel.fraudshield/scanner_progress"
    
    private var progressEventSink: EventChannel.EventSink? = null
    
    // Store the last known verification status mapped by phone number
    private val lastVerificationStatus = HashMap<String, Int>()

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                TelephonyManager.ACTION_PHONE_STATE_CHANGED -> {
                    val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
                    if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            val extraVerificationStatus = "android.telecom.extra.VERIFICATION_STATUS"
                            if (intent.hasExtra(extraVerificationStatus)) {
                                val status = intent.getIntExtra(extraVerificationStatus, android.telecom.Connection.VERIFICATION_STATUS_NOT_VERIFIED)
                                if (incomingNumber != null) {
                                    lastVerificationStatus[incomingNumber] = status
                                }
                            }
                        }
                    }
                }
                Intent.ACTION_PACKAGE_ADDED -> {
                    val packageName = intent.data?.schemeSpecificPart
                    if (packageName != null) {
                        Log.d("FraudShield", "New app installed: $packageName. Triggering scan...")
                        // In a real app, we would push a notification if risky
                    }
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter()
        filter.addAction(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
        filter.addAction(Intent.ACTION_PACKAGE_ADDED)
        filter.addDataScheme("package")
        registerReceiver(receiver, filter)

        // Phase 3: Schedule Background Scan
        scheduleBackgroundScan()
    }

    private fun scheduleBackgroundScan() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.UNMETERED)
            .setRequiresCharging(true)
            .build()

        val scanRequest = PeriodicWorkRequestBuilder<ScanWorker>(24, TimeUnit.HOURS)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(
            "DailySecurityScan",
            ExistingPeriodicWorkPolicy.KEEP,
            scanRequest
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(receiver)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openNotificationListenerSettings") {
                try {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INTENT_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_ATTESTATION_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getVerificationStatus") {
                val number = call.argument<String>("phoneNumber")
                if (number != null) {
                    // Check CallScreeningService's status first (Android 10+, more reliable)
                    val screeningStatus = CallScreeningServiceImpl.lastVerificationStatus[number]
                    if (screeningStatus != null) {
                        result.success(screeningStatus)
                    } else if (lastVerificationStatus.containsKey(number)) {
                        // Fallback to BroadcastReceiver status (Android 9)
                        result.success(lastVerificationStatus[number])
                    } else {
                        // Default to NOT_VERIFIED (0)
                        result.success(0)
                    }
                } else {
                    result.success(0)
                }
            } else {
                result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_PROGRESS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    progressEventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startFullScan" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val scanResults = performFullScan()
                            withContext(Dispatchers.Main) {
                                result.success(scanResults)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("SCAN_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val intent = Intent(Intent.ACTION_DELETE)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UNINSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "openAppSettings" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ATTESTATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getIntegrityToken" -> {
                    val nonce = call.argument<String>("nonce")
                    val cloudProjectNumber = call.argument<String>("cloudProjectNumber")?.toLong()

                    if (nonce == null || cloudProjectNumber == null) {
                        result.error("INVALID_ARGUMENT", "Nonce and CloudProjectNumber are required", null)
                        return@setMethodCallHandler
                    }

                    requestIntegrityToken(nonce, cloudProjectNumber, result)
                }
                "getSecuritySignals" -> {
                    val signals = getSecuritySignals()
                    result.success(signals)
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel for CallScreeningService (Android 10+)
        // Streams incoming call events to Flutter without READ_CALL_LOG permission
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_SCREENING_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    CallScreeningServiceImpl.eventSink = events
                    Log.d("FraudShield", "CallScreening EventChannel: Flutter listening")
                }
                override fun onCancel(arguments: Any?) {
                    CallScreeningServiceImpl.eventSink = null
                    Log.d("FraudShield", "CallScreening EventChannel: Flutter cancelled")
                }
            }
        )

        // System MethodChannel for platform info (Android version, etc.)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                else -> result.notImplemented()
            }
        }

        // Role MethodChannel for Call Screening role management (Android 10+)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ROLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRoleHeld" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as android.app.role.RoleManager
                        val isHeld = roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_CALL_SCREENING)
                        result.success(isHeld)
                    } else {
                        result.success(false)
                    }
                }
                "requestRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as android.app.role.RoleManager
                        if (!roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_CALL_SCREENING)) {
                            val intent = roleManager.createRequestRoleIntent(android.app.role.RoleManager.ROLE_CALL_SCREENING)
                            startActivityForResult(intent, REQUEST_CODE_CALL_SCREENING_ROLE)
                            // Result will be handled in onActivityResult
                            pendingRoleResult = result
                        } else {
                            result.success(true) // Already held
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val REQUEST_CODE_CALL_SCREENING_ROLE = 1001
    }

    private var pendingRoleResult: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_CALL_SCREENING_ROLE) {
            val granted = resultCode == RESULT_OK
            pendingRoleResult?.success(granted)
            pendingRoleResult = null
        }
    }

    private fun requestIntegrityToken(nonce: String, cloudProjectNumber: Long, result: MethodChannel.Result) {
        val integrityManager = IntegrityManagerFactory.create(applicationContext)

        val integrityTokenRequest = IntegrityTokenRequest.builder()
            .setNonce(nonce)
            .setCloudProjectNumber(cloudProjectNumber)
            .build()

        val integrityTokenResponse: Task<com.google.android.play.core.integrity.IntegrityTokenResponse> = 
            integrityManager.requestIntegrityToken(integrityTokenRequest)

        integrityTokenResponse.addOnSuccessListener { response ->
            result.success(response.token())
        }.addOnFailureListener { exception ->
            Log.e("FraudShield", "Integrity Error: ${exception.message}")
            result.error("INTEGRITY_ERROR", exception.message, null)
        }
    }

    private fun performFullScan(): Map<String, Any> {
        return ScannerEngine.performFullScan(applicationContext) { processed, total ->
            runOnUiThread {
                progressEventSink?.success(mapOf(
                    "processed" to processed,
                    "total" to total,
                    "progress" to (processed.toDouble() / total.toDouble())
                ))
            }
        }
    }

    private fun getSecuritySignals(): Map<String, Any> {
        return ScannerEngine.getSecuritySignals(applicationContext)
    }
}
