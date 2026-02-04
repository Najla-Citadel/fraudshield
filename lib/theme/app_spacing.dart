import 'package:flutter/material.dart';

class AppSpacing {
  // 📏 SPACING (Grid of 4)
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 60.0;

  // 📐 RADIUS
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  
  // 🔘 BORDER RADIUS OBJECTS
  static BorderRadius sm = BorderRadius.circular(radiusS);
  static BorderRadius md = BorderRadius.circular(radiusM);
  static BorderRadius lg = BorderRadius.circular(radiusL);
  static BorderRadius xlRadius = BorderRadius.circular(radiusXL);

  // 📦 COMMON PADDING
  static const EdgeInsets screenPadding = EdgeInsets.all(l);
  static const EdgeInsets cardPadding = EdgeInsets.all(m);
}
