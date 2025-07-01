import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../models/settings/custom_app_data.dart';

/// SQLite database service for CustomAppDataField
/// Handles dynamic field storage and management
class CustomFieldDatabase {
  static final CustomFieldDatabase _instance = CustomFieldDatabase._internal();
  factory CustomFieldDatabase() => _instance;
  CustomFieldDatabase._internal();

  static Database? _database;
  static const String databaseName = 'custom_fields.db';
  static const int databaseVersion = 1;

  // Table names
  static const String fieldsTable = 'custom_fields';
  static const String dropdownOptionsTable = 'field_dropdown_options';

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
      path = 'custom_fields.db';
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
    // Main custom fields table
    await db.execute('''
      CREATE TABLE $fieldsTable (
        id TEXT PRIMARY KEY,
        field_name TEXT NOT NULL,
        display_name TEXT NOT NULL,
        field_type TEXT NOT NULL DEFAULT 'text',
        current_value TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT 'custom',
        is_required INTEGER NOT NULL DEFAULT 0,
        placeholder TEXT,
        description TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Dropdown options table (for dropdown field types)
    await db.execute('''
      CREATE TABLE $dropdownOptionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        field_id TEXT NOT NULL,
        option_value TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (field_id) REFERENCES $fieldsTable (id) ON DELETE CASCADE,
        UNIQUE(field_id, option_value)
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_fields_category ON $fieldsTable (category)');
    await db.execute('CREATE INDEX idx_fields_field_name ON $fieldsTable (field_name)');
    await db.execute('CREATE INDEX idx_fields_sort_order ON $fieldsTable (sort_order)');
    await db.execute('CREATE INDEX idx_dropdown_field_id ON $dropdownOptionsTable (field_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Example: Add new columns in version 2
      // await db.execute('ALTER TABLE $fieldsTable ADD COLUMN new_field TEXT');
    }
  }

  /// Insert a custom field with dropdown options
  Future<void> insertCustomField(CustomAppDataField field) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Insert main field record
      await txn.insert(
        fieldsTable,
        {
          'id': field.id,
          'field_name': field.fieldName,
          'display_name': field.displayName,
          'field_type': field.fieldType,
          'current_value': field.currentValue,
          'category': field.category,
          'is_required': field.isRequired ? 1 : 0,
          'placeholder': field.placeholder,
          'description': field.description,
          'sort_order': field.sortOrder,
          'created_at': field.createdAt.toIso8601String(),
          'updated_at': field.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert dropdown options if present
      if (field.dropdownOptions != null && field.dropdownOptions!.isNotEmpty) {
        for (int i = 0; i < field.dropdownOptions!.length; i++) {
          await txn.insert(
            dropdownOptionsTable,
            {
              'field_id': field.id,
              'option_value': field.dropdownOptions![i],
              'sort_order': i,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Insert multiple custom fields
  Future<void> insertCustomFields(List<CustomAppDataField> fields) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (final field in fields) {
        // Insert main field record
        await txn.insert(
          fieldsTable,
          {
            'id': field.id,
            'field_name': field.fieldName,
            'display_name': field.displayName,
            'field_type': field.fieldType,
            'current_value': field.currentValue,
            'category': field.category,
            'is_required': field.isRequired ? 1 : 0,
            'placeholder': field.placeholder,
            'description': field.description,
            'sort_order': field.sortOrder,
            'created_at': field.createdAt.toIso8601String(),
            'updated_at': field.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert dropdown options if present
        if (field.dropdownOptions != null && field.dropdownOptions!.isNotEmpty) {
          for (int i = 0; i < field.dropdownOptions!.length; i++) {
            await txn.insert(
              dropdownOptionsTable,
              {
                'field_id': field.id,
                'option_value': field.dropdownOptions![i],
                'sort_order': i,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    });
  }

  /// Get custom field by ID
  Future<CustomAppDataField?> getCustomFieldById(String fieldId) async {
    final db = await database;
    
    // Get main field record
    final fieldResult = await db.query(
      fieldsTable,
      where: 'id = ?',
      whereArgs: [fieldId],
      limit: 1,
    );
    
    if (fieldResult.isEmpty) return null;
    
    final fieldData = fieldResult.first;
    
    // Get dropdown options
    final optionsResult = await db.query(
      dropdownOptionsTable,
      where: 'field_id = ?',
      whereArgs: [fieldId],
      orderBy: 'sort_order ASC',
    );
    
    final dropdownOptions = optionsResult.isNotEmpty
        ? optionsResult.map((row) => row['option_value'] as String).toList()
        : null;
    
    return CustomAppDataField(
      id: fieldData['id'] as String,
      fieldName: fieldData['field_name'] as String,
      displayName: fieldData['display_name'] as String,
      fieldType: fieldData['field_type'] as String,
      currentValue: fieldData['current_value'] as String,
      category: fieldData['category'] as String,
      isRequired: (fieldData['is_required'] as int) == 1,
      placeholder: fieldData['placeholder'] as String?,
      description: fieldData['description'] as String?,
      sortOrder: fieldData['sort_order'] as int,
      dropdownOptions: dropdownOptions,
      createdAt: DateTime.parse(fieldData['created_at'] as String),
      updatedAt: DateTime.parse(fieldData['updated_at'] as String),
    );
  }

  /// Get all custom fields
  Future<List<CustomAppDataField>> getAllCustomFields() async {
    final db = await database;
    
    final fieldResults = await db.query(
      fieldsTable,
      orderBy: 'sort_order ASC, display_name ASC',
    );
    
    final fields = <CustomAppDataField>[];
    
    for (final fieldData in fieldResults) {
      final fieldId = fieldData['id'] as String;
      
      // Get dropdown options for this field
      final optionsResult = await db.query(
        dropdownOptionsTable,
        where: 'field_id = ?',
        whereArgs: [fieldId],
        orderBy: 'sort_order ASC',
      );
      
      final dropdownOptions = optionsResult.isNotEmpty
          ? optionsResult.map((row) => row['option_value'] as String).toList()
          : null;
      
      fields.add(CustomAppDataField(
        id: fieldData['id'] as String,
        fieldName: fieldData['field_name'] as String,
        displayName: fieldData['display_name'] as String,
        fieldType: fieldData['field_type'] as String,
        currentValue: fieldData['current_value'] as String,
        category: fieldData['category'] as String,
        isRequired: (fieldData['is_required'] as int) == 1,
        placeholder: fieldData['placeholder'] as String?,
        description: fieldData['description'] as String?,
        sortOrder: fieldData['sort_order'] as int,
        dropdownOptions: dropdownOptions,
        createdAt: DateTime.parse(fieldData['created_at'] as String),
        updatedAt: DateTime.parse(fieldData['updated_at'] as String),
      ));
    }
    
    return fields;
  }

  /// Get custom fields by category
  Future<List<CustomAppDataField>> getCustomFieldsByCategory(String category) async {
    final db = await database;
    
    final fieldResults = await db.query(
      fieldsTable,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'sort_order ASC, display_name ASC',
    );
    
    final fields = <CustomAppDataField>[];
    
    for (final fieldData in fieldResults) {
      final fieldId = fieldData['id'] as String;
      
      // Get dropdown options for this field
      final optionsResult = await db.query(
        dropdownOptionsTable,
        where: 'field_id = ?',
        whereArgs: [fieldId],
        orderBy: 'sort_order ASC',
      );
      
      final dropdownOptions = optionsResult.isNotEmpty
          ? optionsResult.map((row) => row['option_value'] as String).toList()
          : null;
      
      fields.add(CustomAppDataField(
        id: fieldData['id'] as String,
        fieldName: fieldData['field_name'] as String,
        displayName: fieldData['display_name'] as String,
        fieldType: fieldData['field_type'] as String,
        currentValue: fieldData['current_value'] as String,
        category: fieldData['category'] as String,
        isRequired: (fieldData['is_required'] as int) == 1,
        placeholder: fieldData['placeholder'] as String?,
        description: fieldData['description'] as String?,
        sortOrder: fieldData['sort_order'] as int,
        dropdownOptions: dropdownOptions,
        createdAt: DateTime.parse(fieldData['created_at'] as String),
        updatedAt: DateTime.parse(fieldData['updated_at'] as String),
      ));
    }
    
    return fields;
  }

  /// Update custom field
  Future<void> updateCustomField(CustomAppDataField field) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Update main field record
      await txn.update(
        fieldsTable,
        {
          'field_name': field.fieldName,
          'display_name': field.displayName,
          'field_type': field.fieldType,
          'current_value': field.currentValue,
          'category': field.category,
          'is_required': field.isRequired ? 1 : 0,
          'placeholder': field.placeholder,
          'description': field.description,
          'sort_order': field.sortOrder,
          'updated_at': field.updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [field.id],
      );

      // Clear existing dropdown options
      await txn.delete(
        dropdownOptionsTable,
        where: 'field_id = ?',
        whereArgs: [field.id],
      );

      // Re-insert dropdown options if present
      if (field.dropdownOptions != null && field.dropdownOptions!.isNotEmpty) {
        for (int i = 0; i < field.dropdownOptions!.length; i++) {
          await txn.insert(dropdownOptionsTable, {
            'field_id': field.id,
            'option_value': field.dropdownOptions![i],
            'sort_order': i,
          });
        }
      }
    });
  }

  /// Delete custom field
  Future<void> deleteCustomField(String fieldId) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Delete dropdown options first (cascade will handle this, but being explicit)
      await txn.delete(
        dropdownOptionsTable,
        where: 'field_id = ?',
        whereArgs: [fieldId],
      );
      
      // Delete main field record
      await txn.delete(
        fieldsTable,
        where: 'id = ?',
        whereArgs: [fieldId],
      );
    });
  }

  /// Clear all custom fields
  Future<void> clearAllCustomFields() async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(dropdownOptionsTable);
      await txn.delete(fieldsTable);
    });
  }

  /// Search custom fields by name or display name
  Future<List<CustomAppDataField>> searchCustomFields(String query) async {
    final db = await database;
    final lowerQuery = query.toLowerCase();
    
    final fieldResults = await db.query(
      fieldsTable,
      where: 'LOWER(field_name) LIKE ? OR LOWER(display_name) LIKE ? OR LOWER(description) LIKE ?',
      whereArgs: ['%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%'],
      orderBy: 'sort_order ASC, display_name ASC',
    );
    
    final fields = <CustomAppDataField>[];
    
    for (final fieldData in fieldResults) {
      final fieldId = fieldData['id'] as String;
      
      // Get dropdown options for this field
      final optionsResult = await db.query(
        dropdownOptionsTable,
        where: 'field_id = ?',
        whereArgs: [fieldId],
        orderBy: 'sort_order ASC',
      );
      
      final dropdownOptions = optionsResult.isNotEmpty
          ? optionsResult.map((row) => row['option_value'] as String).toList()
          : null;
      
      fields.add(CustomAppDataField(
        id: fieldData['id'] as String,
        fieldName: fieldData['field_name'] as String,
        displayName: fieldData['display_name'] as String,
        fieldType: fieldData['field_type'] as String,
        currentValue: fieldData['current_value'] as String,
        category: fieldData['category'] as String,
        isRequired: (fieldData['is_required'] as int) == 1,
        placeholder: fieldData['placeholder'] as String?,
        description: fieldData['description'] as String?,
        sortOrder: fieldData['sort_order'] as int,
        dropdownOptions: dropdownOptions,
        createdAt: DateTime.parse(fieldData['created_at'] as String),
        updatedAt: DateTime.parse(fieldData['updated_at'] as String),
      ));
    }
    
    return fields;
  }

  /// Get custom field statistics
  Future<Map<String, dynamic>> getCustomFieldStatistics() async {
    final db = await database;
    
    final totalFields = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $fieldsTable')
    ) ?? 0;
    
    final totalOptions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $dropdownOptionsTable')
    ) ?? 0;
    
    // Get field counts by category
    final categoryResults = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM $fieldsTable 
      GROUP BY category 
      ORDER BY count DESC
    ''');
    
    final categoryStats = <String, int>{};
    for (final row in categoryResults) {
      categoryStats[row['category'] as String] = row['count'] as int;
    }
    
    // Get field counts by type
    final typeResults = await db.rawQuery('''
      SELECT field_type, COUNT(*) as count 
      FROM $fieldsTable 
      GROUP BY field_type 
      ORDER BY count DESC
    ''');
    
    final typeStats = <String, int>{};
    for (final row in typeResults) {
      typeStats[row['field_type'] as String] = row['count'] as int;
    }
    
    return {
      'total_fields': totalFields,
      'total_dropdown_options': totalOptions,
      'fields_by_category': categoryStats,
      'fields_by_type': typeStats,
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