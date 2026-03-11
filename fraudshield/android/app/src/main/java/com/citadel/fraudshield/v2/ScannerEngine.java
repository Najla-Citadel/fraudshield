package com.citadel.fraudshield.v2;

import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.SigningInfo;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;
import android.view.inputmethod.InputMethodInfo;
import android.view.inputmethod.InputMethodManager;

import java.io.File;
import java.net.Socket;
import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * ScannerEngine performs full device scans analyzing installed apps for risk.
 * Converted from Kotlin to Java to bypass a K2 compiler bug.
 */
public class ScannerEngine {

    public interface ProgressCallback {
        void onProgress(int processed, int total);
    }

    public static Map<String, Object> performFullScan(Context context, ProgressCallback onProgress) {
        Map<String, Object> results = new HashMap<>();
        PackageManager pm = context.getPackageManager();

        List<PackageInfo> installedApps = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS);
        Set<String> enabledAccessibilityApps = getEnabledAccessibilityServices(context);

        List<Map<String, Object>> riskyApps = new ArrayList<>();
        int totalApps = installedApps.size();
        int processedApps = 0;

        Set<String> systemWhitelist = getCachedSystemWhitelist(context);

        for (PackageInfo pkg : installedApps) {
            String packageName = pkg.packageName;
            processedApps++;

            if (onProgress != null) {
                onProgress.onProgress(processedApps, totalApps);
            }

            if (systemWhitelist.contains(packageName)) continue;

            Map<String, Object> appRisk = analyzeAppRisk(context, pkg, enabledAccessibilityApps.contains(packageName));
            int score = (int) appRisk.get("score");
            if (score > 0) {
                riskyApps.add(appRisk);
            }
        }

        results.put("totalAppsScanned", totalApps);
        results.put("riskyApps", riskyApps);
        results.put("timestamp", System.currentTimeMillis());
        results.put("deviceSignals", getSecuritySignals(context));

        return results;
    }

    public static Map<String, Object> performFullScan(Context context) {
        return performFullScan(context, null);
    }

    private static Set<String> getEnabledAccessibilityServices(Context context) {
        String enabledServices = Settings.Secure.getString(
                context.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        Set<String> result = new HashSet<>();
        if (enabledServices != null) {
            for (String s : enabledServices.split(":")) {
                ComponentName cn = ComponentName.unflattenFromString(s);
                if (cn != null) {
                    result.add(cn.getPackageName());
                }
            }
        }
        return result;
    }

    private static Set<String> getCachedSystemWhitelist(Context context) {
        SharedPreferences prefs = context.getSharedPreferences("ScannerPrefs", Context.MODE_PRIVATE);
        Set<String> cached = prefs.getStringSet("system_whitelist", null);
        long lastUpdate = prefs.getLong("whitelist_last_update", 0);
        long now = System.currentTimeMillis();

        if (cached != null && (now - lastUpdate) < TimeUnit.DAYS.toMillis(7)) {
            return cached;
        }

        PackageManager pm = context.getPackageManager();
        List<PackageInfo> allApps = pm.getInstalledPackages(0);
        Set<String> newWhitelist = new HashSet<>();
        for (PackageInfo pi : allApps) {
            ApplicationInfo ai = pi.applicationInfo;
            if (ai != null && (ai.flags & ApplicationInfo.FLAG_SYSTEM) != 0) {
                newWhitelist.add(pi.packageName);
            } else if (pi.packageName.startsWith("com.google.android")) {
                newWhitelist.add(pi.packageName);
            }
        }

        prefs.edit()
                .putStringSet("system_whitelist", newWhitelist)
                .putLong("whitelist_last_update", now)
                .apply();

        return newWhitelist;
    }

    @SuppressWarnings("deprecation")
    private static Map<String, Object> analyzeAppRisk(Context context, PackageInfo pkg, boolean hasActiveAccessibility) {
        Map<String, Object> risk = new HashMap<>();
        ApplicationInfo appInfo = pkg.applicationInfo;
        PackageManager pm = context.getPackageManager();
        String appName = appInfo != null ? appInfo.loadLabel(pm).toString() : "Unknown";
        String packageName = pkg.packageName;
        int score = 0;
        List<String> reasons = new ArrayList<>();

        boolean isSystemApp = appInfo != null && (appInfo.flags & ApplicationInfo.FLAG_SYSTEM) != 0;
        boolean isGoogleApp = packageName.startsWith("com.google.android") || packageName.startsWith("com.android.vending");
        boolean isAndroidSystem = packageName.startsWith("com.android.") ||
                packageName.equals("android") ||
                packageName.startsWith("com.samsung.android.") ||
                packageName.startsWith("com.sec.android.");

        String sig = null;
        boolean isImpersonatingGoogle = (appName.toLowerCase().contains("google") || appName.toLowerCase().contains("play store")) && !isGoogleApp;

        if (isImpersonatingGoogle) {
            score += 100;
            reasons.add("Potential Impersonation: App uses 'Google' name but is not from Google");
            sig = getAppSignature(context, packageName);
        }

        if (isSystemApp && (isGoogleApp || isAndroidSystem)) {
            risk.put("name", appName);
            risk.put("packageName", packageName);
            risk.put("score", 0);
            risk.put("reasons", reasons);
            return risk;
        }

        if (hasActiveAccessibility) {
            score += 50;
            reasons.add("Active Accessibility Service (Can monitor screen and simulate clicks)");
        }

        String[] permissions = pkg.requestedPermissions;
        if (permissions != null) {
            List<String> permList = Arrays.asList(permissions);
            boolean hasSms = permList.contains(android.Manifest.permission.RECEIVE_SMS);
            boolean hasInternet = permList.contains(android.Manifest.permission.INTERNET);
            boolean hasOverlay = permList.contains(android.Manifest.permission.SYSTEM_ALERT_WINDOW);

            int category = -1;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && appInfo != null) {
                category = appInfo.category;
            }
            boolean isSocialOrComm = category == ApplicationInfo.CATEGORY_SOCIAL || category == ApplicationInfo.CATEGORY_MAPS;

            if (hasSms && hasInternet) {
                if (!isSocialOrComm) {
                    score += 50;
                    reasons.add("SMS + Internet in non-communication app (Critical OTP risk)");
                } else {
                    score += 15;
                    reasons.add("SMS + Internet combination");
                }
            }

            if (hasOverlay) {
                score += 30;
                reasons.add("Overlay permission enabled (Can capture screen content)");
            }

            if (permList.contains(android.Manifest.permission.READ_CALL_LOG)) {
                score += 20;
                reasons.add("Sensitive Permission: Read Call Log (Data exfiltration risk)");
            }
            if (permList.contains(android.Manifest.permission.CAMERA) && !isSocialOrComm) {
                score += 15;
                reasons.add("Sensitive Permission: Camera access in non-media app");
            }
            if (permList.contains(android.Manifest.permission.RECORD_AUDIO) && !isSocialOrComm) {
                score += 15;
                reasons.add("Sensitive Permission: Microphone access in non-media app");
            }
            if (permList.contains("android.permission.BIND_DEVICE_ADMIN")) {
                score += 80;
                reasons.add("Critical Permission: Device Administrator (Can lock device or wipe data)");
            }
            if (permList.contains(android.Manifest.permission.REQUEST_INSTALL_PACKAGES)) {
                score += 40;
                reasons.add("Risky Permission: Request Install Packages (Dropper/Update behavior)");
            }
        }

        if (isBankImpersonation(appName, packageName)) {
            score += 100;
            reasons.add("Critical Threat: Potential Bank Impersonation (Fake banking app)");
            if (sig == null) sig = getAppSignature(context, packageName);
        }

        String installer = null;
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                installer = pm.getInstallSourceInfo(packageName).getInstallingPackageName();
            } else {
                installer = pm.getInstallerPackageName(packageName);
            }
        } catch (Exception e) { /* ignore */ }

        List<String> trustedInstallers = Arrays.asList(
                "com.android.vending",
                "com.sec.android.app.samsungapps",
                "com.amazon.venezia",
                "com.huawei.appmarket"
        );

        if (!isSystemApp && !trustedInstallers.contains(installer)) {
            if (installer == null || installer.isEmpty()) {
                score += 15;
                reasons.add("App from unknown source (Sideloaded)");
            }
        }

        risk.put("name", appName);
        risk.put("packageName", packageName);
        risk.put("score", score);
        risk.put("reasons", reasons);

        if (score > 0 && sig == null) {
            sig = getAppSignature(context, packageName);
        }
        risk.put("signature", sig != null ? sig : "");

        return risk;
    }

    private static boolean isBankImpersonation(String appName, String packageName) {
        String[] bankKeywords = {"Maybank", "CIMB", "Public Bank", "RHB", "Hong Leong", "AmBank", "UOB", "HSBC"};
        String[] officialPackages = {
                "com.maybank2u.android", "com.maybank2u.m2uapp", "com.maybank2u.mae",
                "com.cimb.cimbclicks", "com.cimb.octo",
                "com.pbe.pbebank", "com.pbe.pbengage",
                "com.rhbgroup.rhbmobile", "com.rhbgroup.rhbnow",
                "com.hly.hlbconnect",
                "com.ambank.ambani",
                "com.uob.mighty.my",
                "com.hsbc.hsbcmalaysia"
        };

        for (String official : officialPackages) {
            if (official.equals(packageName)) return false;
        }

        String appNameLower = appName.toLowerCase();
        for (String keyword : bankKeywords) {
            if (appNameLower.contains(keyword.toLowerCase())) return true;
            if (levenshteinDistance(appNameLower, keyword.toLowerCase()) <= 1) return true;
        }
        return false;
    }

    private static int levenshteinDistance(String s1, String s2) {
        int[][] dp = new int[s1.length() + 1][s2.length() + 1];
        for (int i = 0; i <= s1.length(); i++) dp[i][0] = i;
        for (int j = 0; j <= s2.length(); j++) dp[0][j] = j;
        for (int i = 1; i <= s1.length(); i++) {
            for (int j = 1; j <= s2.length(); j++) {
                int cost = s1.charAt(i - 1) == s2.charAt(j - 1) ? 0 : 1;
                dp[i][j] = Math.min(Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1), dp[i - 1][j - 1] + cost);
            }
        }
        return dp[s1.length()][s2.length()];
    }

    public static Map<String, Object> getSecuritySignals(Context context) {
        Map<String, Object> signals = new HashMap<>();
        signals.put("isDebuggerConnected", android.os.Debug.isDebuggerConnected());

        boolean isEmulator = Build.FINGERPRINT.contains("generic") ||
                Build.FINGERPRINT.contains("unknown") ||
                Build.MODEL.contains("google_sdk") ||
                Build.MODEL.contains("gphone") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK built for x86") ||
                "QC_Reference_Phone".equals(Build.BOARD) ||
                Build.MANUFACTURER.contains("Genymotion") ||
                Build.HOST.startsWith("Build") ||
                (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) ||
                "google_sdk".equals(Build.PRODUCT);
        signals.put("isEmulator", isEmulator);

        signals.put("isFridaDetected", detectFrida());
        signals.put("isXposedDetected", detectXposed(context));

        InputMethodManager imm = (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
        int untrustedImeCount = 0;
        if (imm != null) {
            List<InputMethodInfo> enabledImeList = imm.getEnabledInputMethodList();
            for (InputMethodInfo ime : enabledImeList) {
                String imeId = ime.getId();
                boolean isTrusted = imeId.startsWith("com.google.android.inputmethod") ||
                        imeId.startsWith("com.samsung.android.honeyboard") ||
                        imeId.startsWith("com.microsoft.emojis") ||
                        imeId.startsWith("com.android.inputmethod");
                if (!isTrusted) untrustedImeCount++;
            }
        }
        signals.put("untrustedImeCount", untrustedImeCount);
        signals.put("isRooted", checkRootMethod());

        return signals;
    }

    private static boolean detectFrida() {
        String[] fridaFiles = {"/data/local/tmp/re.frida.server", "/data/local/tmp/frida-server", "/usr/bin/frida-server"};
        for (String path : fridaFiles) {
            if (new File(path).exists()) return true;
        }
        try {
            Socket socket = new Socket("127.0.0.1", 27042);
            socket.close();
            return true;
        } catch (Exception ignored) {}
        return false;
    }

    private static boolean detectXposed(Context context) {
        try {
            Class.forName("de.robv.android.xposed.XposedBridge");
            return true;
        } catch (ClassNotFoundException ignored) {}
        List<PackageInfo> packages = context.getPackageManager().getInstalledPackages(0);
        for (PackageInfo pkg : packages) {
            if (pkg.packageName.contains("de.robv.android.xposed.installer")) return true;
        }
        return false;
    }

    private static boolean checkRootMethod() {
        String[] paths = {"/system/app/Superuser.apk", "/sbin/su", "/system/bin/su", "/system/xbin/su",
                "/data/local/xbin/su", "/data/local/bin/su", "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su"};
        for (String path : paths) {
            if (new File(path).exists()) return true;
        }
        return false;
    }

    @SuppressWarnings("deprecation")
    private static String getAppSignature(Context context, String packageName) {
        try {
            PackageManager pm = context.getPackageManager();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                PackageInfo packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES);
                SigningInfo signingInfo = packageInfo.signingInfo;
                if (signingInfo != null) {
                    android.content.pm.Signature[] signatures;
                    if (signingInfo.hasMultipleSigners()) {
                        signatures = signingInfo.getApkContentsSigners();
                    } else {
                        signatures = signingInfo.getSigningCertificateHistory();
                    }
                    if (signatures != null && signatures.length > 0) {
                        return hashSignature(signatures[0].toByteArray());
                    }
                }
            } else {
                PackageInfo packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES);
                if (packageInfo.signatures != null && packageInfo.signatures.length > 0) {
                    return hashSignature(packageInfo.signatures[0].toByteArray());
                }
            }
        } catch (Exception ignored) {}
        return null;
    }

    private static String hashSignature(byte[] signature) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(signature);
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return null;
        }
    }
}
