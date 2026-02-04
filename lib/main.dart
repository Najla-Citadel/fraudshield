import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/secure_storage_service.dart';
import 'app_router.dart';
import 'screens/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file for development
  await dotenv.load(fileName: ".env");

  // Try to get credentials from secure storage first
  final secureStorage = SecureStorageService.instance;
  String? supabaseUrl = await secureStorage.getSupabaseUrl();
  String? supabaseAnonKey = await secureStorage.getSupabaseAnonKey();

  // Fallback to .env if not in secure storage (first run or development)
  if (supabaseUrl == null || supabaseAnonKey == null) {
    supabaseUrl = dotenv.env['SUPABASE_URL'];
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl != null && supabaseAnonKey != null) {
      // Save to secure storage for future use
      await secureStorage.saveSupabaseCredentials(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      log('⚠️ Using credentials from .env (development mode)');
    } else {
      throw Exception('Supabase credentials not found in secure storage or .env');
    }
  } else {
    log('✅ Using credentials from secure storage');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
            ),

            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              cardColor: const Color(0xFF1E293B),
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
