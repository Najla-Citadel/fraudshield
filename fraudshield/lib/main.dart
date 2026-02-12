import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'app_router.dart';
import 'constants/app_theme.dart';
import 'screens/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

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
        ChangeNotifierProvider(create: (_) => NotificationService.instance),
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
            onGenerateRoute: AppRouter.generate,
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
