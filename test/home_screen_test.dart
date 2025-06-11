import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rufko/main.dart';
import 'package:rufko/providers/app_state_provider.dart';
import 'package:rufko/providers/customer_provider.dart';
import 'package:rufko/providers/product_state_provider.dart';
import 'package:rufko/providers/quote_state_provider.dart';
import 'package:rufko/providers/template_provider.dart';

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
  testWidgets('Home screen shows navigation items',
      (WidgetTester tester) async {
    await tester.pumpWidget(_createTestApp());

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
  });
}
