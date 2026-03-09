import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? placeholder;
  final String? hintText;
  final int maxLines;
  final bool? filled;
  final Color? fillColor;
  final Color? textColor;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final IconData? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const AdaptiveTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.placeholder,
    this.hintText,
    this.maxLines = 1,
    this.filled,
    this.fillColor,
    this.textColor,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isIos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: DesignTokens.spacing.xs, bottom: DesignTokens.spacing.sm),
            child: Text(
              label,
              style: TextStyle(
                color:
                    isDark ? CupertinoColors.white : CupertinoColors.systemGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoTextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            placeholder: hintText ?? placeholder ?? label,
            maxLines: maxLines,
            autofocus: autofocus,
            readOnly: readOnly,
            enabled: enabled,
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            prefix: prefixIcon != null
                ? Padding(
                    padding: EdgeInsets.only(left: DesignTokens.spacing.lg),
                    child: Icon(prefixIcon, color: CupertinoColors.systemGrey),
                  )
                : null,
            suffix: suffixIcon != null
                ? Padding(
                    padding: EdgeInsets.only(right: DesignTokens.spacing.lg),
                    child: Icon(suffixIcon, color: CupertinoColors.systemGrey),
                  )
                : null,
            decoration: BoxDecoration(
              color: fillColor ??
                  (isDark
                      ? CupertinoColors.systemGrey6.darkColor
                      : CupertinoColors.systemGrey6),
              borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            ),
            style: TextStyle(
              color: textColor ??
                  (isDark ? CupertinoColors.white : CupertinoColors.black),
            ),
          ),
        ],
      );
    } else {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        autofocus: autofocus,
        readOnly: readOnly,
        enabled: enabled,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        style: TextStyle(
          color: textColor ?? (isDark ? Colors.white : Colors.black),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: errorText != null
                ? DesignTokens.colors.error
                : Colors.white.withValues(alpha: 0.5),
          ),
          hintText: hintText ?? placeholder,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  color: errorText != null
                      ? DesignTokens.colors.error
                      : DesignTokens.colors.primary,
                  size: 20)
              : null,
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.white.withValues(alpha: 0.3), size: 20)
              : null,
          errorText: errorText,
          errorStyle: TextStyle(color: DesignTokens.colors.error),
          filled: true,
          fillColor: fillColor ?? Colors.white.withValues(alpha: 0.05),
          contentPadding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            borderSide: BorderSide(
              color: errorText != null
                  ? DesignTokens.colors.error
                  : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            borderSide: BorderSide(
              color: errorText != null
                  ? DesignTokens.colors.error
                  : DesignTokens.colors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            borderSide: BorderSide(color: DesignTokens.colors.error, width: 1),
          ),
        ),
      );
    }
  }
}
