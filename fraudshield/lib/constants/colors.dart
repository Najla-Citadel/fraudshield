import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';

@Deprecated('Use DesignTokens.colors instead for new development. '
    'This class will be removed once the global migration is complete.')
class AppColors {
  static Color get primaryBlue => DesignTokens.colors.primary;
  static Color get deepNavy => DesignTokens.colors.backgroundDark;
  static Color get accentGreen => DesignTokens.colors.accentGreen;
  static Color get lightBg => DesignTokens.colors.backgroundLight;
  static Color get textLight => DesignTokens.colors.textLight;
  static Color get textDark => DesignTokens.colors.textDark;
  static Color get premiumYellow => DesignTokens.colors.premiumYellow;
  static Color get premiumYellowText => DesignTokens.colors.premiumYellowText;

  // Legacy colors still used in older screens
  static const Color lightBlue = Color(0xFFE9F3FF);
  static const Color darkText = Color(0xFF1C1C1E);
  static const Color greyText = Color(0xFF8E8E93);
  static const Color background = Colors.white;
  static const Color blueLight = Color(0xFF3B82F6);
  static const Color blueDark = Color(0xFF1E40AF);
  static const Color cardWhite = Colors.white;
  static const Color healthGradientStart = Color(0xFF60A5FA);
  static const Color healthGradientEnd = Color(0xFF2563EB);
  static const Color iconBlue = Color(0xFF3B82F6);
}
