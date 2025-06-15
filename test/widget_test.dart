// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rufko/main.dart';
import 'package:rufko/data/providers/state/app_state_provider.dart';
import 'package:rufko/data/providers/customer_provider.dart';
import 'package:rufko/data/providers/state/product_state_provider.dart';
import 'package:rufko/data/providers/state/quote_state_provider.dart';
import 'package:rufko/data/providers/template_provider.dart';

Widget _createTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ChangeNotifierProvider(create: (_) => ProductStateProvider()),
      ChangeNotifierProvider(create: (_) => QuoteStateProvider()),
      ChangeNotifierProvider(create: (_) => TemplateProvider()),
    ],
    child: const RufkoApp(),
  );
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(_createTestApp());

    // Verify that the dashboard tab is visible
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
