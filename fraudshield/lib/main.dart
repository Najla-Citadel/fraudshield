import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'services/security_service.dart';
import 'app_router.dart';
import 'constants/app_theme.dart';
import 'screens/root_screen.dart';
import 'services/call_state_service.dart';
import 'services/clipboard_monitor_service.dart';
import 'services/smart_capture_service.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/locale_provider.dart';
import 'widgets/macau_intervention_overlay.dart';
import 'widgets/caller_risk_overlay.dart';
import 'widgets/post_call_safety_check.dart';
import 'widgets/cooldown_banner.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint('OVERLAY: >>> overlayMain STARTED (Inside main.dart) <<<');

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5), // Tint everything
        body: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 4),
          ),
          child: StreamBuilder<dynamic>(
            stream: FlutterOverlayWindow.overlayListener,
            builder: (context, snapshot) {
              final data = snapshot.data;
              debugPrint('OVERLAY: >>> Received Data Update: $data <<<');
              return CallerRiskOverlay(
                callerData: data is Map<String, dynamic> ? data : null,
                isSystemOverlay: true,
              );
            },
          ),
        ),
      ),
    ),
  );
}

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('--- FraudShield App Starting ---');
  }
  await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FlutterError.dumpErrorToConsole(errorDetails);
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // 🛡️ Initialize Security Checks
  await SecurityService.instance.init();

  // 🔔 Initialize Phase 2 Services
  await _initBackgroundService();
  await NotificationService.instance.init();
  await CallStateService.instance.init();
  ClipboardMonitorService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('smart_capture_enabled') ?? false) {
    await SmartCaptureService().start();
  }
  if (prefs.getBool('caller_id_protection_enabled') ?? false) {
    await CallStateService.instance.startProtection();
  }

  runApp(const FraudShieldApp());
}

Future<void> _initBackgroundService() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'fraudshield_background',
      channelName: 'FraudShield Protection',
      channelDescription: 'Maintains background call & alert monitoring',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      isOnceEvent: false,
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

class FraudShieldApp extends StatelessWidget {
  const FraudShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (context) {
          final service = NotificationService.instance;
          service.onNavigate = (route, args) {
            AppRouter.navigatorKey.currentState
                ?.pushNamed(route, arguments: args);
          };
          return service;
        }),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (_, theme, localeProvider, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FraudShield',
            locale: localeProvider.locale,
            themeMode: theme.mode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ms'), // Bahasa Malaysia
            ],
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.generate,
            home: const RootScreen(),
            builder: (context, child) {
              return Consumer<NotificationService>(
                builder: (context, notification, _) {
                  return Stack(
                    children: [
                      if (child != null) child,
                      if (notification.activeCallerRisk != null)
                        CallerRiskOverlay(
                          callerData: notification.activeCallerRisk!,
                        ),
                      if (notification.activeIntervention != null)
                        MacauInterventionOverlay(
                          evaluation: notification.activeIntervention!,
                        ),
                      if (notification.postCallCheck != null)
                        PostCallSafetyCheck(
                          data: notification.postCallCheck!,
                        ),
                      if (notification.coolDownActive) const CoolDownBanner(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
