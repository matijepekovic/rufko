import 'package:sqflite/sqflite.dart';

import '../database/inventory_database.dart';
import '../models/business/inventory_item.dart';
import '../models/business/inventory_transaction.dart';

/// Repository class for inventory-related database operations
/// Provides a clean interface for CRUD operations on inventory data
class InventoryRepository {
  final InventoryDatabase _database = InventoryDatabase();

  // INVENTORY ITEMS OPERATIONS

  /// Create a new inventory item
  Future<void> createInventoryItem(InventoryItem item) async {
    final db = await _database.database;
    await db.insert(
      InventoryDatabase.inventoryItemsTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all inventory items
  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      InventoryDatabase.inventoryItemsTable,
      orderBy: 'last_updated DESC',
    );

    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  /// Get inventory item by ID
  Future<InventoryItem?> getInventoryItemById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      InventoryDatabase.inventoryItemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  /// Get inventory item by product ID
  Future<InventoryItem?> getInventoryItemByProductId(String productId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      InventoryDatabase.inventoryItemsTable,
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  /// Update an inventory item
  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await _database.database;
    await db.update(
      InventoryDatabase.inventoryItemsTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete an inventory item
  Future<void> deleteInventoryItem(String id) async {
    final db = await _database.database;
    
    // Delete all transactions for this item first
    await db.delete(
      InventoryDatabase.inventoryTransactionsTable,
      where: 'inventory_item_id = ?',
      whereArgs: [id],
    );
    
    // Then delete the inventory item
    await db.delete(
      InventoryDatabase.inventoryItemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get inventory items with low stock
  Future<List<InventoryItem>> getLowStockItems() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM ${InventoryDatabase.inventoryItemsTable}
      WHERE minimum_stock IS NOT NULL 
      AND quantity <= minimum_stock
      ORDER BY quantity ASC
    ''');

    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  /// Get out of stock items
  Future<List<InventoryItem>> getOutOfStockItems() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      InventoryDatabase.inventoryItemsTable,
      where: 'quantity <= 0',
      orderBy: 'last_updated DESC',
    );

    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  /// Search inventory items by product name or location
  Future<List<InventoryItem>> searchInventoryItems(String query) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT i.* FROM ${InventoryDatabase.inventoryItemsTable} i
      WHERE i.location LIKE ? OR i.notes LIKE ?
      ORDER BY i.last_updated DESC
    ''', ['%$query%', '%$query%']);

    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  // INVENTORY TRANSACTIONS OPERATIONS

  /// Create a new inventory transaction
  Future<void> createInventoryTransaction(InventoryTransaction transaction) async {
    final db = await _database.database;
    await db.insert(
      InventoryDatabase.inventoryTransactionsTable,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all transactions for a specific inventory item
  Future<List<InventoryTransaction>> getTransactionsForItem(String inventoryItemId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      InventoryDatabase.inventoryTransactionsTable,
      where: 'inventory_item_id = ?',
      whereArgs: [inventoryItemId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return InventoryTransaction.fromMap(maps[i]);
    });
  }

  /// Get recent transactions (last N transactions)
  Future<List<InventoryTransaction>> getRecentTransactions({int limit = 50}) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      InventoryDatabase.inventoryTransactionsTable,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return InventoryTransaction.fromMap(maps[i]);
    });
  }

  /// Get transactions within a date range
  Future<List<InventoryTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      InventoryDatabase.inventoryTransactionsTable,
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return InventoryTransaction.fromMap(maps[i]);
    });
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    final db = await _database.database;
    await db.delete(
      InventoryDatabase.inventoryTransactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COMBINED OPERATIONS

  /// Add inventory with transaction recording
  Future<void> addInventoryWithTransaction({
    required String productId,
    required int quantityToAdd,
    required String reason,
    String? location,
    String? notes,
    int? minimumStock,
    String? userId,
  }) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Get or create inventory item using transaction
      final List<Map<String, dynamic>> maps = await txn.query(
        InventoryDatabase.inventoryItemsTable,
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      
      InventoryItem? inventoryItem;
      if (maps.isNotEmpty) {
        inventoryItem = InventoryItem.fromMap(maps.first);
      }
      
      int previousQuantity = 0;
      if (inventoryItem == null) {
        // Create new inventory item
        inventoryItem = InventoryItem(
          productId: productId,
          quantity: quantityToAdd,
          minimumStock: minimumStock,
          location: location,
          notes: notes,
        );
        await txn.insert(
          InventoryDatabase.inventoryItemsTable,
          inventoryItem.toMap(),
        );
      } else {
        // Update existing inventory item
        previousQuantity = inventoryItem.quantity;
        inventoryItem.updateQuantity(inventoryItem.quantity + quantityToAdd);
        if (location != null) inventoryItem.location = location;
        if (notes != null) inventoryItem.notes = notes;
        if (minimumStock != null) inventoryItem.minimumStock = minimumStock;
        
        await txn.update(
          InventoryDatabase.inventoryItemsTable,
          inventoryItem.toMap(),
          where: 'id = ?',
          whereArgs: [inventoryItem.id],
        );
      }

      // Create transaction record
      final transaction = InventoryTransaction.add(
        inventoryItemId: inventoryItem.id,
        quantityAdded: quantityToAdd,
        previousQuantity: previousQuantity,
        reason: reason,
        userId: userId,
      );

      await txn.insert(
        InventoryDatabase.inventoryTransactionsTable,
        transaction.toMap(),
      );
    });
  }

  /// Adjust inventory with transaction recording
  Future<void> adjustInventoryWithTransaction({
    required String inventoryItemId,
    required int newQuantity,
    required String reason,
    String? userId,
  }) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Get current inventory item using transaction
      final List<Map<String, dynamic>> maps = await txn.query(
        InventoryDatabase.inventoryItemsTable,
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );
      
      if (maps.isEmpty) {
        throw Exception('Inventory item not found');
      }
      
      final inventoryItem = InventoryItem.fromMap(maps.first);

      final previousQuantity = inventoryItem.quantity;
      inventoryItem.updateQuantity(newQuantity);

      // Update inventory item
      await txn.update(
        InventoryDatabase.inventoryItemsTable,
        inventoryItem.toMap(),
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );

      // Create transaction record
      final transaction = InventoryTransaction.adjust(
        inventoryItemId: inventoryItemId,
        previousQuantity: previousQuantity,
        newQuantity: newQuantity,
        reason: reason,
        userId: userId,
      );

      await txn.insert(
        InventoryDatabase.inventoryTransactionsTable,
        transaction.toMap(),
      );
    });
  }

  /// Get inventory summary statistics
  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await _database.database;
    
    final totalItems = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${InventoryDatabase.inventoryItemsTable}')
    ) ?? 0;
    
    final lowStockItems = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*) FROM ${InventoryDatabase.inventoryItemsTable}
        WHERE minimum_stock IS NOT NULL AND quantity <= minimum_stock
      ''')
    ) ?? 0;
    
    final outOfStockItems = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*) FROM ${InventoryDatabase.inventoryItemsTable}
        WHERE quantity <= 0
      ''')
    ) ?? 0;

    final totalTransactions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${InventoryDatabase.inventoryTransactionsTable}')
    ) ?? 0;

    return {
      'totalItems': totalItems,
      'lowStockItems': lowStockItems,
      'outOfStockItems': outOfStockItems,
      'totalTransactions': totalTransactions,
    };
  }
}