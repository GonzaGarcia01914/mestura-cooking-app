import 'package:flutter/material.dart';

/// Simple responsive helpers for tablet/desktop layouts.
class Responsive {
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Returns a comfortable max content width for center-constrained layouts.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreakpoint) return 1100;
    if (w >= tabletBreakpoint) return 900;
    return w; // On phones, fill width
  }

  /// Horizontal padding for pages.
  static double hPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreakpoint) return 40;
    if (w >= tabletBreakpoint) return 32;
    return 20;
  }
}

