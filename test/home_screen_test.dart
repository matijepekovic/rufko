import 'package:flutter_test/flutter_test.dart';
import 'package:rufko/main.dart';

void main() {
  testWidgets('Home screen shows navigation items', (WidgetTester tester) async {
    await tester.pumpWidget(const RufkoApp());

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
  });
}
