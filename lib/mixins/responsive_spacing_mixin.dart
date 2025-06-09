// lib/mixins/responsive_spacing_mixin.dart

import 'package:flutter/material.dart';
import 'responsive_breakpoints_mixin.dart';

mixin ResponsiveSpacingMixin on ResponsiveBreakpointsMixin {
  // Base spacing unit
  double baseSpacing(BuildContext context) {
    if (isXS(context)) return 4.0;
    if (isSM(context)) return 6.0;
    if (isMD(context)) return 8.0;
    return 10.0;
  }

  // Responsive spacing multipliers
  double spacing(BuildContext context, double multiplier) => baseSpacing(context) * multiplier;

  // Common spacing values
  double spacingXS(BuildContext context) => spacing(context, 0.5);  // 2, 3, 4, 5
  double spacingSM(BuildContext context) => spacing(context, 1);    // 4, 6, 8, 10
  double spacingMD(BuildContext context) => spacing(context, 2);    // 8, 12, 16, 20
  double spacingLG(BuildContext context) => spacing(context, 3);    // 12, 18, 24, 30
  double spacingXL(BuildContext context) => spacing(context, 4);    // 16, 24, 32, 40
  double spacingXXL(BuildContext context) => spacing(context, 6);   // 24, 36, 48, 60

  // Responsive padding
  EdgeInsets responsivePadding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final base = baseSpacing(context);
    return EdgeInsets.only(
      left: left != null ? left * base : (horizontal ?? all ?? 2) * base,
      top: top != null ? top * base : (vertical ?? all ?? 2) * base,
      right: right != null ? right * base : (horizontal ?? all ?? 2) * base,
      bottom: bottom != null ? bottom * base : (vertical ?? all ?? 2) * base,
    );
  }

  // Screen edge padding
  EdgeInsets screenPadding(BuildContext context) {
    if (isXS(context)) return const EdgeInsets.all(8);
    if (isSM(context)) return const EdgeInsets.all(16);
    if (isMD(context)) return const EdgeInsets.all(24);
    if (isLG(context)) return const EdgeInsets.all(32);
    return const EdgeInsets.all(48);
  }

  // Card padding
  EdgeInsets cardPadding(BuildContext context) {
    if (isXS(context)) return const EdgeInsets.all(12);
    if (isSM(context)) return const EdgeInsets.all(16);
    return const EdgeInsets.all(20);
  }
}