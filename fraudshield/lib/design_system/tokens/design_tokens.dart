import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._();

  static const colors = DesignColors();
  static const spacing = AppSpacing();
  static const radii = AppRadii();
  static const shadows = AppShadows();
}

class DesignColors {
  const DesignColors();

  // 🔵 Brand & Primary
  final Color primary = const Color(0xFF2563EB);    // Royal Blue (from AppTheme)
  final Color primaryDark = const Color(0xFF3B82F6);
  final Color primaryBlue = const Color(0xFF1565C0); // Specific Blue (from AppColors)

  // 🌑 Surface & Background
  final Color secondaryDark = const Color(0xFFF8FAFC);  // Slate 50 (from AppTheme)
  final Color secondaryLight = const Color(0xFF0F172A); // Slate 900 (from AppTheme)
  
  final Color backgroundDark = const Color(0xFF0F172A); // Slate 900
  final Color backgroundLight = const Color(0xFFF1F5F9); // Slate 100
  final Color surfaceDark = const Color(0xFF1E293B);    // Slate 800
  final Color surfaceLight = const Color(0xFFFFFFFF);
  final Color deepNavy = const Color(0xFF0B1121);
  final Color lightBg = const Color(0xFFF8FAFC);

  // 🟢 Semantic
  final Color success = const Color(0xFF10B981);
  final Color error = const Color(0xFFEF4444);
  final Color warning = const Color(0xFFF59E0B);
  final Color info = const Color(0xFF3B82F6);

  // ✨ Accents
  final Color accentGreen = const Color(0xFF10B981);
  final Color premiumYellow = const Color(0xFFFFD700);
  final Color premiumYellowText = const Color(0xFF854D0E);

  // 📝 Text
  final Color textDark = const Color(0xFF111827);
  final Color textLight = Colors.white;
  final Color textGrey = const Color(0xFF8E8E93);

  // 🏁 Borders & Dividers
  final Color divider = const Color(0x1AFFFFFF); // White @ 10%
  final Color border = const Color(0x0DFFFFFF);  // White @ 5%

  // 🌉 Gradients
  List<Color> get mainGradient => [
        const Color(0xFF0F172A),
        const Color(0xFF0B1121),
        const Color(0xFF1E3A8A),
      ];
}

class AppSpacing {
  const AppSpacing();

  final double xs = 4.0;
  final double sm = 8.0;
  final double md = 12.0;
  final double lg = 16.0;
  final double xl = 20.0;
  final double xxl = 24.0;
  final double xxxl = 32.0;
  final double huge = 48.0;
}

class AppRadii {
  const AppRadii();

  final double xs = 8.0;
  final double sm = 12.0;
  final double md = 16.0;
  final double lg = 20.0;
  final double xl = 24.0;
  final double xxl = 28.0;
}

class AppShadows {
  const AppShadows();

  List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  List<BoxShadow> get glass => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 30,
          spreadRadius: -5,
        ),
      ];
}
