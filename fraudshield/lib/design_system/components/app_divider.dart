import 'package:flutter/material.dart';

class AppDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;

  const AppDivider({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? 1.0,
      thickness: thickness ?? 1.0,
      indent: indent,
      endIndent: endIndent,
      color: color ?? Colors.white.withOpacity(0.1),
    );
  }

  static Widget vertical({
    double? width,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
  }) {
    return VerticalDivider(
      width: width ?? 1.0,
      thickness: thickness ?? 1.0,
      indent: indent,
      endIndent: endIndent,
      color: color ?? Colors.white.withOpacity(0.1),
    );
  }
}
