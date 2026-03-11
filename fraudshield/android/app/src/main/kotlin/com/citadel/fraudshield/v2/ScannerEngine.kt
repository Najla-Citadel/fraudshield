package com.citadel.fraudshield.v2

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import java.security.MessageDigest
import java.util.concurrent.TimeUnit

object ScannerEngine {

    fun performFullScan(context: Context, onProgress: ((Int, Int) -> Unit)? = null): Map<String, Any> {
        val results = mutableMapOf<String, Any>()
        val pm = context.packageManager
        
        val installedApps = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        val enabledAccessibilityApps = getEnabledAccessibilityServices(context)
        
        val riskyApps = mutableListOf<Map<String, Any>>()
        val totalApps = installedApps.size
        var processedApps = 0

        val systemWhitelist = getCachedSystemWhitelist(context)
        
        installedApps.chunked(50).forEach { chunk ->
            for (pkg in chunk) {
                val packageName = pkg.packageName
                processedApps++
                
                onProgress?.invoke(processedApps, totalApps)

                if (systemWhitelist.contains(packageName)) continue

                val appRisk = analyzeAppRisk(context, pkg, enabledAccessibilityApps.contains(packageName))
                if ((appRisk["score"] as Int) > 0) {
                    riskyApps.add(appRisk)
                }
            }
        }
        
        results["totalAppsScanned"] = totalApps
        results["riskyApps"] = riskyApps
        results["timestamp"] = System.currentTimeMillis()
        results["deviceSignals"] = getSecuritySignals(context)
        
        return results
    }

    private fun getEnabledAccessibilityServices(context: Context): Set<String> {
        val enabledServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        return enabledServices?.split(':')?.mapNotNull { 
            val component = android.content.ComponentName.unflattenFromString(it)
            component?.packageName 
        }?.toSet() ?: emptySet()
    }

    private fun getCachedSystemWhitelist(context: Context): Set<String> {
        val prefs = context.getSharedPreferences("ScannerPrefs", Context.MODE_PRIVATE)
        val cached = prefs.getStringSet("system_whitelist", null)
        val lastUpdate = prefs.getLong("whitelist_last_update", 0)
        val now = System.currentTimeMillis()

        if (cached != null && (now - lastUpdate) < TimeUnit.DAYS.toMillis(7)) {
            return cached
        }

        val pm = context.packageManager
        val allApps = pm.getInstalledPackages(0)
        val newWhitelist = allApps.filter { 
            (it.applicationInfo?.flags?.and(ApplicationInfo.FLAG_SYSTEM)) != 0 ||
            it.packageName.startsWith("com.google.android")
        }.map { it.packageName }.toSet()

        prefs.edit()
            .putStringSet("system_whitelist", newWhitelist)
            .putLong("whitelist_last_update", now)
            .apply()

        return newWhitelist
    }

    private fun analyzeAppRisk(context: Context, pkg: android.content.pm.PackageInfo, hasActiveAccessibility: Boolean): Map<String, Any> {
        val risk = mutableMapOf<String, Any>()
        val appInfo = pkg.applicationInfo
        val pm = context.packageManager
        val appName = appInfo?.loadLabel(pm)?.toString() ?: "Unknown"
        val packageName = pkg.packageName
        var score = 0
        val reasons = mutableListOf<String>()
        
        val isSystemApp = (appInfo?.flags?.and(ApplicationInfo.FLAG_SYSTEM)) != 0
        val isGoogleApp = packageName.startsWith("com.google.android") || packageName.startsWith("com.android.vending")
        val isAndroidSystem = packageName.startsWith("com.android.") || 
                             packageName == "android" || 
                             packageName.startsWith("com.samsung.android.") || 
                             packageName.startsWith("com.sec.android.")

        var sig: String? = null 
        val isImpersonatingGoogle = (appName.contains("Google", ignoreCase = true) || appName.contains("Play Store", ignoreCase = true)) && !isGoogleApp
        
        if (isImpersonatingGoogle) {
            score += 100
            reasons.add("Potential Impersonation: App uses 'Google' name but is not from Google")
            sig = getAppSignature(context, packageName)
        }

        if (isSystemApp && (isGoogleApp || isAndroidSystem)) {
            risk["name"] = appName
            risk["packageName"] = packageName
            risk["score"] = 0
            risk["reasons"] = reasons
            return risk
        }
        
        if (hasActiveAccessibility) {
            score += 50
            reasons.add("Active Accessibility Service (Can monitor screen and simulate clicks)")
        }

        val permissions = pkg.requestedPermissions
        if (permissions != null) {
            val hasSms = permissions.contains(android.Manifest.permission.RECEIVE_SMS)
            val hasInternet = permissions.contains(android.Manifest.permission.INTERNET)
            val hasOverlay = permissions.contains(android.Manifest.permission.SYSTEM_ALERT_WINDOW)
            
            val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) appInfo?.category else -1
            val isSocialOrComm = category == ApplicationInfo.CATEGORY_SOCIAL || category == ApplicationInfo.CATEGORY_MAPS
            
            if (hasSms && hasInternet) {
                if (!isSocialOrComm) {
                    score += 50
                    reasons.add("SMS + Internet in non-communication app (Critical OTP risk)")
                } else {
                    score += 15
                    reasons.add("SMS + Internet combination")
                }
            }

            if (hasOverlay) {
                score += 30
                reasons.add("Overlay permission enabled (Can capture screen content)")
            }

            if (permissions.contains(android.Manifest.permission.READ_CALL_LOG)) {
                score += 20
                reasons.add("Sensitive Permission: Read Call Log (Data exfiltration risk)")
            }
            if (permissions.contains(android.Manifest.permission.CAMERA) && !isSocialOrComm) {
                score += 15
                reasons.add("Sensitive Permission: Camera access in non-media app")
            }
            if (permissions.contains(android.Manifest.permission.RECORD_AUDIO) && !isSocialOrComm) {
                score += 15
                reasons.add("Sensitive Permission: Microphone access in non-media app")
            }
            if (permissions.contains("android.permission.BIND_DEVICE_ADMIN")) {
                score += 80
                reasons.add("Critical Permission: Device Administrator (Can lock device or wipe data)")
            }
            if (permissions.contains(android.Manifest.permission.REQUEST_INSTALL_PACKAGES)) {
                score += 40
                reasons.add("Risky Permission: Request Install Packages (Dropper/Update behavior)")
            }
        }

        if (isBankImpersonation(appName, packageName)) {
            score += 100
            reasons.add("Critical Threat: Potential Bank Impersonation (Fake banking app)")
            if (sig == null) sig = getAppSignature(context, packageName)
        }

        val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            pm.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            pm.getInstallerPackageName(packageName)
        }
        
        val trustedInstallers = listOf(
            "com.android.vending", 
            "com.sec.android.app.samsungapps",
            "com.amazon.venezia",
            "com.huawei.appmarket"
        )
        
        if (!isSystemApp && !trustedInstallers.contains(installer)) {
            if (installer == null || installer.isEmpty()) {
                score += 15
                reasons.add("App from unknown source (Sideloaded)")
            }
        }
        
        risk["name"] = appName
        risk["packageName"] = packageName
        risk["score"] = score
        risk["reasons"] = reasons

        if (score > 0 && sig == null) {
            sig = getAppSignature(context, packageName)
        }
        risk["signature"] = sig ?: ""
        
        return risk
    }

    private fun isBankImpersonation(appName: String, packageName: String): Boolean {
        val bankKeywords = listOf("Maybank", "CIMB", "Public Bank", "RHB", "Hong Leong", "AmBank", "UOB", "HSBC")
        val officialPackages = listOf(
            "com.maybank2u.android", "com.maybank2u.m2uapp", "com.maybank2u.mae",
            "com.cimb.cimbclicks", "com.cimb.octo",
            "com.pbe.pbebank", "com.pbe.pbengage",
            "com.rhbgroup.rhbmobile", "com.rhbgroup.rhbnow",
            "com.hly.hlbconnect",
            "com.ambank.ambani",
            "com.uob.mighty.my",
            "com.hsbc.hsbcmalaysia"
        )

        if (officialPackages.contains(packageName)) return false

        for (keyword in bankKeywords) {
            if (appName.contains(keyword, ignoreCase = true)) return true
            if (levenshteinDistance(appName.lowercase(), keyword.lowercase()) <= 1) return true
        }
        return false
    }

    private fun levenshteinDistance(s1: String, s2: String): Int {
        val dp = Array(s1.length + 1) { IntArray(s2.length + 1) }
        for (i in 0..s1.length) dp[i][0] = i
        for (j in 0..s2.length) dp[0][j] = j
        for (i in 1..s1.length) {
            for (j in 1..s2.length) {
                val cost = if (s1[i - 1] == s2[j - 1]) 0 else 1
                dp[i][j] = minOf(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost)
            }
        }
        return dp[s1.length][s2.length]
    }

    fun getSecuritySignals(context: Context): Map<String, Any> {
        val signals = mutableMapOf<String, Any>()
        signals["isDebuggerConnected"] = android.os.Debug.isDebuggerConnected()
        
        val isEmulator = Build.FINGERPRINT.contains("generic") ||
                Build.FINGERPRINT.contains("unknown") ||
                Build.MODEL.contains("google_sdk") ||
                Build.MODEL.contains("gphone") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK built for x86") ||
                Build.BOARD == "QC_Reference_Phone" ||
                Build.MANUFACTURER.contains("Genymotion") ||
                Build.HOST.startsWith("Build") ||
                Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
                "google_sdk" == Build.PRODUCT
        signals["isEmulator"] = isEmulator

        signals["isFridaDetected"] = detectFrida()
        signals["isXposedDetected"] = detectXposed(context)

        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager
        val enabledImeList = imm?.enabledInputMethodList
        var untrustedImeCount = 0
        if (enabledImeList != null) {
            for (ime in enabledImeList) {
                val imeId = ime.id
                val isTrusted = imeId.startsWith("com.google.android.inputmethod") || 
                               imeId.startsWith("com.samsung.android.honeyboard") ||
                               imeId.startsWith("com.microsoft.emojis") ||
                               imeId.startsWith("com.android.inputmethod")
                if (!isTrusted) untrustedImeCount++
            }
        }
        signals["untrustedImeCount"] = untrustedImeCount
        signals["isRooted"] = checkRootMethod()

        return signals
    }

    private fun detectFrida(): Boolean {
        val fridaFiles = arrayOf("/data/local/tmp/re.frida.server", "/data/local/tmp/frida-server", "/usr/bin/frida-server")
        for (path in fridaFiles) if (java.io.File(path).exists()) return true
        try {
            val socket = java.net.Socket("127.0.0.1", 27042)
            socket.close()
            return true
        } catch (e: Exception) {}
        return false
    }

    private fun detectXposed(context: Context): Boolean {
        try {
            Class.forName("de.robv.android.xposed.XposedBridge")
            return true
        } catch (e: ClassNotFoundException) {}
        val packages = context.packageManager.getInstalledPackages(0)
        for (pkg in packages) if (pkg.packageName.contains("de.robv.android.xposed.installer")) return true
        return false
    }

    private fun checkRootMethod(): Boolean {
        val paths = arrayOf("/system/app/Superuser.apk", "/sbin/su", "/system/bin/su", "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su", "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su")
        for (path in paths) if (java.io.File(path).exists()) return true
        return false
    }

    private fun getAppSignature(context: Context, packageName: String): String? {
        return try {
            val pm = context.packageManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                val signingInfo = packageInfo.signingInfo
                if (signingInfo != null) {
                    val signatures = if (signingInfo.hasMultipleSigners()) signingInfo.apkContentsSigners else signingInfo.signingCertificateHistory
                    signatures?.firstOrNull()?.let { hashSignature(it.toByteArray()) }
                } else null
            } else {
                @Suppress("DEPRECATION")
                val packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                packageInfo.signatures?.firstOrNull()?.let { hashSignature(it.toByteArray()) }
            }
        } catch (e: Exception) { null }
    }

    private fun hashSignature(signature: ByteArray): String {
        val md = MessageDigest.getInstance("SHA-256")
        val digest = md.digest(signature)
        return digest.joinToString("") { "%02x".format(it) }
    }
}
