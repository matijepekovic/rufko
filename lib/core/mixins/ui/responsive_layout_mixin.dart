// lib/mixins/responsive_layout_mixin.dart

import 'responsive_breakpoints_mixin.dart';
import 'responsive_dimensions_mixin.dart';
import 'responsive_spacing_mixin.dart';
import 'responsive_text_mixin.dart';
import 'responsive_widget_mixin.dart';

// Master mixin that includes all responsive functionality
mixin ResponsiveLayoutMixin
on ResponsiveBreakpointsMixin,
    ResponsiveDimensionsMixin,
    ResponsiveSpacingMixin,
    ResponsiveTextMixin,
    ResponsiveWidgetMixin {
  // This mixin combines all responsive mixins for easy usage
}