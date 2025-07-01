// lib/mixins/responsive_widget_mixin.dart

import 'package:flutter/material.dart';
import 'responsive_breakpoints_mixin.dart';
import 'responsive_dimensions_mixin.dart';

mixin ResponsiveWidgetMixin on ResponsiveBreakpointsMixin, ResponsiveDimensionsMixin {
  // Responsive builder
  Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? largeDesktop,
  }) {
    if (windowSizeClass(context) == WindowSizeClass.expanded &&
        largeDesktop != null) {
      return largeDesktop;
    }
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Choose a widget based on the Material window size class.
  Widget windowClassBuilder({
    required BuildContext context,
    required Widget compact,
    Widget? medium,
    Widget? expanded,
  }) {
    switch (windowSizeClass(context)) {
      case WindowSizeClass.compact:
        return compact;
      case WindowSizeClass.medium:
        return medium ?? compact;
      case WindowSizeClass.expanded:
        return expanded ?? medium ?? compact;
    }
  }

  // Orientation builder helper
  Widget orientationBuilder({
    required BuildContext context,
    required Widget portrait,
    required Widget landscape,
  }) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? portrait : landscape;
      },
    );
  }

  // Responsive aspect ratio
  Widget responsiveAspectRatio({
    required BuildContext context,
    required Widget child,
    double mobileRatio = 1.0,
    double? tabletRatio,
    double? desktopRatio,
  }) {
    final ratio = responsiveValue(
      context,
      mobile: mobileRatio,
      tablet: tabletRatio,
      desktop: desktopRatio,
    );

    return AspectRatio(
      aspectRatio: ratio,
      child: child,
    );
  }

  // Responsive container constraints
  BoxConstraints responsiveConstraints(BuildContext context, {
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) {
    return BoxConstraints(
      maxWidth: maxWidth ?? double.infinity,
      maxHeight: maxHeight ?? double.infinity,
      minWidth: minWidth ?? 0,
      minHeight: minHeight ?? 0,
    );
  }

  // Responsive flex
  int responsiveFlex(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Safe area wrapper
  Widget responsiveSafeArea({
    required BuildContext context,
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    // Only apply SafeArea on mobile devices
    if (isMobile(context)) {
      return SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: child,
      );
    }
    return child;
  }
}