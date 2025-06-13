import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rufko/data/providers/customer_provider.dart';
import 'package:rufko/data/models/business/customer.dart';
import 'package:rufko/core/services/database/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService db;
  late CustomerProvider provider;

  setUp(() {
    db = MockDatabaseService();
    provider = CustomerProvider(database: db);
  });

  test('loadCustomers populates list', () async {
    final customer = Customer(name: 'Test');
    when(() => db.getAllCustomers()).thenAnswer((_) async => [customer]);

    await provider.loadCustomers();

    expect(provider.customers, [customer]);
  });

  test('addCustomer adds item to list', () async {
    final customer = Customer(name: 'Test');
    when(() => db.saveCustomer(customer)).thenAnswer((_) async {});

    await provider.addCustomer(customer);

    expect(provider.customers.contains(customer), isTrue);
    verify(() => db.saveCustomer(customer)).called(1);
  });

  test('updateCustomer updates existing item', () async {
    final customer = Customer(name: 'Test');
    provider.customers.add(customer);

    final updated = Customer(id: customer.id, name: 'Updated');
    when(() => db.saveCustomer(updated)).thenAnswer((_) async {});

    await provider.updateCustomer(updated);

    expect(provider.customers.first.name, 'Updated');
  });

  test('deleteCustomer removes item from list', () async {
    final customer = Customer(name: 'Test');
    provider.customers.add(customer);
    when(() => db.deleteCustomer(customer.id)).thenAnswer((_) async {});

    await provider.deleteCustomer(customer.id);

    expect(provider.customers, isEmpty);
  });
}
