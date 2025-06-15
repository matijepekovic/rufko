import 'package:flutter/foundation.dart';

import '../../models/business/product.dart';
import '../../../core/services/database/database_service.dart';

/// Helper methods for managing [Product] records.
class ProductHelper {
  static Future<void> addProduct({
    required DatabaseService db,
    required List<Product> products,
    required Product product,
  }) async {
    await db.saveProduct(product);
    products.add(product);
    if (kDebugMode) {
      debugPrint('➕ Added product: ${product.name}');
    }
  }

  static Future<void> updateProduct({
    required DatabaseService db,
    required List<Product> products,
    required Product product,
  }) async {
    await db.saveProduct(product);
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      if (kDebugMode) {
        debugPrint('✅ Updated product in memory');
      }
    } else {
      products.add(product);
      if (kDebugMode) {
        debugPrint('⚠️ Product not found in memory, adding it');
      }
    }
  }

  static Future<void> deleteProduct({
    required DatabaseService db,
    required List<Product> products,
    required String productId,
  }) async {
    await db.deleteProduct(productId);
    products.removeWhere((p) => p.id == productId);
    if (kDebugMode) {
      debugPrint('🗑️ Deleted product $productId');
    }
  }
}
