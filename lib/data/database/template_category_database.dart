import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../models/templates/template_category.dart';

/// SQLite database service for TemplateCategory
/// Handles category storage for organizing templates
class TemplateCategoryDatabase {
  static final TemplateCategoryDatabase _instance = TemplateCategoryDatabase._internal();
  factory TemplateCategoryDatabase() => _instance;
  TemplateCategoryDatabase._internal();

  static Database? _database;
  static const String databaseName = 'template_categories.db';
  static const int databaseVersion = 1;

  // Table names
  static const String categoriesTable = 'template_categories';

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
      path = 'template_categories.db';
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
    // Template categories table
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id TEXT PRIMARY KEY,
        key TEXT NOT NULL,
        name TEXT NOT NULL,
        template_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(key, template_type)
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_categories_template_type ON $categoriesTable (template_type)');
    await db.execute('CREATE INDEX idx_categories_key ON $categoriesTable (key)');
    await db.execute('CREATE INDEX idx_categories_name ON $categoriesTable (name)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Example: Add new columns in version 2
      // await db.execute('ALTER TABLE $categoriesTable ADD COLUMN new_field TEXT');
    }
  }

  /// Insert a template category
  Future<void> insertTemplateCategory(TemplateCategory category) async {
    final db = await database;
    
    await db.insert(
      categoriesTable,
      {
        'id': category.id,
        'key': category.key,
        'name': category.name,
        'template_type': category.templateType,
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple template categories
  Future<void> insertTemplateCategories(List<TemplateCategory> categories) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (final category in categories) {
        await txn.insert(
          categoriesTable,
          {
            'id': category.id,
            'key': category.key,
            'name': category.name,
            'template_type': category.templateType,
            'created_at': category.createdAt.toIso8601String(),
            'updated_at': category.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get template category by ID
  Future<TemplateCategory?> getTemplateCategoryById(String categoryId) async {
    final db = await database;
    
    final result = await db.query(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    final data = result.first;
    return TemplateCategory(
      id: data['id'] as String,
      key: data['key'] as String,
      name: data['name'] as String,
      templateType: data['template_type'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  /// Get template category by key and template type
  Future<TemplateCategory?> getTemplateCategoryByKey(String key, String templateType) async {
    final db = await database;
    
    final result = await db.query(
      categoriesTable,
      where: 'key = ? AND template_type = ?',
      whereArgs: [key, templateType],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    final data = result.first;
    return TemplateCategory(
      id: data['id'] as String,
      key: data['key'] as String,
      name: data['name'] as String,
      templateType: data['template_type'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  /// Get all template categories
  Future<List<TemplateCategory>> getAllTemplateCategories() async {
    final db = await database;
    
    final result = await db.query(
      categoriesTable,
      orderBy: 'template_type ASC, name ASC',
    );
    
    return result.map((data) => TemplateCategory(
      id: data['id'] as String,
      key: data['key'] as String,
      name: data['name'] as String,
      templateType: data['template_type'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    )).toList();
  }

  /// Get template categories by template type
  Future<List<TemplateCategory>> getTemplateCategoriesByType(String templateType) async {
    final db = await database;
    
    final result = await db.query(
      categoriesTable,
      where: 'template_type = ?',
      whereArgs: [templateType],
      orderBy: 'name ASC',
    );
    
    return result.map((data) => TemplateCategory(
      id: data['id'] as String,
      key: data['key'] as String,
      name: data['name'] as String,
      templateType: data['template_type'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    )).toList();
  }

  /// Get template categories structured for UI display
  Future<Map<String, List<Map<String, dynamic>>>> getTemplateCategoriesForUI() async {
    final db = await database;
    
    final result = await db.query(
      categoriesTable,
      orderBy: 'template_type ASC, name ASC',
    );
    
    final Map<String, List<Map<String, dynamic>>> categoriesMap = {
      'pdf_templates': [],
      'message_templates': [],
      'email_templates': [],
      'fields': [],
    };
    
    for (final data in result) {
      final templateType = data['template_type'] as String;
      final categoryData = {
        'id': data['id'],
        'key': data['key'],
        'name': data['name'],
      };
      
      // Map template types to UI keys
      String uiKey;
      switch (templateType) {
        case 'pdf_templates':
        case 'PDF Templates':
          uiKey = 'pdf_templates';
          break;
        case 'message_templates':
        case 'Message Templates':
          uiKey = 'message_templates';
          break;
        case 'email_templates':
        case 'Email Templates':
          uiKey = 'email_templates';
          break;
        case 'fields':
        case 'Fields':
          uiKey = 'fields';
          break;
        default:
          // Use template type as-is, but convert to lowercase with underscores
          uiKey = templateType.toLowerCase().replaceAll(' ', '_');
          if (!categoriesMap.containsKey(uiKey)) {
            categoriesMap[uiKey] = [];
          }
      }
      
      if (categoriesMap.containsKey(uiKey)) {
        categoriesMap[uiKey]!.add(categoryData);
      }
    }
    
    return categoriesMap;
  }

  /// Update template category
  Future<void> updateTemplateCategory(TemplateCategory category) async {
    final db = await database;
    
    await db.update(
      categoriesTable,
      {
        'key': category.key,
        'name': category.name,
        'template_type': category.templateType,
        'updated_at': category.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Update category name by ID
  Future<void> updateTemplateCategoryName(String categoryId, String newName) async {
    final db = await database;
    
    await db.update(
      categoriesTable,
      {
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Delete template category
  Future<void> deleteTemplateCategory(String categoryId) async {
    final db = await database;
    
    await db.delete(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Clear all template categories
  Future<void> clearAllTemplateCategories() async {
    final db = await database;
    await db.delete(categoriesTable);
  }

  /// Search template categories by name or key
  Future<List<TemplateCategory>> searchTemplateCategories(String query) async {
    final db = await database;
    final lowerQuery = query.toLowerCase();
    
    final result = await db.query(
      categoriesTable,
      where: 'LOWER(name) LIKE ? OR LOWER(key) LIKE ?',
      whereArgs: ['%$lowerQuery%', '%$lowerQuery%'],
      orderBy: 'name ASC',
    );
    
    return result.map((data) => TemplateCategory(
      id: data['id'] as String,
      key: data['key'] as String,
      name: data['name'] as String,
      templateType: data['template_type'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    )).toList();
  }

  /// Check if category key exists for a given template type
  Future<bool> categoryKeyExists(String key, String templateType) async {
    final db = await database;
    
    final result = await db.query(
      categoriesTable,
      where: 'key = ? AND template_type = ?',
      whereArgs: [key, templateType],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }

  /// Get template category statistics
  Future<Map<String, dynamic>> getTemplateCategoryStatistics() async {
    final db = await database;
    
    final totalCategories = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $categoriesTable')
    ) ?? 0;
    
    // Get category counts by template type
    final typeResults = await db.rawQuery('''
      SELECT template_type, COUNT(*) as count 
      FROM $categoriesTable 
      GROUP BY template_type 
      ORDER BY count DESC
    ''');
    
    final typeStats = <String, int>{};
    for (final row in typeResults) {
      typeStats[row['template_type'] as String] = row['count'] as int;
    }
    
    return {
      'total_categories': totalCategories,
      'categories_by_type': typeStats,
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