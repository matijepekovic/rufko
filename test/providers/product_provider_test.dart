import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rufko/providers/product_provider.dart';
import 'package:rufko/models/product.dart';
import 'package:rufko/services/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService db;
  late ProductProvider provider;

  setUp(() {
    db = MockDatabaseService();
    provider = ProductProvider(database: db);
  });

  test('loadProducts populates list', () async {
    final product = Product(name: 'Prod', unitPrice: 10);
    when(() => db.getAllProducts()).thenAnswer((_) async => [product]);

    await provider.loadProducts();

    expect(provider.products, [product]);
  });

  test('addProduct adds item to list', () async {
    final product = Product(name: 'Prod', unitPrice: 10);
    when(() => db.saveProduct(product)).thenAnswer((_) async {});

    await provider.addProduct(product);

    expect(provider.products.contains(product), isTrue);
    verify(() => db.saveProduct(product)).called(1);
  });

  test('updateProduct updates existing item', () async {
    final product = Product(name: 'Prod', unitPrice: 10);
    provider.products.add(product);

    final updated = Product(id: product.id, name: 'New', unitPrice: 20);
    when(() => db.saveProduct(updated)).thenAnswer((_) async {});

    await provider.updateProduct(updated);

    expect(provider.products.first.name, 'New');
  });

  test('deleteProduct removes item from list', () async {
    final product = Product(name: 'Prod', unitPrice: 10);
    provider.products.add(product);
    when(() => db.deleteProduct(product.id)).thenAnswer((_) async {});

    await provider.deleteProduct(product.id);

    expect(provider.products, isEmpty);
  });
}
