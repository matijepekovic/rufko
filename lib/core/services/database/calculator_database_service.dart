import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../../models/calculator/custom_formula.dart';
import '../../models/calculator/formula_variable.dart';

// Conditional imports
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class CalculatorDatabaseService {
  static final CalculatorDatabaseService _instance = CalculatorDatabaseService._internal();
  factory CalculatorDatabaseService() => _instance;
  CalculatorDatabaseService._internal();
  
  static CalculatorDatabaseService get instance => _instance;
  
  Database? _database;
  bool _isInitialized = false;
  static const String _customFormulasTable = 'custom_formulas';
  static const String _formulaVariablesTable = 'formula_variables';
  static const String _formulaCategoriesTable = 'formula_categories';
  static const int _databaseVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_isInitialized) return _database!;
    
    try {
      // Initialize SQLite for desktop platforms
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        ffi.sqfliteFfiInit();
        databaseFactory = ffi.databaseFactoryFfi;
      }
      
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'rufko_calculator.db');
    
      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('Calculator database initialized successfully');
        final formulaCount = Sqflite.firstIntValue(
          await _database!.rawQuery('SELECT COUNT(*) FROM $_customFormulasTable'),
        );
        debugPrint('- Custom Formulas: $formulaCount');
      }
      
      return _database!;
    } catch (e) {
      // If SQLite fails (desktop platforms), skip calculator initialization
      if (kDebugMode) {
        debugPrint('Calculator database initialization failed: $e');
        debugPrint('Calculator features will be disabled');
      }
      _isInitialized = true; // Mark as initialized to prevent retries
      throw Exception('Calculator database not available on this platform');
    }
  }

  Future<void> init() async {
    await database; // This will initialize the database
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add usage tracking columns
      await db.execute('''
        ALTER TABLE $_customFormulasTable 
        ADD COLUMN usage_count INTEGER NOT NULL DEFAULT 0
      ''');
      
      await db.execute('''
        ALTER TABLE $_customFormulasTable 
        ADD COLUMN last_used_at TEXT
      ''');
      
      // Create index for usage tracking
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_formulas_usage 
        ON $_customFormulasTable (usage_count DESC, last_used_at DESC)
      ''');
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    // Custom formulas table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_customFormulasTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        expression TEXT NOT NULL,
        description TEXT,
        is_global INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        category TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 0,
        last_used_at TEXT
      )
    ''');

    // Formula variables table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_formulaVariablesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        formula_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        default_value REAL,
        description TEXT,
        unit TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (formula_id) REFERENCES $_customFormulasTable (id) ON DELETE CASCADE
      )
    ''');

    // Formula categories table (optional)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_formulaCategoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indices for better performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_formulas_favorite ON $_customFormulasTable (is_favorite)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_formulas_global ON $_customFormulasTable (is_global)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_formulas_category ON $_customFormulasTable (category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_variables_formula ON $_formulaVariablesTable (formula_id)');
    
    // Create index for usage tracking
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_formulas_usage 
      ON $_customFormulasTable (usage_count DESC, last_used_at DESC)
    ''');

    // Insert default roofing formulas
    await _insertDefaultFormulas(db);
  }

  static Future<void> _insertDefaultFormulas(Database db) async {
    // Check if we already have default formulas
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_customFormulasTable WHERE is_global = 1'),
    );
    
    if (count != null && count > 0) return; // Already have default formulas

    final now = DateTime.now().toIso8601String();

    // Insert default roofing formulas
    final defaultFormulas = [
      {
        'name': 'Roof Squares',
        'expression': '{Area} / 100',
        'description': 'Convert square feet to roofing squares',
        'is_global': 1,
        'category': 'Roofing',
        'order_index': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'Waste Factor',
        'expression': '{Base} * (1 + {WastePercent} / 100)',
        'description': 'Add waste percentage to base amount',
        'is_global': 1,
        'category': 'General',
        'order_index': 2,
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'Pitch Multiplier',
        'expression': '{Base} * {PitchFactor}',
        'description': 'Apply pitch factor to base calculation',
        'is_global': 1,
        'category': 'Roofing',
        'order_index': 3,
        'created_at': now,
        'updated_at': now,
      },
      {
        'name': 'Coverage Factor',
        'expression': '{Area} * {CoverageFactor}',
        'description': 'Calculate material coverage',
        'is_global': 1,
        'category': 'Materials',
        'order_index': 4,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final formula in defaultFormulas) {
      final formulaId = await db.insert(_customFormulasTable, formula);
      
      // Add variables for each formula
      switch (formula['name']) {
        case 'Roof Squares':
          await db.insert(_formulaVariablesTable, {
            'formula_id': formulaId,
            'name': 'Area',
            'description': 'Area in square feet',
            'unit': 'sq ft',
            'created_at': now,
            'updated_at': now,
          });
          break;
        case 'Waste Factor':
          await db.insert(_formulaVariablesTable, {
            'formula_id': formulaId,
            'name': 'Base',
            'description': 'Base amount',
            'created_at': now,
            'updated_at': now,
          });
          await db.insert(_formulaVariablesTable, {
            'formula_id': formulaId,
            'name': 'WastePercent',
            'default_value': 10.0,
            'description': 'Waste percentage',
            'unit': '%',
            'created_at': now,
            'updated_at': now,
          });
          break;
        case 'Pitch Multiplier':
          await db.insert(_formulaVariablesTable, {
            'formula_id': formulaId,
            'name': 'Base',
            'description': 'Base amount',
            'created_at': now,
            'updated_at': now,
          });
          await db.insert(_formulaVariablesTable, {
            'formula_id': formulaId,
            'name': 'PitchFactor',
            'default_value': 1.15,
            'description': 'Pitch multiplier factor',
            'created_at': now,
            'updated_at': now,
          });
          break;
        case 'Coverage Factor':
          await db.insert(_formulaVariablesTable, {
            'formula_id': formulaId,
            'name': 'Area',
            'description': 'Area to cover',
            'unit': 'sq ft',
            'created_at': now,
            'updated_at': now,
          });
          await db.insert(_formulaVariablesTable, {
            'formula_id': formulaId,
            'name': 'CoverageFactor',
            'default_value': 0.9,
            'description': 'Material coverage factor',
            'created_at': now,
            'updated_at': now,
          });
          break;
      }
    }
  }

  // CRUD operations for formulas
  Future<int> insertFormula(CustomFormula formula) async {
    final db = await database;
    return await db.insert(_customFormulasTable, formula.toMap());
  }

  Future<List<CustomFormula>> getAllFormulas() async {
    final db = await database;
    final results = await db.query(
      _customFormulasTable,
      orderBy: 'is_favorite DESC, order_index ASC, name ASC',
    );

    final formulas = <CustomFormula>[];
    for (final row in results) {
      final variables = await getFormulaVariables(row['id'] as int);
      formulas.add(CustomFormula.fromMap(row, variables: variables));
    }

    return formulas;
  }

  Future<List<CustomFormula>> searchFormulas(String query) async {
    final db = await database;
    final results = await db.query(
      _customFormulasTable,
      where: 'name LIKE ? OR description LIKE ? OR expression LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'is_favorite DESC, order_index ASC, name ASC',
    );

    final formulas = <CustomFormula>[];
    for (final row in results) {
      final variables = await getFormulaVariables(row['id'] as int);
      formulas.add(CustomFormula.fromMap(row, variables: variables));
    }

    return formulas;
  }

  Future<CustomFormula?> getFormula(int id) async {
    final db = await database;
    final results = await db.query(
      _customFormulasTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final variables = await getFormulaVariables(id);
    return CustomFormula.fromMap(results.first, variables: variables);
  }

  Future<void> updateFormula(CustomFormula formula) async {
    final db = await database;
    await db.update(
      _customFormulasTable,
      formula.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [formula.id],
    );
  }

  Future<void> deleteFormula(int id) async {
    final db = await database;
    await db.delete(_customFormulasTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      _customFormulasTable,
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for formula variables
  Future<int> insertVariable(FormulaVariable variable) async {
    final db = await database;
    return await db.insert(_formulaVariablesTable, variable.toMap());
  }

  Future<List<FormulaVariable>> getFormulaVariables(int formulaId) async {
    final db = await database;
    final results = await db.query(
      _formulaVariablesTable,
      where: 'formula_id = ?',
      whereArgs: [formulaId],
      orderBy: 'name ASC',
    );

    return results.map((row) => FormulaVariable.fromMap(row)).toList();
  }

  Future<void> updateVariable(FormulaVariable variable) async {
    final db = await database;
    await db.update(
      _formulaVariablesTable,
      variable.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [variable.id],
    );
  }

  Future<void> deleteVariable(int id) async {
    final db = await database;
    await db.delete(_formulaVariablesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVariablesForFormula(int formulaId) async {
    final db = await database;
    await db.delete(_formulaVariablesTable, where: 'formula_id = ?', whereArgs: [formulaId]);
  }

  /// Records that a formula has been used by incrementing usage count and updating last used timestamp
  Future<void> recordFormulaUsage(int id) async {
    final db = await database;
    
    // Get current usage count
    final result = await db.query(
      _customFormulasTable,
      columns: ['usage_count'],
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      final currentCount = result.first['usage_count'] as int? ?? 0;
      
      await db.update(
        _customFormulasTable,
        {
          'usage_count': currentCount + 1,
          'last_used_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Gets the most frequently used formulas ordered by usage count and last used date
  Future<List<CustomFormula>> getMostUsedFormulas({int limit = 10}) async {
    final db = await database;
    final results = await db.query(
      _customFormulasTable,
      orderBy: 'usage_count DESC, last_used_at DESC, is_favorite DESC',
      limit: limit,
    );

    final formulas = <CustomFormula>[];
    for (final row in results) {
      final variables = await getFormulaVariables(row['id'] as int);
      formulas.add(CustomFormula.fromMap(row, variables: variables));
    }

    return formulas;
  }
}