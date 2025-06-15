import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rufko/core/mixins/ui/responsive_breakpoints_mixin.dart';
import 'package:rufko/core/mixins/ui/responsive_dimensions_mixin.dart';
import 'package:rufko/core/mixins/ui/responsive_text_mixin.dart';

class _MixinTester
    with ResponsiveBreakpointsMixin, ResponsiveDimensionsMixin, ResponsiveTextMixin {}

void main() {
  final testerMixin = _MixinTester();

  testWidgets('responsiveFontSize clamps to min value', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    final size = testerMixin.responsiveFontSize(context, 10, min: 12);
    expect(size, 12);
  });

  testWidgets('responsiveFontSize clamps to max value', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    final size = testerMixin.responsiveFontSize(context, 20, max: 18);
    expect(size, 18);
  });

  testWidgets('windowClassValue returns expanded', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(1300, 800)),
        child: MaterialApp(home: SizedBox()),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    final value = testerMixin.windowClassValue(
      context,
      compact: 'c',
      medium: 'm',
      expanded: 'e',
    );
    expect(value, 'e');
  });
}
