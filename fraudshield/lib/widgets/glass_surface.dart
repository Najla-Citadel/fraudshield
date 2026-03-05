import 'package:flutter/material.dart';
import 'dart:ui';

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
    final baseColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) // Subtle glass for dark mode
        : Colors.white.withValues(alpha: 0.65);

    // Subtle border color
    final effectiveBorderColor = borderColor ?? accentColor?.withValues(alpha: 0.3) ?? 
        (isDark 
            ? Colors.white.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.6));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: Colors.transparent, // Important for ripple
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            highlightColor: colorScheme.primary.withValues(alpha: 0.1),
            splashColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: effectiveBorderColor,
                  width: 1.0,
                ),
                boxShadow: [
                  // 1. Ambient Shadow (Soft)
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  // 2. Direct Shadow (Keeps it grounded)
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
