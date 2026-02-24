import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'app_router.dart';
import 'constants/app_theme.dart';
import 'screens/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
    // Continue running app even if .env fails, ApiService has defaults
  }

  // Supabase initialization removed - using custom backend via ApiService

  runApp(const FraudShieldApp());
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
            AppRouter.navigatorKey.currentState?.pushNamed(route, arguments: args);
          };
          return service;
        }),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FraudShield',

              // ✅ THEME CONNECTION
            themeMode: theme.mode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,

            // ✅ ROUTING
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.generate,
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
