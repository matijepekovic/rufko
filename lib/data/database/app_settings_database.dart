import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../models/settings/app_settings.dart';

/// SQLite database service for AppSettings
/// Handles singleton settings storage and list field management
class AppSettingsDatabase {
  static final AppSettingsDatabase _instance = AppSettingsDatabase._internal();
  factory AppSettingsDatabase() => _instance;
  AppSettingsDatabase._internal();

  static Database? _database;
  static const String databaseName = 'app_settings.db';
  static const int databaseVersion = 2;

  // Table names
  static const String settingsTable = 'app_settings';
  static const String categoriesTable = 'product_categories';
  static const String unitsTable = 'product_units';
  static const String levelNamesTable = 'quote_level_names';
  static const String discountTypesTable = 'discount_types';
  static const String jobTypesTable = 'job_types';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      path = 'app_settings.db';
    } else {
      // Mobile platforms
      final dbPath = await getDatabasesPath();
      path = '$dbPath/$databaseName';
    }

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main settings table (singleton)
    await db.execute('''
      CREATE TABLE $settingsTable (
        id TEXT PRIMARY KEY,
        default_unit TEXT NOT NULL,
        tax_rate REAL NOT NULL DEFAULT 0.0,
        company_name TEXT,
        company_address TEXT,
        company_phone TEXT,
        company_email TEXT,
        company_logo_path TEXT,
        allow_product_discount_toggle INTEGER NOT NULL DEFAULT 1,
        default_discount_limit REAL NOT NULL DEFAULT 25.0,
        show_calculator_quick_chips INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Product categories table
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        settings_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (settings_id) REFERENCES $settingsTable (id) ON DELETE CASCADE,
        UNIQUE(settings_id, category_name)
      )
    ''');

    // Product units table
    await db.execute('''
      CREATE TABLE $unitsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        settings_id TEXT NOT NULL,
        unit_name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (settings_id) REFERENCES $settingsTable (id) ON DELETE CASCADE,
        UNIQUE(settings_id, unit_name)
      )
    ''');

    // Quote level names table
    await db.execute('''
      CREATE TABLE $levelNamesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        settings_id TEXT NOT NULL,
        level_name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (settings_id) REFERENCES $settingsTable (id) ON DELETE CASCADE,
        UNIQUE(settings_id, level_name)
      )
    ''');

    // Discount types table
    await db.execute('''
      CREATE TABLE $discountTypesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        settings_id TEXT NOT NULL,
        discount_type TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (settings_id) REFERENCES $settingsTable (id) ON DELETE CASCADE,
        UNIQUE(settings_id, discount_type)
      )
    ''');

    // Job types table
    await db.execute('''
      CREATE TABLE $jobTypesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        settings_id TEXT NOT NULL,
        job_type TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (settings_id) REFERENCES $settingsTable (id) ON DELETE CASCADE,
        UNIQUE(settings_id, job_type)
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_categories_settings ON $categoriesTable (settings_id)');
    await db.execute('CREATE INDEX idx_units_settings ON $unitsTable (settings_id)');
    await db.execute('CREATE INDEX idx_level_names_settings ON $levelNamesTable (settings_id)');
    await db.execute('CREATE INDEX idx_discount_types_settings ON $discountTypesTable (settings_id)');
    await db.execute('CREATE INDEX idx_job_types_settings ON $jobTypesTable (settings_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Add job types table in version 2
      await db.execute('''
        CREATE TABLE $jobTypesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          settings_id TEXT NOT NULL,
          job_type TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (settings_id) REFERENCES $settingsTable (id) ON DELETE CASCADE,
          UNIQUE(settings_id, job_type)
        )
      ''');
      await db.execute('CREATE INDEX idx_job_types_settings ON $jobTypesTable (settings_id)');
    }
  }

  /// Insert AppSettings with all related list data
  Future<void> insertAppSettings(AppSettings settings) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Insert main settings record
      await txn.insert(
        settingsTable,
        {
          'id': settings.id,
          'default_unit': settings.defaultUnit,
          'tax_rate': settings.taxRate,
          'company_name': settings.companyName,
          'company_address': settings.companyAddress,
          'company_phone': settings.companyPhone,
          'company_email': settings.companyEmail,
          'company_logo_path': settings.companyLogoPath,
          'allow_product_discount_toggle': settings.allowProductDiscountToggle ? 1 : 0,
          'default_discount_limit': settings.defaultDiscountLimit,
          'show_calculator_quick_chips': settings.showCalculatorQuickChips ? 1 : 0,
          'updated_at': settings.updatedAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert product categories
      for (int i = 0; i < settings.productCategories.length; i++) {
        await txn.insert(
          categoriesTable,
          {
            'settings_id': settings.id,
            'category_name': settings.productCategories[i],
            'sort_order': i,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert product units
      for (int i = 0; i < settings.productUnits.length; i++) {
        await txn.insert(
          unitsTable,
          {
            'settings_id': settings.id,
            'unit_name': settings.productUnits[i],
            'sort_order': i,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert quote level names
      for (int i = 0; i < settings.defaultQuoteLevelNames.length; i++) {
        await txn.insert(
          levelNamesTable,
          {
            'settings_id': settings.id,
            'level_name': settings.defaultQuoteLevelNames[i],
            'sort_order': i,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert discount types
      for (int i = 0; i < settings.discountTypes.length; i++) {
        await txn.insert(
          discountTypesTable,
          {
            'settings_id': settings.id,
            'discount_type': settings.discountTypes[i],
            'sort_order': i,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert job types
      for (int i = 0; i < settings.jobTypes.length; i++) {
        await txn.insert(
          jobTypesTable,
          {
            'settings_id': settings.id,
            'job_type': settings.jobTypes[i],
            'sort_order': i,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get AppSettings by ID (usually singleton)
  Future<AppSettings?> getAppSettings(String settingsId) async {
    final db = await database;
    
    // Get main settings record
    final settingsResult = await db.query(
      settingsTable,
      where: 'id = ?',
      whereArgs: [settingsId],
      limit: 1,
    );
    
    if (settingsResult.isEmpty) return null;
    
    final settingsData = settingsResult.first;
    
    // Get product categories (ordered)
    final categoriesResult = await db.query(
      categoriesTable,
      where: 'settings_id = ?',
      whereArgs: [settingsId],
      orderBy: 'sort_order ASC',
    );
    
    // Get product units (ordered)
    final unitsResult = await db.query(
      unitsTable,
      where: 'settings_id = ?',
      whereArgs: [settingsId],
      orderBy: 'sort_order ASC',
    );
    
    // Get quote level names (ordered)
    final levelNamesResult = await db.query(
      levelNamesTable,
      where: 'settings_id = ?',
      whereArgs: [settingsId],
      orderBy: 'sort_order ASC',
    );
    
    // Get discount types (ordered)
    final discountTypesResult = await db.query(
      discountTypesTable,
      where: 'settings_id = ?',
      whereArgs: [settingsId],
      orderBy: 'sort_order ASC',
    );
    
    // Get job types (ordered)
    final jobTypesResult = await db.query(
      jobTypesTable,
      where: 'settings_id = ?',
      whereArgs: [settingsId],
      orderBy: 'sort_order ASC',
    );
    
    // Build AppSettings object
    return AppSettings(
      id: settingsData['id'] as String,
      defaultUnit: settingsData['default_unit'] as String,
      taxRate: (settingsData['tax_rate'] as num).toDouble(),
      companyName: settingsData['company_name'] as String?,
      companyAddress: settingsData['company_address'] as String?,
      companyPhone: settingsData['company_phone'] as String?,
      companyEmail: settingsData['company_email'] as String?,
      companyLogoPath: settingsData['company_logo_path'] as String?,
      allowProductDiscountToggle: (settingsData['allow_product_discount_toggle'] as int) == 1,
      defaultDiscountLimit: (settingsData['default_discount_limit'] as num).toDouble(),
      showCalculatorQuickChips: (settingsData['show_calculator_quick_chips'] as int) == 1,
      productCategories: categoriesResult.map((row) => row['category_name'] as String).toList(),
      productUnits: unitsResult.map((row) => row['unit_name'] as String).toList(),
      defaultQuoteLevelNames: levelNamesResult.map((row) => row['level_name'] as String).toList(),
      discountTypes: discountTypesResult.map((row) => row['discount_type'] as String).toList(),
      jobTypes: jobTypesResult.map((row) => row['job_type'] as String).toList(),
      updatedAt: DateTime.parse(settingsData['updated_at'] as String),
    );
  }

  /// Get singleton AppSettings (first/only record)
  Future<AppSettings?> getSingletonSettings() async {
    final db = await database;
    
    final result = await db.query(
      settingsTable,
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    final settingsId = result.first['id'] as String;
    return await getAppSettings(settingsId);
  }

  /// Update AppSettings (replaces all data)
  Future<void> updateAppSettings(AppSettings settings) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Update main settings record
      await txn.update(
        settingsTable,
        {
          'default_unit': settings.defaultUnit,
          'tax_rate': settings.taxRate,
          'company_name': settings.companyName,
          'company_address': settings.companyAddress,
          'company_phone': settings.companyPhone,
          'company_email': settings.companyEmail,
          'company_logo_path': settings.companyLogoPath,
          'allow_product_discount_toggle': settings.allowProductDiscountToggle ? 1 : 0,
          'default_discount_limit': settings.defaultDiscountLimit,
          'show_calculator_quick_chips': settings.showCalculatorQuickChips ? 1 : 0,
          'updated_at': settings.updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [settings.id],
      );

      // Clear and re-insert all list data
      await txn.delete(categoriesTable, where: 'settings_id = ?', whereArgs: [settings.id]);
      await txn.delete(unitsTable, where: 'settings_id = ?', whereArgs: [settings.id]);
      await txn.delete(levelNamesTable, where: 'settings_id = ?', whereArgs: [settings.id]);
      await txn.delete(discountTypesTable, where: 'settings_id = ?', whereArgs: [settings.id]);
      await txn.delete(jobTypesTable, where: 'settings_id = ?', whereArgs: [settings.id]);

      // Re-insert categories
      for (int i = 0; i < settings.productCategories.length; i++) {
        await txn.insert(categoriesTable, {
          'settings_id': settings.id,
          'category_name': settings.productCategories[i],
          'sort_order': i,
        });
      }

      // Re-insert units
      for (int i = 0; i < settings.productUnits.length; i++) {
        await txn.insert(unitsTable, {
          'settings_id': settings.id,
          'unit_name': settings.productUnits[i],
          'sort_order': i,
        });
      }

      // Re-insert level names
      for (int i = 0; i < settings.defaultQuoteLevelNames.length; i++) {
        await txn.insert(levelNamesTable, {
          'settings_id': settings.id,
          'level_name': settings.defaultQuoteLevelNames[i],
          'sort_order': i,
        });
      }

      // Re-insert discount types
      for (int i = 0; i < settings.discountTypes.length; i++) {
        await txn.insert(discountTypesTable, {
          'settings_id': settings.id,
          'discount_type': settings.discountTypes[i],
          'sort_order': i,
        });
      }

      // Re-insert job types
      for (int i = 0; i < settings.jobTypes.length; i++) {
        await txn.insert(jobTypesTable, {
          'settings_id': settings.id,
          'job_type': settings.jobTypes[i],
          'sort_order': i,
        });
      }
    });
  }

  /// Delete all AppSettings data
  Future<void> clearAllSettings() async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(jobTypesTable);
      await txn.delete(discountTypesTable);
      await txn.delete(levelNamesTable);
      await txn.delete(unitsTable);
      await txn.delete(categoriesTable);
      await txn.delete(settingsTable);
    });
  }

  /// Check if settings exist
  Future<bool> hasSettings() async {
    final db = await database;
    final result = await db.query(settingsTable, limit: 1);
    return result.isNotEmpty;
  }

  /// Get settings statistics
  Future<Map<String, dynamic>> getSettingsStatistics() async {
    final db = await database;
    
    final settingsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $settingsTable')
    ) ?? 0;
    
    final categoriesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $categoriesTable')
    ) ?? 0;
    
    final unitsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $unitsTable')
    ) ?? 0;
    
    final levelNamesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $levelNamesTable')
    ) ?? 0;
    
    final discountTypesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $discountTypesTable')
    ) ?? 0;
    
    final jobTypesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $jobTypesTable')
    ) ?? 0;
    
    return {
      'settings_count': settingsCount,
      'categories_count': categoriesCount,
      'units_count': unitsCount,
      'level_names_count': levelNamesCount,
      'discount_types_count': discountTypesCount,
      'job_types_count': jobTypesCount,
      'has_singleton': settingsCount > 0,
    };
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}