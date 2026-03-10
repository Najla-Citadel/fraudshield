package com.citadel.fraudshield.v2

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel

/**
 * CallScreeningServiceImpl provides call screening for Android 10+ (API 29+).
 * This replaces the phone_state package approach, removing the need for
 * the restricted READ_CALL_LOG permission and improving Play Store compliance.
 *
 * Flow:
 * 1. Android OS invokes onScreenCall() when a call arrives
 * 2. We extract the phone number and call direction
 * 3. Send the event to Flutter via EventChannel
 * 4. Flutter handles risk evaluation and overlay display
 * 5. We respond to the call (never auto-block, just notify)
 */
@RequiresApi(Build.VERSION_CODES.N)
class CallScreeningServiceImpl : CallScreeningService() {

    companion object {
        private const val TAG = "FraudShieldCallScreen"

        // EventChannel sink for streaming call events to Flutter
        var eventSink: EventChannel.EventSink? = null

        // Store the last verification status for STIR/SHAKEN
        val lastVerificationStatus = HashMap<String, Int>()
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val phoneNumber = callDetails.handle?.schemeSpecificPart
        Log.d(TAG, "onScreenCall: number=$phoneNumber")

        // Extract call direction
        val direction = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            when (callDetails.callDirection) {
                Call.Details.DIRECTION_INCOMING -> "INCOMING"
                Call.Details.DIRECTION_OUTGOING -> "OUTGOING"
                else -> "UNKNOWN"
            }
        } else {
            "UNKNOWN"
        }

        // Extract STIR/SHAKEN verification status (Android 11+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && phoneNumber != null) {
            try {
                val verificationStatus = callDetails.callerNumberVerificationStatus
                lastVerificationStatus[phoneNumber] = verificationStatus
                Log.d(TAG, "STIR/SHAKEN status: $verificationStatus for $phoneNumber")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to get verification status: ${e.message}")
            }
        }

        // Send call event to Flutter via EventChannel
        Handler(Looper.getMainLooper()).post {
            try {
                eventSink?.success(mapOf(
                    "event" to "CALL_SCREENING",
                    "phoneNumber" to phoneNumber,
                    "callDirection" to direction,
                    "timestamp" to System.currentTimeMillis()
                ))
                Log.d(TAG, "Sent call event to Flutter: $phoneNumber ($direction)")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send event to Flutter: ${e.message}")
            }
        }

        // Respond to the call - never auto-block, only notify
        val response = CallResponse.Builder()
            .setDisallowCall(false)    // Don't block the call
            .setRejectCall(false)      // Don't reject the call
            .setSkipCallLog(false)     // Keep in call log
            .setSkipNotification(false) // Show default notification
            .build()

        respondToCall(callDetails, response)
    }
}
