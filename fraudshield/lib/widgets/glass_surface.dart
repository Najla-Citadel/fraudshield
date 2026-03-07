import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? accentColor;
  final double borderRadius;
  final bool borderGradient;
  final Color? borderColor;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.7, // Higher opacity for better readability in light mode
    this.padding,
    this.onTap,
    this.accentColor,
    this.borderRadius = 24.0,
    this.borderGradient = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Premium base color: Surface color with transparency
    final baseOpacity = isDark
        ? (opacity == 0.7 ? 0.05 : opacity)
        : (opacity == 0.7 ? 0.12 : opacity);

    final baseColor = accentColor == null
        ? Colors.white.withOpacity(baseOpacity)
        : Color.alphaBlend(
            accentColor!.withOpacity(0.1),
            Colors.white.withOpacity(baseOpacity),
          );

    // Subtle border color
    final effectiveBorderColor = borderColor ??
        accentColor?.withOpacity(0.3) ??
        (isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.6));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            highlightColor: colorScheme.primary.withOpacity(0.1),
            splashColor: colorScheme.primary.withOpacity(0.1),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: effectiveBorderColor,
                  width: 1.0,
                ),
                boxShadow: DesignTokens.shadows.sm,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
