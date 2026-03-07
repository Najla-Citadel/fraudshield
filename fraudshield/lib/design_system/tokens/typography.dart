import 'package:flutter/material.dart';
import 'design_tokens.dart';

class DesignTypography {
  DesignTypography._();

  static TextStyle get h1 => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: DesignTokens.colors.textLight,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: DesignTokens.colors.textLight,
        letterSpacing: -0.5,
      );

  static TextStyle get h3 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: DesignTokens.colors.textLight,
      );

  static TextStyle get bodyLg => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: DesignTokens.colors.textLight,
      );

  static TextStyle get bodyMd => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: DesignTokens.colors.textLight,
      );

  static TextStyle get bodySm => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: DesignTokens.colors.textLight,
      );

  static TextStyle get bodyXs => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: DesignTokens.colors.textLight,
      );

  static TextStyle get labelLg => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DesignTokens.colors.textLight,
      );

  static TextStyle get labelMd => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DesignTokens.colors.textLight,
      );

  static TextStyle get labelSm => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DesignTokens.colors.textLight,
      );
      
  static TextStyle get caption => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: DesignTokens.colors.textGrey,
        letterSpacing: 0.5,
      );
}
