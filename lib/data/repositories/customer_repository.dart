import 'package:sqflite/sqflite.dart';

import '../database/customer_database.dart';
import '../models/business/customer.dart';

/// Repository class for customer-related database operations
/// Provides a clean interface for CRUD operations on customer data
class CustomerRepository {
  final CustomerDatabase _database = CustomerDatabase();

  // CUSTOMER OPERATIONS

  /// Create a new customer
  Future<void> createCustomer(Customer customer) async {
    final db = await _database.database;
    await db.insert(
      CustomerDatabase.customersTable,
      _database.customerToMap(customer),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CustomerDatabase.customersTable,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return _database.customerFromMap(maps[i]);
    });
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CustomerDatabase.customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _database.customerFromMap(maps.first);
    }
    return null;
  }

  /// Update a customer
  Future<void> updateCustomer(Customer customer) async {
    final db = await _database.database;
    await db.update(
      CustomerDatabase.customersTable,
      _database.customerToMap(customer),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete a customer
  Future<void> deleteCustomer(String id) async {
    final db = await _database.database;
    await db.delete(
      CustomerDatabase.customersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search customers by name, email, phone, or address
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _database.database;
    final lowerQuery = '%${query.toLowerCase()}%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      CustomerDatabase.customersTable,
      where: '''
        LOWER(name) LIKE ? OR 
        LOWER(email) LIKE ? OR 
        phone LIKE ? OR 
        LOWER(street_address) LIKE ? OR 
        LOWER(city) LIKE ?
      ''',
      whereArgs: [lowerQuery, lowerQuery, lowerQuery, lowerQuery, lowerQuery],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return _database.customerFromMap(maps[i]);
    });
  }

  /// Get customers by city
  Future<List<Customer>> getCustomersByCity(String city) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CustomerDatabase.customersTable,
      where: 'LOWER(city) = ?',
      whereArgs: [city.toLowerCase()],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return _database.customerFromMap(maps[i]);
    });
  }

  /// Get customers by state
  Future<List<Customer>> getCustomersByState(String stateAbbreviation) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CustomerDatabase.customersTable,
      where: 'LOWER(state_abbreviation) = ?',
      whereArgs: [stateAbbreviation.toLowerCase()],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return _database.customerFromMap(maps[i]);
    });
  }

  /// Get customers created within a date range
  Future<List<Customer>> getCustomersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      CustomerDatabase.customersTable,
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return _database.customerFromMap(maps[i]);
    });
  }

  /// Get customers with due follow-ups (recent customers for follow-up)
  Future<List<Customer>> getCustomersForFollowUp() async {
    final db = await _database.database;
    // Get customers created in the last 30 days for potential follow-up
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final List<Map<String, dynamic>> maps = await db.query(
      CustomerDatabase.customersTable,
      where: 'created_at >= ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return _database.customerFromMap(maps[i]);
    });
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics() async {
    final db = await _database.database;
    
    final totalCustomers = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${CustomerDatabase.customersTable}')
    ) ?? 0;
    
    // Get customers by state count
    final stateStats = await db.rawQuery('''
      SELECT state_abbreviation, COUNT(*) as count 
      FROM ${CustomerDatabase.customersTable} 
      WHERE state_abbreviation IS NOT NULL 
      GROUP BY state_abbreviation 
      ORDER BY count DESC
    ''');
    
    // Get customers by city count
    final cityStats = await db.rawQuery('''
      SELECT city, COUNT(*) as count 
      FROM ${CustomerDatabase.customersTable} 
      WHERE city IS NOT NULL 
      GROUP BY city 
      ORDER BY count DESC 
      LIMIT 10
    ''');
    
    // Get recent customer count (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentCustomers = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*) FROM ${CustomerDatabase.customersTable} 
        WHERE created_at >= ?
      ''', [thirtyDaysAgo.toIso8601String()])
    ) ?? 0;

    return {
      'totalCustomers': totalCustomers,
      'recentCustomers': recentCustomers,
      'stateDistribution': stateStats,
      'topCities': cityStats,
    };
  }

  /// Batch insert customers (useful for migration)
  Future<void> insertCustomers(List<Customer> customers) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      for (final customer in customers) {
        await txn.insert(
          CustomerDatabase.customersTable,
          _database.customerToMap(customer),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Clear all customers (useful for testing)
  Future<void> clearAllCustomers() async {
    final db = await _database.database;
    await db.delete(CustomerDatabase.customersTable);
  }
}