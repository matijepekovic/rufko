// lib/mixins/responsive_text_mixin.dart

import 'package:flutter/material.dart';
import 'responsive_breakpoints_mixin.dart';

mixin ResponsiveTextMixin on ResponsiveBreakpointsMixin {
  // Base font size scale
  double _baseFontScale(BuildContext context) {
    switch (windowSizeClass(context)) {
      case WindowSizeClass.compact:
        return 0.9;
      case WindowSizeClass.medium:
        return 1.0;
      case WindowSizeClass.expanded:
        return 1.1;
    }
  }

  // Responsive font size
  double responsiveFontSize(
    BuildContext context,
    double baseSize, {
    bool respectTextScale = true,
    double? min,
    double? max,
  }) {
    final scale = _baseFontScale(context);
    final textScale =
        respectTextScale ? MediaQuery.of(context).textScaler.scale(1.0) : 1.0;
    double size = baseSize * scale * textScale;
    if (min != null && max != null) {
      size = size.clamp(min, max);
    } else if (min != null) {
      if (size < min) size = min;
    } else if (max != null) {
      if (size > max) size = max;
    }
    return size;
  }

  // Text style helpers
  TextStyle responsiveTextStyle(
    BuildContext context,
    TextStyle baseStyle, {
    bool respectTextScale = true,
    double? min,
    double? max,
  }) {
    final fontSize = baseStyle.fontSize;
    if (fontSize == null) return baseStyle;

    return baseStyle.copyWith(
      fontSize: responsiveFontSize(
        context,
        fontSize,
        respectTextScale: respectTextScale,
        min: min,
        max: max,
      ),
      height: baseStyle.height, // Preserve line height ratio
    );
  }

  // Common text styles
  TextStyle headlineLarge(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        min: 14,
      );

  TextStyle headlineMedium(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        min: 14,
      );

  TextStyle headlineSmall(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        min: 14,
      );

  TextStyle titleLarge(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        min: 14,
      );

  TextStyle titleMedium(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        min: 14,
      );

  TextStyle titleSmall(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        min: 14,
      );

  TextStyle bodyLarge(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 16),
      );

  TextStyle bodyMedium(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 14),
      );

  TextStyle bodySmall(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 12),
      );

  TextStyle labelLarge(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      );

  TextStyle labelMedium(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      );

  TextStyle labelSmall(BuildContext context) => responsiveTextStyle(
        context,
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      );
}
