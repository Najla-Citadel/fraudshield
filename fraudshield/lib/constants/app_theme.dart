import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/tokens/design_tokens.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // 🌞 Light Theme
  static ThemeData get lightTheme {
    final colors = DesignTokens.colors;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.backgroundDark,
        onSecondary: Colors.white,
        surface: colors.surfaceLight,
        onSurface: colors.backgroundDark,
        background: colors.backgroundLight,
        onBackground: colors.backgroundDark,
        error: colors.error,
        outline: const Color(0xFFE2E8F0), // Slate 200
      ),
      scaffoldBackgroundColor: colors.backgroundLight,
      cardColor: colors.surfaceLight,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.backgroundDark),
        titleTextStyle: TextStyle(
          color: colors.backgroundDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🌚 Dark Theme
  static ThemeData get darkTheme {
    final colors = DesignTokens.colors;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: colors.primaryDark,
        onPrimary: Colors.white,
        secondary: colors.secondaryDark,
        onSecondary: colors.secondaryLight,
        surface: colors.surfaceDark,
        onSurface: colors.secondaryDark,
        background: colors.backgroundDark,
        onBackground: colors.secondaryDark,
        error: colors.error,
        outline: const Color(0xFF334155), // Slate 700
      ),
      scaffoldBackgroundColor: colors.backgroundDark,
      cardColor: colors.surfaceDark,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.secondaryDark),
        titleTextStyle: TextStyle(
          color: colors.secondaryDark,
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
