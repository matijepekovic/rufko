import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rufko/data/providers/state/app_state_provider.dart';
import 'package:rufko/features/customers/presentation/screens/customers_screen.dart';

void main() {
  testWidgets('Customers screen has title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppStateProvider>(
        create: (_) => AppStateProvider(),
        child: const MaterialApp(home: CustomersScreen()),
      ),
    );

    expect(find.text('Customers'), findsOneWidget);
  });
}
