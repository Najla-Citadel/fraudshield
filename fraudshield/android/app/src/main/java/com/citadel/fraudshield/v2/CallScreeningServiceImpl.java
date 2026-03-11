package com.citadel.fraudshield.v2;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.telecom.Call;
import android.telecom.CallScreeningService;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

/**
 * CallScreeningServiceImpl provides call screening for Android 10+ (API 29+).
 * Converted from Kotlin to Java to bypass a K2 compiler bug
 * (FirIncompatibleClassExpressionChecker crash on Call.Details).
 */
@RequiresApi(api = Build.VERSION_CODES.N)
public class CallScreeningServiceImpl extends CallScreeningService {

    private static final String TAG = "FraudShieldCallScreen";

    // EventChannel sink for streaming call events to Flutter
    public static EventChannel.EventSink eventSink = null;

    // Store the last verification status for STIR/SHAKEN
    public static final HashMap<String, Integer> lastVerificationStatus = new HashMap<>();

    @Override
    public void onScreenCall(@NonNull Call.Details callDetails) {
        String phoneNumber = null;
        if (callDetails.getHandle() != null) {
            phoneNumber = callDetails.getHandle().getSchemeSpecificPart();
        }
        Log.d(TAG, "onScreenCall: number=" + phoneNumber);

        // Extract call direction
        String direction = "UNKNOWN";
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            int dir = callDetails.getCallDirection();
            if (dir == Call.Details.DIRECTION_INCOMING) {
                direction = "INCOMING";
            } else if (dir == Call.Details.DIRECTION_OUTGOING) {
                direction = "OUTGOING";
            }
        }

        // Extract STIR/SHAKEN verification status (Android 11+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && phoneNumber != null) {
            try {
                int verificationStatus = callDetails.getCallerNumberVerificationStatus();
                lastVerificationStatus.put(phoneNumber, verificationStatus);
                Log.d(TAG, "STIR/SHAKEN status: " + verificationStatus + " for " + phoneNumber);
            } catch (Exception e) {
                Log.w(TAG, "Failed to get verification status: " + e.getMessage());
            }
        }

        // Send call event to Flutter via EventChannel
        final String finalPhoneNumber = phoneNumber;
        final String finalDirection = direction;
        new Handler(Looper.getMainLooper()).post(() -> {
            try {
                if (eventSink != null) {
                    Map<String, Object> event = new HashMap<>();
                    event.put("event", "CALL_SCREENING");
                    event.put("phoneNumber", finalPhoneNumber);
                    event.put("callDirection", finalDirection);
                    event.put("timestamp", System.currentTimeMillis());
                    eventSink.success(event);
                    Log.d(TAG, "Sent call event to Flutter: " + finalPhoneNumber + " (" + finalDirection + ")");
                }
            } catch (Exception e) {
                Log.e(TAG, "Failed to send event to Flutter: " + e.getMessage());
            }
        });

        // Respond to the call - never auto-block, only notify
        CallResponse response = new CallResponse.Builder()
                .setDisallowCall(false)
                .setRejectCall(false)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build();

        respondToCall(callDetails, response);
    }
}
