import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'app_router.dart';
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
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF0F7FF),
              cardColor: Colors.white,
              textTheme: GoogleFonts.interTextTheme(),
            ),

            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              cardColor: const Color(0xFF1E293B),
              appBarTheme: const AppBarTheme(
                surfaceTintColor: Colors.transparent,
                backgroundColor: Colors.transparent,
              ),
            ),

            // ✅ ROUTING
            onGenerateRoute: AppRouter.generate,
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
