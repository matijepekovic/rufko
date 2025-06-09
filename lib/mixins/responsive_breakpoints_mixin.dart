// lib/mixins/responsive_breakpoints_mixin.dart

import 'package:flutter/material.dart';

/// Material 3 window size classes.
enum WindowSizeClass { compact, medium, expanded }

mixin ResponsiveBreakpointsMixin {
  // Screen size breakpoints
  static const double xsBreakpoint = 360;
  static const double smBreakpoint = 600;
  static const double mdBreakpoint = 900;
  static const double lgBreakpoint = 1200;
  static const double xlBreakpoint = 1600;

  // Material window size class breakpoints
  static const double compactBreakpoint = 600;
  static const double mediumBreakpoint = 1240;

  // Check current breakpoint
  bool isXS(BuildContext context) => MediaQuery.sizeOf(context).width < xsBreakpoint;
  bool isSM(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= xsBreakpoint &&
      MediaQuery.sizeOf(context).width < smBreakpoint;
  bool isMD(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= smBreakpoint &&
      MediaQuery.sizeOf(context).width < mdBreakpoint;
  bool isLG(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mdBreakpoint &&
      MediaQuery.sizeOf(context).width < lgBreakpoint;
  bool isXL(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= lgBreakpoint &&
      MediaQuery.sizeOf(context).width < xlBreakpoint;
  bool isXXL(BuildContext context) => MediaQuery.sizeOf(context).width >= xlBreakpoint;

  // Mobile/Tablet/Desktop helpers
  bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < smBreakpoint;
  bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= smBreakpoint &&
      MediaQuery.sizeOf(context).width < mdBreakpoint;
  bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mdBreakpoint;

  // Material window size classes
  WindowSizeClass windowSizeClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactBreakpoint) return WindowSizeClass.compact;
    if (width < mediumBreakpoint) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  bool isCompact(BuildContext context) =>
      windowSizeClass(context) == WindowSizeClass.compact;
  bool isMedium(BuildContext context) =>
      windowSizeClass(context) == WindowSizeClass.medium;
  bool isExpanded(BuildContext context) =>
      windowSizeClass(context) == WindowSizeClass.expanded;

  // Get responsive grid columns
  int getGridColumns(BuildContext context, {int xs = 1, int sm = 2, int md = 3, int lg = 4, int xl = 5}) {
    final width = MediaQuery.sizeOf(context).width;
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