import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/design_tokens.dart';
import 'app_loading_indicator.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final Widget? iconWidget;
  final IconData? suffixIcon;
  final double? width;
  final bool hapticFeedback;
  final String? semanticsLabel;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.suffixIcon,
    this.width,
    this.hapticFeedback = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DesignTokens.colors;
    final radii = DesignTokens.radii;
    final spacing = DesignTokens.spacing;

    // Define colors based on variant
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = colors.primary;
        foregroundColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = colors.primary.withOpacity(0.1);
        foregroundColor = colors.primary;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        border = BorderSide(color: colors.primary, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        break;
      case AppButtonVariant.destructive:
        backgroundColor = colors.error;
        foregroundColor = Colors.white;
        break;
    }

    // Define dimensions based on size
    double height;
    double fontSize;
    double horizontalPadding;
    double iconSize;

    switch (size) {
      case AppButtonSize.sm:
        height = 36;
        fontSize = 13;
        horizontalPadding = spacing.md;
        iconSize = 16;
        break;
      case AppButtonSize.md:
        height = 48;
        fontSize = 15;
        horizontalPadding = spacing.xxl;
        iconSize = 20;
        break;
      case AppButtonSize.lg:
        height = 56;
        fontSize = 17;
        horizontalPadding = spacing.xxxl;
        iconSize = 24;
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    return Semantics(
      label: semanticsLabel ?? label,
      button: true,
      enabled: isEnabled,
      child: SizedBox(
        width: width,
        height: height,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.6,
          child: ElevatedButton(
            onPressed: isEnabled
                ? () {
                    if (hapticFeedback) HapticFeedback.lightImpact();
                    onPressed?.call();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radii.md),
                side: border ?? BorderSide.none,
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return foregroundColor.withOpacity(0.1);
                }
                return null;
              }),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  AppLoadingIndicator(
                    size: iconSize * 0.8,
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                  SizedBox(width: spacing.md),
                ] else if (iconWidget != null) ...[
                  iconWidget!,
                  SizedBox(width: spacing.sm),
                ] else if (icon != null) ...[
                  Icon(icon, size: iconSize),
                  SizedBox(width: spacing.sm),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                if (!isLoading && suffixIcon != null) ...[
                  SizedBox(width: spacing.sm),
                  Icon(suffixIcon, size: iconSize),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
