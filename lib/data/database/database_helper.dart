import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;

/// Common database helper utilities for SQLite operations
class DatabaseHelper {
  static const String _databaseName = 'rufko_app.db';
  static const int _databaseVersion = 2;

  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  
  static DatabaseHelper get instance => _instance;

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
    // Create all tables for the new database files
    
    // Roof scope data table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS roof_scope_data (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        source_file_name TEXT,
        roof_area REAL NOT NULL DEFAULT 0.0,
        number_of_squares REAL NOT NULL DEFAULT 0.0,
        pitch REAL NOT NULL DEFAULT 0.0,
        valley_length REAL NOT NULL DEFAULT 0.0,
        hip_length REAL NOT NULL DEFAULT 0.0,
        ridge_length REAL NOT NULL DEFAULT 0.0,
        perimeter_length REAL NOT NULL DEFAULT 0.0,
        eave_length REAL NOT NULL DEFAULT 0.0,
        gutter_length REAL NOT NULL DEFAULT 0.0,
        chimney_count INTEGER NOT NULL DEFAULT 0,
        skylight_count INTEGER NOT NULL DEFAULT 0,
        flashing_length REAL NOT NULL DEFAULT 0.0,
        additional_measurements TEXT, -- JSON
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Project media table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_media (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        quote_id TEXT,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_type TEXT NOT NULL,
        description TEXT,
        tags TEXT, -- JSON array
        category TEXT NOT NULL DEFAULT 'general',
        file_size_bytes INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // PDF templates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pdf_templates (
        id TEXT PRIMARY KEY,
        template_name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        pdf_file_path TEXT NOT NULL,
        template_type TEXT NOT NULL DEFAULT 'quote',
        page_width REAL NOT NULL,
        page_height REAL NOT NULL,
        total_pages INTEGER NOT NULL DEFAULT 1,
        field_mappings TEXT, -- JSON array
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        metadata TEXT, -- JSON
        user_category_key TEXT
      )
    ''');

    // PDF field mappings table (separate table for field mapping details)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pdf_field_mappings (
        field_id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        app_data_type TEXT NOT NULL,
        pdf_form_field_name TEXT NOT NULL,
        detected_pdf_field_type INTEGER NOT NULL DEFAULT 0,
        visual_x REAL,
        visual_y REAL,
        visual_width REAL,
        visual_height REAL,
        page_number INTEGER NOT NULL DEFAULT 0,
        font_family_override TEXT,
        font_size_override REAL,
        font_color_override TEXT,
        alignment_override TEXT,
        additional_properties TEXT,
        FOREIGN KEY (template_id) REFERENCES pdf_templates (id) ON DELETE CASCADE
      )
    ''');

    // Message templates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS message_templates (
        id TEXT PRIMARY KEY,
        template_name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        message_content TEXT NOT NULL,
        placeholders TEXT, -- JSON array
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_category_key TEXT
      )
    ''');

    // Email templates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS email_templates (
        id TEXT PRIMARY KEY,
        template_name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        subject TEXT NOT NULL,
        email_content TEXT NOT NULL,
        placeholders TEXT, -- JSON array
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_html INTEGER NOT NULL DEFAULT 0,
        user_category_key TEXT
      )
    ''');

    // Inspection documents table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inspection_documents (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        file_path TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        quote_id TEXT,
        file_size_bytes INTEGER,
        tags TEXT -- JSON array
      )
    ''');

    // Create indexes for performance
    await _createIndexes(db);
  }

  /// Create indexes for better query performance
  Future<void> _createIndexes(Database db) async {
    // Roof scope data indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_roof_scope_customer_id ON roof_scope_data (customer_id)');
    
    // Project media indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_project_media_customer_id ON project_media (customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_project_media_quote_id ON project_media (quote_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_project_media_category ON project_media (category)');
    
    // PDF templates indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pdf_templates_active ON pdf_templates (is_active)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pdf_templates_type ON pdf_templates (template_type)');
    
    // PDF field mappings indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pdf_field_mappings_template_id ON pdf_field_mappings (template_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pdf_field_mappings_app_data_type ON pdf_field_mappings (app_data_type)');
    
    // Message templates indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_message_templates_active ON message_templates (is_active)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_message_templates_category ON message_templates (category)');
    
    // Email templates indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_email_templates_active ON email_templates (is_active)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_email_templates_category ON email_templates (category)');
    
    // Inspection documents indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inspection_docs_customer_id ON inspection_documents (customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inspection_docs_quote_id ON inspection_documents (quote_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inspection_docs_type ON inspection_documents (type)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations
    if (oldVersion < 2) {
      // Migration for version 2: Add pdf_field_mappings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pdf_field_mappings (
          field_id TEXT PRIMARY KEY,
          template_id TEXT NOT NULL,
          app_data_type TEXT NOT NULL,
          pdf_form_field_name TEXT NOT NULL,
          detected_pdf_field_type INTEGER NOT NULL DEFAULT 0,
          visual_x REAL,
          visual_y REAL,
          visual_width REAL,
          visual_height REAL,
          page_number INTEGER NOT NULL DEFAULT 0,
          font_family_override TEXT,
          font_size_override REAL,
          font_color_override TEXT,
          alignment_override TEXT,
          additional_properties TEXT,
          FOREIGN KEY (template_id) REFERENCES pdf_templates (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for the new table
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pdf_field_mappings_template_id ON pdf_field_mappings (template_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pdf_field_mappings_app_data_type ON pdf_field_mappings (app_data_type)');
      
      if (kDebugMode) {
        print('✅ Database upgraded to version 2: Added pdf_field_mappings table');
      }
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

  /// Utility method to execute raw SQL
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Utility method to execute raw SQL without return
  Future<void> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.rawQuery(sql, arguments);
  }

  /// Get database path for debugging
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getDatabasesPath();
    return join(documentsDirectory, _databaseName);
  }
}