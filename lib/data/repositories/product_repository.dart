import 'package:sqflite/sqflite.dart';

import '../database/product_database.dart';
import '../models/business/product.dart';

/// Repository class for product-related database operations
/// Provides a clean interface for CRUD operations on product data
class ProductRepository {
  final ProductDatabase _database = ProductDatabase();

  // PRODUCT OPERATIONS

  /// Create a new product with its level prices
  Future<void> createProduct(Product product) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Insert the main product
      await txn.insert(
        ProductDatabase.productsTable,
        _database.productToMap(product),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert enhanced level prices
      for (final levelPrice in product.enhancedLevelPrices) {
        await txn.insert(
          ProductDatabase.productLevelPricesTable,
          _database.productLevelPriceToMap(levelPrice, product.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get all products with their level prices
  Future<List<Product>> getAllProducts() async {
    final db = await _database.database;
    
    // Get all products
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      orderBy: 'name ASC',
    );

    // Get all level prices
    final List<Map<String, dynamic>> levelPriceMaps = await db.query(
      ProductDatabase.productLevelPricesTable,
      orderBy: 'level_name ASC',
    );

    // Group level prices by product ID
    final Map<String, List<ProductLevelPrice>> levelPricesByProduct = {};
    for (final levelPriceMap in levelPriceMaps) {
      final productId = levelPriceMap['product_id'];
      final levelPrice = _database.productLevelPriceFromMap(levelPriceMap);
      
      levelPricesByProduct.putIfAbsent(productId, () => []);
      levelPricesByProduct[productId]!.add(levelPrice);
    }

    // Build products with their level prices
    return productMaps.map((productMap) {
      final productId = productMap['id'];
      final levelPrices = levelPricesByProduct[productId] ?? [];
      return _database.productFromMap(productMap, levelPrices: levelPrices);
    }).toList();
  }

  /// Get product by ID with level prices
  Future<Product?> getProductById(String id) async {
    final db = await _database.database;
    
    // Get the product
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (productMaps.isEmpty) return null;

    // Get level prices for this product
    final List<Map<String, dynamic>> levelPriceMaps = await db.query(
      ProductDatabase.productLevelPricesTable,
      where: 'product_id = ?',
      whereArgs: [id],
      orderBy: 'level_name ASC',
    );

    final levelPrices = levelPriceMaps
        .map((map) => _database.productLevelPriceFromMap(map))
        .toList();

    return _database.productFromMap(productMaps.first, levelPrices: levelPrices);
  }

  /// Update a product and its level prices
  Future<void> updateProduct(Product product) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Update the main product
      await txn.update(
        ProductDatabase.productsTable,
        _database.productToMap(product),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      // Delete existing level prices
      await txn.delete(
        ProductDatabase.productLevelPricesTable,
        where: 'product_id = ?',
        whereArgs: [product.id],
      );

      // Insert updated level prices
      for (final levelPrice in product.enhancedLevelPrices) {
        await txn.insert(
          ProductDatabase.productLevelPricesTable,
          _database.productLevelPriceToMap(levelPrice, product.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Delete a product and its level prices
  Future<void> deleteProduct(String id) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Delete level prices first (due to foreign key constraint)
      await txn.delete(
        ProductDatabase.productLevelPricesTable,
        where: 'product_id = ?',
        whereArgs: [id],
      );

      // Delete the product
      await txn.delete(
        ProductDatabase.productsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Get active products only
  Future<List<Product>> getActiveProducts() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    // Get level prices for all active products
    final productIds = productMaps.map((p) => p['id'] as String).toList();
    final levelPrices = await _getLevelPricesForProducts(productIds);

    return productMaps.map((productMap) {
      final productId = productMap['id'];
      final productLevelPrices = levelPrices[productId] ?? [];
      return _database.productFromMap(productMap, levelPrices: productLevelPrices);
    }).toList();
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      where: 'LOWER(category) = ?',
      whereArgs: [category.toLowerCase()],
      orderBy: 'name ASC',
    );

    final productIds = productMaps.map((p) => p['id'] as String).toList();
    final levelPrices = await _getLevelPricesForProducts(productIds);

    return productMaps.map((productMap) {
      final productId = productMap['id'];
      final productLevelPrices = levelPrices[productId] ?? [];
      return _database.productFromMap(productMap, levelPrices: productLevelPrices);
    }).toList();
  }

  /// Get addon products
  Future<List<Product>> getAddonProducts() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      where: 'is_addon = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    final productIds = productMaps.map((p) => p['id'] as String).toList();
    final levelPrices = await _getLevelPricesForProducts(productIds);

    return productMaps.map((productMap) {
      final productId = productMap['id'];
      final productLevelPrices = levelPrices[productId] ?? [];
      return _database.productFromMap(productMap, levelPrices: productLevelPrices);
    }).toList();
  }

  /// Get main differentiator products
  Future<List<Product>> getMainDifferentiatorProducts() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      where: 'is_main_differentiator = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    final productIds = productMaps.map((p) => p['id'] as String).toList();
    final levelPrices = await _getLevelPricesForProducts(productIds);

    return productMaps.map((productMap) {
      final productId = productMap['id'];
      final productLevelPrices = levelPrices[productId] ?? [];
      return _database.productFromMap(productMap, levelPrices: productLevelPrices);
    }).toList();
  }

  /// Get products with inventory tracking
  Future<List<Product>> getInventoryProducts() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      where: 'has_inventory = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    final productIds = productMaps.map((p) => p['id'] as String).toList();
    final levelPrices = await _getLevelPricesForProducts(productIds);

    return productMaps.map((productMap) {
      final productId = productMap['id'];
      final productLevelPrices = levelPrices[productId] ?? [];
      return _database.productFromMap(productMap, levelPrices: productLevelPrices);
    }).toList();
  }

  /// Search products by name, description, category, or SKU
  Future<List<Product>> searchProducts(String query) async {
    final db = await _database.database;
    final lowerQuery = '%${query.toLowerCase()}%';
    
    final List<Map<String, dynamic>> productMaps = await db.query(
      ProductDatabase.productsTable,
      where: '''
        LOWER(name) LIKE ? OR 
        LOWER(description) LIKE ? OR 
        LOWER(category) LIKE ? OR 
        LOWER(sku) LIKE ?
      ''',
      whereArgs: [lowerQuery, lowerQuery, lowerQuery, lowerQuery],
      orderBy: 'name ASC',
    );

    final productIds = productMaps.map((p) => p['id'] as String).toList();
    final levelPrices = await _getLevelPricesForProducts(productIds);

    return productMaps.map((productMap) {
      final productId = productMap['id'];
      final productLevelPrices = levelPrices[productId] ?? [];
      return _database.productFromMap(productMap, levelPrices: productLevelPrices);
    }).toList();
  }

  /// Get all unique categories
  Future<List<String>> getCategories() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT category 
      FROM ${ProductDatabase.productsTable} 
      WHERE category IS NOT NULL 
      ORDER BY category ASC
    ''');

    return maps.map((map) => map['category'] as String).toList();
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    final db = await _database.database;
    
    final totalProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${ProductDatabase.productsTable}')
    ) ?? 0;
    
    final activeProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${ProductDatabase.productsTable} WHERE is_active = 1')
    ) ?? 0;

    final addonProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${ProductDatabase.productsTable} WHERE is_addon = 1')
    ) ?? 0;

    final mainDifferentiatorProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${ProductDatabase.productsTable} WHERE is_main_differentiator = 1')
    ) ?? 0;

    final inventoryProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${ProductDatabase.productsTable} WHERE has_inventory = 1')
    ) ?? 0;
    
    // Get category distribution
    final categoryStats = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM ${ProductDatabase.productsTable} 
      WHERE category IS NOT NULL 
      GROUP BY category 
      ORDER BY count DESC
    ''');

    return {
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'addonProducts': addonProducts,
      'mainDifferentiatorProducts': mainDifferentiatorProducts,
      'inventoryProducts': inventoryProducts,
      'categoryDistribution': categoryStats,
    };
  }

  /// Batch insert products (useful for migration)
  Future<void> insertProducts(List<Product> products) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      for (final product in products) {
        // Insert the main product
        await txn.insert(
          ProductDatabase.productsTable,
          _database.productToMap(product),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert enhanced level prices
        for (final levelPrice in product.enhancedLevelPrices) {
          await txn.insert(
            ProductDatabase.productLevelPricesTable,
            _database.productLevelPriceToMap(levelPrice, product.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Clear all products (useful for testing)
  Future<void> clearAllProducts() async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      await txn.delete(ProductDatabase.productLevelPricesTable);
      await txn.delete(ProductDatabase.productsTable);
    });
  }

  // Helper Methods

  /// Get level prices for multiple products
  Future<Map<String, List<ProductLevelPrice>>> _getLevelPricesForProducts(List<String> productIds) async {
    if (productIds.isEmpty) return {};
    
    final db = await _database.database;
    final placeholders = productIds.map((_) => '?').join(',');
    
    final List<Map<String, dynamic>> levelPriceMaps = await db.rawQuery(
      'SELECT * FROM ${ProductDatabase.productLevelPricesTable} WHERE product_id IN ($placeholders) ORDER BY level_name ASC',
      productIds,
    );

    final Map<String, List<ProductLevelPrice>> result = {};
    for (final levelPriceMap in levelPriceMaps) {
      final productId = levelPriceMap['product_id'];
      final levelPrice = _database.productLevelPriceFromMap(levelPriceMap);
      
      result.putIfAbsent(productId, () => []);
      result[productId]!.add(levelPrice);
    }

    return result;
  }
}