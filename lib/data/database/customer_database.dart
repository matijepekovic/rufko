import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import '../models/business/customer.dart';

/// SQLite database manager for customer-related data
/// Handles database creation, migrations, and provides connection management
class CustomerDatabase {
  static const String _databaseName = 'rufko_customers.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String customersTable = 'customers';

  // Singleton pattern
  static final CustomerDatabase _instance = CustomerDatabase._internal();
  factory CustomerDatabase() => _instance;
  CustomerDatabase._internal();

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
    // Create customers table
    await db.execute('''
      CREATE TABLE $customersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notes TEXT,
        communication_history TEXT, -- JSON array as text
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        street_address TEXT,
        city TEXT,
        state_abbreviation TEXT,
        zip_code TEXT,
        inspection_data TEXT -- JSON object as text
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_customers_name ON $customersTable (name)
    ''');

    await db.execute('''
      CREATE INDEX idx_customers_email ON $customersTable (email)
    ''');

    await db.execute('''
      CREATE INDEX idx_customers_phone ON $customersTable (phone)
    ''');

    await db.execute('''
      CREATE INDEX idx_customers_city ON $customersTable (city)
    ''');

    await db.execute('''
      CREATE INDEX idx_customers_created_at ON $customersTable (created_at)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE $customersTable ADD COLUMN new_field TEXT');
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

  /// Convert Customer to SQLite map
  Map<String, dynamic> customerToMap(Customer customer) {
    return {
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'email': customer.email,
      'notes': customer.notes,
      'communication_history': jsonEncode(customer.communicationHistory),
      'created_at': customer.createdAt.toIso8601String(),
      'updated_at': customer.updatedAt.toIso8601String(),
      'street_address': customer.streetAddress,
      'city': customer.city,
      'state_abbreviation': customer.stateAbbreviation,
      'zip_code': customer.zipCode,
      'inspection_data': jsonEncode(customer.inspectionData),
    };
  }

  /// Convert SQLite map to Customer
  Customer customerFromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? 'Unknown Customer',
      phone: map['phone'],
      email: map['email'],
      notes: map['notes'],
      communicationHistory: map['communication_history'] != null 
          ? List<String>.from(jsonDecode(map['communication_history']))
          : [],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
      streetAddress: map['street_address'],
      city: map['city'],
      stateAbbreviation: map['state_abbreviation'],
      zipCode: map['zip_code'],
      inspectionData: map['inspection_data'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['inspection_data']))
          : {},
    );
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
    final customersCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $customersTable')
    ) ?? 0;

    return {
      'version': version,
      'path': path,
      'customersCount': customersCount,
    };
  }
}