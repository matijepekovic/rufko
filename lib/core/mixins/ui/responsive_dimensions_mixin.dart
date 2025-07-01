// lib/mixins/responsive_dimensions_mixin.dart

import 'package:flutter/material.dart';

mixin ResponsiveDimensionsMixin {
  // Screen dimensions
  double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;
  double screenHeight(BuildContext context) => MediaQuery.sizeOf(context).height;
  EdgeInsets screenPadding(BuildContext context) => MediaQuery.paddingOf(context);
  EdgeInsets viewInsets(BuildContext context) => MediaQuery.viewInsetsOf(context);

  // Orientation
  Orientation orientation(BuildContext context) => MediaQuery.of(context).orientation;
  bool isPortrait(BuildContext context) => orientation(context) == Orientation.portrait;
  bool isLandscape(BuildContext context) => orientation(context) == Orientation.landscape;

  // Text scale
  double textScaleFactor(BuildContext context) => MediaQuery.of(context).textScaler.scale(1.0);

  // Device pixel ratio
  double devicePixelRatio(BuildContext context) => MediaQuery.of(context).devicePixelRatio;

  // Responsive value based on screen size
  T responsiveValue<T>(
      BuildContext context, {
        required T mobile,
        T? tablet,
        T? desktop,
        T? largeDesktop,
      }) {
    final width = screenWidth(context);
    if (width >= 1200) return largeDesktop ?? desktop ?? tablet ?? mobile;
    if (width >= 900) return desktop ?? tablet ?? mobile;
    if (width >= 600) return tablet ?? mobile;
    return mobile;
  }

  /// Responsive value using Material window size classes.
  T windowClassValue<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    final width = screenWidth(context);
    if (width >= 1240) return expanded ?? medium ?? compact;
    if (width >= 600) return medium ?? compact;
    return compact;
  }

  // Get percentage of screen width/height
  double percentWidth(BuildContext context, double percent) => screenWidth(context) * percent / 100;
  double percentHeight(BuildContext context, double percent) => screenHeight(context) * percent / 100;

  // Safe area aware dimensions
  double safeWidth(BuildContext context) => screenWidth(context) - screenPadding(context).horizontal;
  double safeHeight(BuildContext context) => screenHeight(context) - screenPadding(context).vertical;
}