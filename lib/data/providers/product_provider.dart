import 'package:flutter/foundation.dart';
import '../models/business/product.dart';
import '../../core/services/database/database_service.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Product> _products = [];

  ProductProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<Product> get products => _products;

  Future<void> loadProducts() async {
    try {
      _products = await _db.getAllProducts();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addProduct(Product product) async {
    await _db.saveProduct(product);
    _products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db.saveProduct(product);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) _products[index] = product;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lower = query.toLowerCase();
    return _products
        .where((p) => p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower))
        .toList();
  }
}
