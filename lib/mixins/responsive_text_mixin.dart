// lib/mixins/responsive_text_mixin.dart

import 'package:flutter/material.dart';
import 'responsive_breakpoints_mixin.dart';

mixin ResponsiveTextMixin on ResponsiveBreakpointsMixin {
  // Base font size scale
  double _baseFontScale(BuildContext context) {
    if (isXS(context)) return 0.85;
    if (isSM(context)) return 0.92;
    if (isMD(context)) return 1.0;
    if (isLG(context)) return 1.05;
    if (isXL(context)) return 1.1;
    return 1.15;
  }

  // Responsive font size
  double responsiveFontSize(BuildContext context, double baseSize, {bool respectTextScale = true}) {
    final scale = _baseFontScale(context);
    final textScale = respectTextScale ? MediaQuery.of(context).textScaleFactor : 1.0;
    return baseSize * scale * textScale;
  }

  // Text style helpers
  TextStyle responsiveTextStyle(BuildContext context, TextStyle baseStyle, {bool respectTextScale = true}) {
    final fontSize = baseStyle.fontSize;
    if (fontSize == null) return baseStyle;

    return baseStyle.copyWith(
      fontSize: responsiveFontSize(context, fontSize, respectTextScale: respectTextScale),
      height: baseStyle.height, // Preserve line height ratio
    );
  }

  // Common text styles
  TextStyle headlineLarge(BuildContext context) => responsiveTextStyle(
    context,
    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
  );

  TextStyle headlineMedium(BuildContext context) => responsiveTextStyle(
    context,
    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
  );

  TextStyle headlineSmall(BuildContext context) => responsiveTextStyle(
    context,
    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  );

  TextStyle titleLarge(BuildContext context) => responsiveTextStyle(
    context,
    const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
  );

  TextStyle titleMedium(BuildContext context) => responsiveTextStyle(
    context,
    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  );

  TextStyle titleSmall(BuildContext context) => responsiveTextStyle(
    context,
    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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