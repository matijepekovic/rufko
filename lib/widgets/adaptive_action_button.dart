import 'package:flutter/material.dart';

import '../mixins/responsive_breakpoints_mixin.dart';
import '../mixins/responsive_dimensions_mixin.dart';
import '../mixins/responsive_spacing_mixin.dart';
import '../mixins/responsive_text_mixin.dart';
import '../mixins/responsive_widget_mixin.dart';
import '../mixins/responsive_layout_mixin.dart';

class AdaptiveActionButton extends StatelessWidget
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin,
        ResponsiveLayoutMixin {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AdaptiveActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.symmetric(vertical: spacingLG(context)),
      ),
    );
  }
}
