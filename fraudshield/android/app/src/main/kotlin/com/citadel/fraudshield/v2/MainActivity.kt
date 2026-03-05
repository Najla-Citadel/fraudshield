package com.citadel.fraudshield.v2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.citadel.fraudshield/settings"
    private val CALL_ATTESTATION_CHANNEL = "com.citadel.fraudshield/call_attestation"
    
    // Store the last known verification status mapped by phone number
    private val lastVerificationStatus = HashMap<String, Int>()

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
                val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
                if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                    val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        // In Android, verification status is typically only available to CallScreeningServices.
                        // We use the string literal to allow compilation and intercept if any custom ROMs broadcast it.
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
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
        registerReceiver(receiver, filter)
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
                if (number != null && lastVerificationStatus.containsKey(number)) {
                    result.success(lastVerificationStatus[number])
                } else {
                    // Default to NOT_VERIFIED (0)
                    result.success(0) 
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
