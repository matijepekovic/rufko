import 'package:flutter/material.dart';

import '../mixins/responsive_breakpoints_mixin.dart';
import '../mixins/responsive_dimensions_mixin.dart';
import '../mixins/responsive_spacing_mixin.dart';
import '../mixins/responsive_text_mixin.dart';
import '../mixins/responsive_widget_mixin.dart';
import '../mixins/responsive_layout_mixin.dart';

class AdaptiveQuoteCard extends StatelessWidget
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin,
        ResponsiveLayoutMixin {
  final Widget child;
  final EdgeInsets? padding;
  const AdaptiveQuoteCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? cardPadding(context),
        child: child,
      ),
    );
  }
}
