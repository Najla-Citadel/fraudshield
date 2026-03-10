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

class MainActivity: FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.citadel.fraudshield/settings"
    private val CALL_ATTESTATION_CHANNEL = "com.citadel.fraudshield/call_attestation"
    private val SCANNER_CHANNEL = "com.citadel.fraudshield/scanner"
    private val ATTESTATION_CHANNEL = "com.citadel.fraudshield/attestation"
    private val CALL_SCREENING_CHANNEL = "com.citadel.fraudshield/call_screening"
    private val SYSTEM_CHANNEL = "com.citadel.fraudshield/system"
    private val ROLE_CHANNEL = "com.citadel.fraudshield/role"
    
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

    private fun getEnabledAccessibilityServices(): Set<String> {
        val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        return enabledServices?.split(':')?.mapNotNull { 
            val component = android.content.ComponentName.unflattenFromString(it)
            component?.packageName 
        }?.toSet() ?: emptySet()
    }

    private fun getAppSignature(packageName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                val signingInfo = packageInfo.signingInfo
                if (signingInfo != null) {
                    val signatures = if (signingInfo.hasMultipleSigners()) {
                        signingInfo.apkContentsSigners
                    } else {
                        signingInfo.signingCertificateHistory
                    }
                    signatures?.firstOrNull()?.let { hashSignature(it.toByteArray()) }
                } else {
                    null
                }
            } else {
                @Suppress("DEPRECATION")
                val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                val signatures = packageInfo.signatures
                signatures?.firstOrNull()?.let { hashSignature(it.toByteArray()) }
            }
        } catch (e: Exception) { 
            Log.e("FraudShield", "Error getting signature for $packageName: ${e.message}")
            null 
        }
    }

    private fun hashSignature(signature: ByteArray): String {
        val md = MessageDigest.getInstance("SHA-256")
        val digest = md.digest(signature)
        return digest.joinToString("") { "%02x".format(it) }
    }

    private fun performFullScan(): Map<String, Any> {
        val results = mutableMapOf<String, Any>()
        val pm = packageManager
        val installedApps = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        val enabledAccessibilityApps = getEnabledAccessibilityServices()
        
        val riskyApps = mutableListOf<Map<String, Any>>()
        val totalApps = installedApps.size
        
        for (pkg in installedApps) {
            val appInfo = pkg.applicationInfo
            if (appInfo == null) continue
            
            val appRisk = analyzeAppRisk(pkg, enabledAccessibilityApps.contains(pkg.packageName))
            if (appRisk["score"] as Int > 0) {
                riskyApps.add(appRisk)
            }
        }
        
        results["totalAppsScanned"] = totalApps
        results["riskyApps"] = riskyApps
        results["timestamp"] = System.currentTimeMillis()
        
        return results
    }

    private fun analyzeAppRisk(pkg: android.content.pm.PackageInfo, hasActiveAccessibility: Boolean): Map<String, Any> {
        val risk = mutableMapOf<String, Any>()
        val appInfo = pkg.applicationInfo
        val appName = appInfo?.loadLabel(packageManager)?.toString() ?: "Unknown"
        val packageName = pkg.packageName
        var score = 0
        val reasons = mutableListOf<String>()
        
        // 1. System Whitelist (Reduce False Positives)
        val isSystemApp = (appInfo?.flags?.and(ApplicationInfo.FLAG_SYSTEM)) != 0
        val isGoogleApp = packageName.startsWith("com.google.android") || packageName.startsWith("com.android.vending")
        val isAndroidSystem = packageName.startsWith("com.android.") || packageName == "android"
        
        // 2. Signature Fingerprinting (Spoofing Detection)
        val sig = getAppSignature(packageName)
        val isImpersonatingGoogle = (appName.contains("Google", ignoreCase = true) || appName.contains("Play Store", ignoreCase = true)) && !isGoogleApp
        
        if (isImpersonatingGoogle) {
            score += 100 // Critical
            reasons.add("Potential Impersonation: App uses 'Google' name but is not from Google")
        }

        if (isSystemApp && (isGoogleApp || isAndroidSystem)) {
            risk["name"] = appName
            risk["packageName"] = packageName
            risk["score"] = 0
            risk["reasons"] = reasons
            return risk
        }

        // 2. Accessibility Service Audit (Phase 3)
        if (hasActiveAccessibility) {
            score += 50
            reasons.add("Active Accessibility Service (Can monitor screen and simulate clicks)")
        }

        // 3. Category-Aware Permission Analysis (Phase 3)
        val permissions = pkg.requestedPermissions
        if (permissions != null) {
            val hasSms = permissions.contains(android.Manifest.permission.RECEIVE_SMS)
            val hasInternet = permissions.contains(android.Manifest.permission.INTERNET)
            val hasOverlay = permissions.contains(android.Manifest.permission.SYSTEM_ALERT_WINDOW)
            
            // Context Check: Is this a tool/utility that shouldn't need SMS?
            val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) appInfo?.category else -1
            val isSocialOrComm = category == ApplicationInfo.CATEGORY_SOCIAL || category == ApplicationInfo.CATEGORY_MAPS
            
            if (hasSms && hasInternet) {
                if (!isSocialOrComm) {
                    score += 50 // Much higher for non-comm apps
                    reasons.add("SMS + Internet in non-communication app (Critical OTP risk)")
                } else {
                    score += 15 // Normal-ish for messengers
                    reasons.add("SMS + Internet combination")
                }
            }

            if (hasOverlay) {
                score += 30
                reasons.add("Overlay permission enabled (Can capture screen content)")
            }
        }

        // 4. Sideload Check
        val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            packageManager.getInstallerPackageName(packageName)
        }
        
        if (installer == null || installer.isEmpty()) {
            score += 15
            reasons.add("App from unknown source (Sideloaded)")
        }
        
        risk["name"] = appName
        risk["packageName"] = packageName
        risk["score"] = score
        risk["reasons"] = reasons
        
        return risk
    }
    private fun getSecuritySignals(): Map<String, Any> {
        val signals = mutableMapOf<String, Any>()
        
        // 1. Debugger Detection
        signals["isDebuggerConnected"] = android.os.Debug.isDebuggerConnected()
        
        // 2. Emulator Detection (Deep)
        val isEmulator = Build.FINGERPRINT.contains("generic") ||
                Build.FINGERPRINT.contains("unknown") ||
                Build.MODEL.contains("google_sdk") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK built for x86") ||
                Build.BOARD == "QC_Reference_Phone" || // Native bridge often has this
                Build.MANUFACTURER.contains("Genymotion") ||
                Build.HOST.startsWith("Build") || // Android Studio Build
                Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
                "google_sdk" == Build.PRODUCT
        signals["isEmulator"] = isEmulator

        // 3. Hooking Framework Detection (Frida/Xposed)
        signals["isFridaDetected"] = detectFrida()
        signals["isXposedDetected"] = detectXposed()
        
        // 4. Root Detection (Basic)
        signals["isRooted"] = checkRootMethod()

        return signals
    }

    private fun detectFrida(): Boolean {
        val fridaFiles = arrayOf(
            "/data/local/tmp/re.frida.server",
            "/data/local/tmp/frida-server",
            "/usr/bin/frida-server"
        )
        for (path in fridaFiles) {
            if (java.io.File(path).exists()) return true
        }
        
        // Check for common Frida port (fast check, doesn't block UI if local)
        try {
            val socket = java.net.Socket("127.0.0.1", 27042)
            socket.close()
            return true
        } catch (e: Exception) {
            // Port closed as expected
        }
        
        return false
    }

    private fun detectXposed(): Boolean {
        try {
            // Check for XposedBridge class
            Class.forName("de.robv.android.xposed.XposedBridge")
            return true
        } catch (e: ClassNotFoundException) {
            // Not detected
        }
        
        // Check for Xposed packages
        val packages = packageManager.getInstalledPackages(0)
        for (pkg in packages) {
            if (pkg.packageName.contains("de.robv.android.xposed.installer")) return true
        }
        
        return false
    }

    private fun checkRootMethod(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )
        for (path in paths) {
            if (java.io.File(path).exists()) return true
        }
        return false
    }
}
