import 'package:flutter/material.dart';
import '../tokens/design_tokens.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final double? value;
  final Color? backgroundColor;

  const AppLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.color,
    this.value,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator.adaptive(
        value: value,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? DesignTokens.colors.accentGreen,
        ),
      ),
    );
  }

  static Widget center({double size = 32.0, Color? color}) {
    return Center(
      child: AppLoadingIndicator(
        size: size,
        color: color,
        strokeWidth: size / 10,
      ),
    );
  }
}
