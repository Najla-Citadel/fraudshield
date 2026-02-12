import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // 🎨 Semantic Colors
  static const _primaryLight = Color(0xFF2563EB); // Royal Blue
  static const _primaryDark = Color(0xFF3B82F6);
  
  static const _secondaryLight = Color(0xFF0F172A); // Slate 900
  static const _secondaryDark = Color(0xFFF8FAFC); // Slate 50
  
  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _surfaceDark = Color(0xFF1E293B); // Slate 800
  
  static const _backgroundLight = Color(0xFFF1F5F9); // Slate 100
  static const _backgroundDark = Color(0xFF0F172A); // Slate 900
  
  static const _error = Color(0xFFEF4444);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);

  // 🌞 Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        onPrimary: Colors.white,
        secondary: _secondaryLight,
        onSecondary: Colors.white,
        surface: _surfaceLight,
        onSurface: _secondaryLight,
        background: _backgroundLight,
        onBackground: _secondaryLight,
        error: _error,
        outline: Color(0xFFE2E8F0), // Slate 200
      ),
      scaffoldBackgroundColor: _backgroundLight,
      cardColor: _surfaceLight,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: _secondaryLight),
        titleTextStyle: TextStyle(
          color: _secondaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🌚 Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        onPrimary: Colors.white,
        secondary: _secondaryDark,
        onSecondary: _secondaryLight,
        surface: _surfaceDark,
        onSurface: _secondaryDark,
        background: _backgroundDark,
        onBackground: _secondaryDark,
        error: _error,
        outline: Color(0xFF334155), // Slate 700
      ),
      scaffoldBackgroundColor: _backgroundDark,
      cardColor: _surfaceDark,
      textTheme: _textTheme, // Google Fonts handles dark mode adaptation mostly, but colors need check
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: _secondaryDark),
        titleTextStyle: TextStyle(
          color: _secondaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ✍️ Text Theme (Shared)
  static TextTheme get _textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
