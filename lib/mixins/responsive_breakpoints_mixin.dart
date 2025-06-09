// lib/mixins/responsive_breakpoints_mixin.dart

import 'package:flutter/material.dart';

mixin ResponsiveBreakpointsMixin {
  // Screen size breakpoints
  static const double xsBreakpoint = 360;
  static const double smBreakpoint = 600;
  static const double mdBreakpoint = 900;
  static const double lgBreakpoint = 1200;
  static const double xlBreakpoint = 1600;

  // Check current breakpoint
  bool isXS(BuildContext context) => MediaQuery.of(context).size.width < xsBreakpoint;
  bool isSM(BuildContext context) => MediaQuery.of(context).size.width >= xsBreakpoint && MediaQuery.of(context).size.width < smBreakpoint;
  bool isMD(BuildContext context) => MediaQuery.of(context).size.width >= smBreakpoint && MediaQuery.of(context).size.width < mdBreakpoint;
  bool isLG(BuildContext context) => MediaQuery.of(context).size.width >= mdBreakpoint && MediaQuery.of(context).size.width < lgBreakpoint;
  bool isXL(BuildContext context) => MediaQuery.of(context).size.width >= lgBreakpoint && MediaQuery.of(context).size.width < xlBreakpoint;
  bool isXXL(BuildContext context) => MediaQuery.of(context).size.width >= xlBreakpoint;

  // Mobile/Tablet/Desktop helpers
  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < smBreakpoint;
  bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= smBreakpoint && MediaQuery.of(context).size.width < mdBreakpoint;
  bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= mdBreakpoint;

  // Get responsive grid columns
  int getGridColumns(BuildContext context, {int xs = 1, int sm = 2, int md = 3, int lg = 4, int xl = 5}) {
    final width = MediaQuery.of(context).size.width;
    if (width < xsBreakpoint) return xs;
    if (width < smBreakpoint) return sm;
    if (width < mdBreakpoint) return md;
    if (width < lgBreakpoint) return lg;
    return xl;
  }

  // Get current breakpoint name
  String getCurrentBreakpoint(BuildContext context) {
    if (isXS(context)) return 'xs';
    if (isSM(context)) return 'sm';
    if (isMD(context)) return 'md';
    if (isLG(context)) return 'lg';
    if (isXL(context)) return 'xl';
    return 'xxl';
  }
}