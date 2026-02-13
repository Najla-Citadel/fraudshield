import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? accentColor;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.5,
    this.padding,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.05) // Subtle glass for dark mode
                  : Theme.of(context).cardColor.withOpacity(opacity),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor?.withOpacity(0.5) ?? 
                  (isDark 
                    ? Colors.white.withOpacity(0.1) // Subtle border
                    : Colors.white.withOpacity(0.4)),
                width: 1.0, // Thinner border
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
