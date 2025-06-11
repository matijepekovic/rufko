import 'package:flutter/material.dart';

import '../mixins/responsive_breakpoints_mixin.dart';
import '../mixins/responsive_dimensions_mixin.dart';
import '../mixins/responsive_spacing_mixin.dart';
import '../mixins/responsive_text_mixin.dart';
import '../mixins/responsive_widget_mixin.dart';
import '../mixins/responsive_layout_mixin.dart';

class ResponsiveLevelGrid extends StatelessWidget
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin,
        ResponsiveLayoutMixin {
  final List<Widget> children;
  final int? columns;
  const ResponsiveLevelGrid({super.key, required this.children, this.columns});

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = columns ?? getGridColumns(context, xs: 1, sm: 2, md: 3, lg: 4, xl: 4);
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacingSM(context),
      crossAxisSpacing: spacingSM(context),
      childAspectRatio: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
