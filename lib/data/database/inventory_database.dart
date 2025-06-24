import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';


/// SQLite database manager for inventory-related data
/// Handles database creation, migrations, and provides connection management
class InventoryDatabase {
  static const String _databaseName = 'rufko_inventory.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String inventoryItemsTable = 'inventory_items';
  static const String inventoryTransactionsTable = 'inventory_transactions';

  // Singleton pattern
  static final InventoryDatabase _instance = InventoryDatabase._internal();
  factory InventoryDatabase() => _instance;
  InventoryDatabase._internal();

  static Database? _database;

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
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
    // Create inventory_items table
    await db.execute('''
      CREATE TABLE $inventoryItemsTable (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        minimum_stock INTEGER,
        location TEXT,
        last_updated TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Create inventory_transactions table
    await db.execute('''
      CREATE TABLE $inventoryTransactionsTable (
        id TEXT PRIMARY KEY,
        inventory_item_id TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previous_quantity INTEGER NOT NULL,
        new_quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        user_id TEXT,
        FOREIGN KEY (inventory_item_id) REFERENCES $inventoryItemsTable (id)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_inventory_items_product_id ON $inventoryItemsTable (product_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_inventory_transactions_item_id ON $inventoryTransactionsTable (inventory_item_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_inventory_transactions_timestamp ON $inventoryTransactionsTable (timestamp)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE $inventoryItemsTable ADD COLUMN new_field TEXT');
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
    if (await File(path).exists()) {
      await File(path).delete();
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
    final inventoryItemsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $inventoryItemsTable')
    ) ?? 0;
    
    final transactionsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $inventoryTransactionsTable')
    ) ?? 0;

    return {
      'version': version,
      'path': path,
      'inventoryItemsCount': inventoryItemsCount,
      'transactionsCount': transactionsCount,
    };
  }
}