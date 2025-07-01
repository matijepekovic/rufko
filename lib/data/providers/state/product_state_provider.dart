import 'package:flutter/foundation.dart';

import '../../models/business/product.dart';
import '../../../core/services/database/database_service.dart';
import '../helpers/data_loading_helper.dart';
import '../helpers/product_helper.dart';

/// Provider responsible for managing [Product] data and business rules.
/// Extracted from `AppStateProvider` to keep product logic isolated.
class ProductStateProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Product> _products = [];

  ProductStateProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<Product> get products => _products;

  /// Loads all products from the database.
  Future<void> loadProducts() async {
    _products = await DataLoadingHelper.loadProducts(_db);
    notifyListeners();
  }

  /// Adds a new product and persists it.
  Future<void> addProduct(Product product) async {
    await ProductHelper.addProduct(
        db: _db, products: _products, product: product);
    notifyListeners();
  }

  /// Updates an existing product.
  Future<void> updateProduct(Product product) async {
    await ProductHelper.updateProduct(
        db: _db, products: _products, product: product);
    notifyListeners();
  }

  /// Deletes a product by [productId].
  Future<void> deleteProduct(String productId) async {
    await ProductHelper.deleteProduct(
        db: _db, products: _products, productId: productId);
    notifyListeners();
  }

  /// Imports a list of products, updating existing ones by name.
  Future<void> importProducts(List<Product> productsToImport) async {
    for (final product in productsToImport) {
      final existingIndex = _products.indexWhere(
          (p) => p.name.toLowerCase() == product.name.toLowerCase());
      if (existingIndex != -1) {
        await ProductHelper.updateProduct(
            db: _db, products: _products, product: product);
      } else {
        await ProductHelper.addProduct(
            db: _db, products: _products, product: product);
      }
    }
    notifyListeners();
  }

  /// Finds products matching the search [query].
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lower = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower))
        .toList();
  }

  /// Returns products belonging to [category].
  List<Product> filterByCategory(String category) {
    final lower = category.toLowerCase();
    return _products.where((p) => p.category.toLowerCase() == lower).toList();
  }

  /// Simple validation to ensure product integrity.
  bool validateProduct(Product product) {
    return product.name.trim().isNotEmpty && product.unitPrice >= 0;
  }

  /// Calculates the price with a percentage [markup].
  double priceWithMarkup(Product product, double markup) {
    return product.unitPrice * (1 + markup / 100);
  }
}
