import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import '../models/business/product.dart';

/// SQLite database manager for product-related data
/// Handles database creation, migrations, and provides connection management
class ProductDatabase {
  static const String _databaseName = 'rufko_products.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String productsTable = 'products';
  static const String productLevelPricesTable = 'product_level_prices';

  // Singleton pattern
  static final ProductDatabase _instance = ProductDatabase._internal();
  factory ProductDatabase() => _instance;
  ProductDatabase._internal();

  static Database? _database;

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    // Initialize database factory for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      databaseFactory = databaseFactoryFfi;
    }
    
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE $productsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        unit_price REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'each',
        category TEXT NOT NULL DEFAULT 'Materials',
        sku TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        level_prices TEXT, -- JSON map for backward compatibility
        is_addon INTEGER NOT NULL DEFAULT 0,
        is_discountable INTEGER NOT NULL DEFAULT 1,
        max_levels INTEGER NOT NULL DEFAULT 3,
        notes TEXT,
        is_main_differentiator INTEGER NOT NULL DEFAULT 0,
        enable_level_pricing INTEGER NOT NULL DEFAULT 0,
        pricing_type TEXT NOT NULL DEFAULT 'simple',
        has_inventory INTEGER NOT NULL DEFAULT 0,
        photo_path TEXT
      )
    ''');

    // Create product level prices table (normalized table for enhanced level prices)
    await db.execute('''
      CREATE TABLE $productLevelPricesTable (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        level_id TEXT NOT NULL,
        level_name TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES $productsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_products_name ON $productsTable (name)
    ''');

    await db.execute('''
      CREATE INDEX idx_products_category ON $productsTable (category)
    ''');

    await db.execute('''
      CREATE INDEX idx_products_active ON $productsTable (is_active)
    ''');

    await db.execute('''
      CREATE INDEX idx_products_addon ON $productsTable (is_addon)
    ''');

    await db.execute('''
      CREATE INDEX idx_products_main_diff ON $productsTable (is_main_differentiator)
    ''');

    await db.execute('''
      CREATE INDEX idx_products_has_inventory ON $productsTable (has_inventory)
    ''');

    await db.execute('''
      CREATE INDEX idx_product_level_prices_product_id ON $productLevelPricesTable (product_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_product_level_prices_level_id ON $productLevelPricesTable (level_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_product_level_prices_active ON $productLevelPricesTable (is_active)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE $productsTable ADD COLUMN new_field TEXT');
    }
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database (useful for testing)
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    
    await close();
    await databaseFactory.deleteDatabase(path);
  }

  /// Convert Product to SQLite map
  Map<String, dynamic> productToMap(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'unit_price': product.unitPrice,
      'unit': product.unit,
      'category': product.category,
      'sku': product.sku,
      'is_active': product.isActive ? 1 : 0,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt.toIso8601String(),
      'level_prices': jsonEncode(product.levelPrices),
      'is_addon': product.isAddon ? 1 : 0,
      'is_discountable': product.isDiscountable ? 1 : 0,
      'max_levels': product.maxLevels,
      'notes': product.notes,
      'is_main_differentiator': product.isMainDifferentiator ? 1 : 0,
      'enable_level_pricing': product.enableLevelPricing ? 1 : 0,
      'pricing_type': product.pricingType.toString().split('.').last,
      'has_inventory': product.hasInventory ? 1 : 0,
      'photo_path': product.photoPath,
    };
  }

  /// Convert ProductLevelPrice to SQLite map
  Map<String, dynamic> productLevelPriceToMap(ProductLevelPrice levelPrice, String productId) {
    return {
      'id': '${productId}_${levelPrice.levelId}',
      'product_id': productId,
      'level_id': levelPrice.levelId,
      'level_name': levelPrice.levelName,
      'price': levelPrice.price,
      'description': levelPrice.description,
      'is_active': levelPrice.isActive ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert SQLite map to Product
  Product productFromMap(Map<String, dynamic> map, {List<ProductLevelPrice>? levelPrices}) {
    return Product(
      id: map['id'],
      name: map['name'] ?? 'Unknown Product',
      description: map['description'],
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'each',
      category: map['category'] ?? 'Materials',
      sku: map['sku'],
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
      levelPrices: map['level_prices'] != null 
          ? Map<String, double>.from(jsonDecode(map['level_prices']))
          : {},
      isAddon: (map['is_addon'] ?? 0) == 1,
      isDiscountable: (map['is_discountable'] ?? 1) == 1,
      enhancedLevelPrices: levelPrices ?? [],
      maxLevels: map['max_levels'] ?? 3,
      notes: map['notes'],
      isMainDifferentiator: (map['is_main_differentiator'] ?? 0) == 1,
      enableLevelPricing: (map['enable_level_pricing'] ?? 0) == 1,
      pricingType: _parsePricingType(map['pricing_type']),
      hasInventory: (map['has_inventory'] ?? 0) == 1,
      photoPath: map['photo_path'],
    );
  }

  /// Convert SQLite map to ProductLevelPrice
  ProductLevelPrice productLevelPriceFromMap(Map<String, dynamic> map) {
    return ProductLevelPrice(
      levelId: map['level_id'] ?? '',
      levelName: map['level_name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      description: map['description'],
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  /// Parse pricing type from string
  ProductPricingType _parsePricingType(String? typeString) {
    switch (typeString) {
      case 'mainDifferentiator':
        return ProductPricingType.mainDifferentiator;
      case 'subLeveled':
        return ProductPricingType.subLeveled;
      case 'simple':
      default:
        return ProductPricingType.simple;
    }
  }

  /// Execute a raw SQL query (for debugging/maintenance)
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute a raw SQL insert/update/delete (for debugging/maintenance)
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  /// Get database info for debugging
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final version = await db.getVersion();
    final path = db.path;
    
    // Get table row counts
    final productsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $productsTable')
    ) ?? 0;

    final levelPricesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $productLevelPricesTable')
    ) ?? 0;

    return {
      'version': version,
      'path': path,
      'productsCount': productsCount,
      'levelPricesCount': levelPricesCount,
    };
  }
}