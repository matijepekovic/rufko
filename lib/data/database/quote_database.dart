import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import '../models/business/simplified_quote.dart';
import '../models/business/quote.dart';
import '../models/business/quote_extras.dart';

/// SQLite database manager for quote-related data
/// Handles database creation, migrations, and provides connection management
class QuoteDatabase {
  static const String _databaseName = 'rufko_quotes.db';
  static const int _databaseVersion = 4;

  // Table names
  static const String quotesTable = 'quotes';
  static const String quoteLevelsTable = 'quote_levels';
  static const String quoteItemsTable = 'quote_items';
  static const String quoteDiscountsTable = 'quote_discounts';
  static const String quoteAddonsTable = 'quote_addons';
  static const String quotePermitsTable = 'quote_permits';
  static const String quoteCustomLineItemsTable = 'quote_custom_line_items';
  static const String quoteEditHistoryTable = 'quote_edit_history';

  // Singleton pattern
  static final QuoteDatabase _instance = QuoteDatabase._internal();
  factory QuoteDatabase() => _instance;
  QuoteDatabase._internal();

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
    await db.execute('''
      CREATE TABLE $quotesTable (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        roof_scope_data_id TEXT,
        quote_number TEXT NOT NULL UNIQUE,
        tax_rate REAL NOT NULL DEFAULT 0.0,
        discount REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'draft',
        previous_status TEXT,
        version INTEGER NOT NULL DEFAULT 1,
        parent_quote_id TEXT,
        is_current_version INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        valid_until TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        base_product_id TEXT,
        base_product_name TEXT,
        base_product_unit TEXT,
        non_discountable_product_ids TEXT,
        pdf_path TEXT,
        pdf_template_id TEXT,
        pdf_generated_at TEXT,
        selected_level_id TEXT,
        no_permits_required INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $quoteLevelsTable (
        id TEXT PRIMARY KEY,
        quote_id TEXT NOT NULL,
        name TEXT NOT NULL,
        level_number INTEGER NOT NULL,
        base_price REAL NOT NULL,
        base_quantity REAL NOT NULL DEFAULT 1.0,
        subtotal REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $quoteItemsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id TEXT,
        level_id TEXT,
        addon_quote_id TEXT,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        unit TEXT NOT NULL,
        description TEXT,
        item_type TEXT NOT NULL DEFAULT 'level_item',
        FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE,
        FOREIGN KEY (level_id) REFERENCES $quoteLevelsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (addon_quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $quoteDiscountsTable (
        id TEXT PRIMARY KEY,
        quote_id TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        code TEXT,
        description TEXT,
        apply_to_addons INTEGER NOT NULL DEFAULT 1,
        excluded_product_ids TEXT,
        expiry_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $quoteAddonsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        unit TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $quotePermitsTable (
        id TEXT PRIMARY KEY,
        quote_id TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        is_required INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $quoteCustomLineItemsTable (
        id TEXT PRIMARY KEY,
        quote_id TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        is_taxable INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $quoteEditHistoryTable (
        id TEXT PRIMARY KEY,
        quote_id TEXT NOT NULL,
        version INTEGER NOT NULL,
        edit_reason TEXT NOT NULL,
        edit_description TEXT,
        edited_at TEXT NOT NULL,
        changes_summary TEXT,
        FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  /// Create indexes for better query performance
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_quotes_customer_id ON $quotesTable(customer_id)');
    await db.execute('CREATE INDEX idx_quotes_status ON $quotesTable(status)');
    await db.execute('CREATE INDEX idx_quotes_created_at ON $quotesTable(created_at)');
    await db.execute('CREATE INDEX idx_quote_levels_quote_id ON $quoteLevelsTable(quote_id)');
    await db.execute('CREATE INDEX idx_quote_items_quote_id ON $quoteItemsTable(quote_id)');
    await db.execute('CREATE INDEX idx_quote_items_level_id ON $quoteItemsTable(level_id)');
    await db.execute('CREATE INDEX idx_quote_discounts_quote_id ON $quoteDiscountsTable(quote_id)');
    await db.execute('CREATE INDEX idx_quote_addons_quote_id ON $quoteAddonsTable(quote_id)');
    await db.execute('CREATE INDEX idx_quote_permits_quote_id ON $quotePermitsTable(quote_id)');
    await db.execute('CREATE INDEX idx_quote_custom_line_items_quote_id ON $quoteCustomLineItemsTable(quote_id)');
    await db.execute('CREATE INDEX idx_quotes_parent_quote_id ON $quotesTable(parent_quote_id)');
    await db.execute('CREATE INDEX idx_quotes_version ON $quotesTable(version)');
    await db.execute('CREATE INDEX idx_quotes_current_version ON $quotesTable(is_current_version)');
    await db.execute('CREATE INDEX idx_quote_edit_history_quote_id ON $quoteEditHistoryTable(quote_id)');
    await db.execute('CREATE INDEX idx_quote_edit_history_version ON $quoteEditHistoryTable(version)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database schema changes
    if (oldVersion < 2) {
      // Add previous_status column to quotes table
      await db.execute('ALTER TABLE $quotesTable ADD COLUMN previous_status TEXT');
    }
    
    if (oldVersion < 4) {
      // Add versioning fields to quotes table
      await db.execute('ALTER TABLE $quotesTable ADD COLUMN version INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $quotesTable ADD COLUMN parent_quote_id TEXT');
      await db.execute('ALTER TABLE $quotesTable ADD COLUMN is_current_version INTEGER NOT NULL DEFAULT 1');
      
      // Create quote edit history table
      await db.execute('''
        CREATE TABLE $quoteEditHistoryTable (
          id TEXT PRIMARY KEY,
          quote_id TEXT NOT NULL,
          version INTEGER NOT NULL,
          edit_reason TEXT NOT NULL,
          edit_description TEXT,
          edited_at TEXT NOT NULL,
          changes_summary TEXT,
          FOREIGN KEY (quote_id) REFERENCES $quotesTable(id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for new fields
      await db.execute('CREATE INDEX idx_quotes_parent_quote_id ON $quotesTable(parent_quote_id)');
      await db.execute('CREATE INDEX idx_quotes_version ON $quotesTable(version)');
      await db.execute('CREATE INDEX idx_quotes_current_version ON $quotesTable(is_current_version)');
      await db.execute('CREATE INDEX idx_quote_edit_history_quote_id ON $quoteEditHistoryTable(quote_id)');
      await db.execute('CREATE INDEX idx_quote_edit_history_version ON $quoteEditHistoryTable(version)');
    }
  }

  /// Convert SimplifiedMultiLevelQuote to database map
  Map<String, dynamic> quoteToMap(SimplifiedMultiLevelQuote quote) {
    return {
      'id': quote.id,
      'customer_id': quote.customerId,
      'roof_scope_data_id': quote.roofScopeDataId,
      'quote_number': quote.quoteNumber,
      'tax_rate': quote.taxRate,
      'discount': quote.discount,
      'status': quote.status,
      'previous_status': quote.previousStatus,
      'version': quote.version,
      'parent_quote_id': quote.parentQuoteId,
      'is_current_version': quote.isCurrentVersion ? 1 : 0,
      'notes': quote.notes,
      'valid_until': quote.validUntil.toIso8601String(),
      'created_at': quote.createdAt.toIso8601String(),
      'updated_at': quote.updatedAt.toIso8601String(),
      'base_product_id': quote.baseProductId,
      'base_product_name': quote.baseProductName,
      'base_product_unit': quote.baseProductUnit,
      'non_discountable_product_ids': jsonEncode(quote.nonDiscountableProductIds),
      'pdf_path': quote.pdfPath,
      'pdf_template_id': quote.pdfTemplateId,
      'pdf_generated_at': quote.pdfGeneratedAt?.toIso8601String(),
      'selected_level_id': quote.selectedLevelId,
      'no_permits_required': quote.noPermitsRequired ? 1 : 0,
    };
  }

  /// Convert QuoteLevel to database map
  Map<String, dynamic> quoteLevelToMap(QuoteLevel level, String quoteId) {
    return {
      'id': level.id,
      'quote_id': quoteId,
      'name': level.name,
      'level_number': level.levelNumber,
      'base_price': level.basePrice,
      'base_quantity': level.baseQuantity,
      'subtotal': level.subtotal,
    };
  }

  /// Convert QuoteItem to database map for level items
  Map<String, dynamic> quoteItemToMap(QuoteItem item, String quoteId, String? levelId, {String itemType = 'level_item'}) {
    return {
      'quote_id': levelId == null ? quoteId : null,
      'level_id': levelId,
      'addon_quote_id': itemType == 'addon' ? quoteId : null,
      'product_id': item.productId,
      'product_name': item.productName,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
      'unit': item.unit,
      'description': item.description,
      'item_type': itemType,
    };
  }

  /// Convert QuoteDiscount to database map
  Map<String, dynamic> quoteDiscountToMap(QuoteDiscount discount, String quoteId) {
    return {
      'id': discount.id,
      'quote_id': quoteId,
      'type': discount.type,
      'value': discount.value,
      'code': discount.code,
      'description': discount.description,
      'apply_to_addons': discount.applyToAddons ? 1 : 0,
      'excluded_product_ids': jsonEncode(discount.excludedProductIds),
      'expiry_date': discount.expiryDate?.toIso8601String(),
      'is_active': discount.isActive ? 1 : 0,
    };
  }

  /// Convert PermitItem to database map
  Map<String, dynamic> permitItemToMap(PermitItem permit, String quoteId) {
    return {
      'id': permit.id,
      'quote_id': quoteId,
      'name': permit.name,
      'amount': permit.amount,
      'description': permit.description,
      'is_required': permit.isRequired ? 1 : 0,
    };
  }

  /// Convert CustomLineItem to database map
  Map<String, dynamic> customLineItemToMap(CustomLineItem item, String quoteId) {
    return {
      'id': item.id,
      'quote_id': quoteId,
      'name': item.name,
      'amount': item.amount,
      'description': item.description,
      'is_taxable': item.isTaxable ? 1 : 0,
    };
  }

  /// Convert database map to SimplifiedMultiLevelQuote
  SimplifiedMultiLevelQuote quoteFromMap(
    Map<String, dynamic> map, {
    List<QuoteLevel>? levels,
    List<QuoteItem>? addons,
    List<QuoteDiscount>? discounts,
    List<PermitItem>? permits,
    List<CustomLineItem>? customLineItems,
  }) {
    return SimplifiedMultiLevelQuote(
      id: map['id'],
      customerId: map['customer_id'],
      roofScopeDataId: map['roof_scope_data_id'],
      quoteNumber: map['quote_number'],
      levels: levels ?? [],
      addons: addons ?? [],
      taxRate: map['tax_rate']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'draft',
      previousStatus: map['previous_status'],
      version: map['version']?.toInt() ?? 1,
      parentQuoteId: map['parent_quote_id'],
      isCurrentVersion: (map['is_current_version'] ?? 1) == 1,
      notes: map['notes'],
      validUntil: DateTime.parse(map['valid_until']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      baseProductId: map['base_product_id'],
      baseProductName: map['base_product_name'],
      baseProductUnit: map['base_product_unit'],
      discounts: discounts ?? [],
      nonDiscountableProductIds: map['non_discountable_product_ids'] != null 
          ? List<String>.from(jsonDecode(map['non_discountable_product_ids']))
          : [],
      pdfPath: map['pdf_path'],
      pdfTemplateId: map['pdf_template_id'],
      pdfGeneratedAt: map['pdf_generated_at'] != null ? DateTime.parse(map['pdf_generated_at']) : null,
      permits: permits ?? [],
      noPermitsRequired: (map['no_permits_required'] ?? 0) == 1,
      customLineItems: customLineItems ?? [],
      selectedLevelId: map['selected_level_id'],
    );
  }

  /// Convert database map to QuoteLevel
  QuoteLevel quoteLevelFromMap(Map<String, dynamic> map, {List<QuoteItem>? includedItems}) {
    return QuoteLevel(
      id: map['id'],
      name: map['name'],
      levelNumber: map['level_number'],
      basePrice: map['base_price']?.toDouble() ?? 0.0,
      baseQuantity: map['base_quantity']?.toDouble() ?? 1.0,
      includedItems: includedItems ?? [],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
    );
  }

  /// Convert database map to QuoteItem
  QuoteItem quoteItemFromMap(Map<String, dynamic> map) {
    return QuoteItem(
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      unit: map['unit'],
      description: map['description'],
    );
  }

  /// Convert database map to QuoteDiscount
  QuoteDiscount quoteDiscountFromMap(Map<String, dynamic> map) {
    return QuoteDiscount(
      id: map['id'],
      type: map['type'],
      value: map['value']?.toDouble() ?? 0.0,
      code: map['code'],
      description: map['description'],
      applyToAddons: (map['apply_to_addons'] ?? 1) == 1,
      excludedProductIds: map['excluded_product_ids'] != null 
          ? List<String>.from(jsonDecode(map['excluded_product_ids']))
          : [],
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  /// Convert database map to PermitItem
  PermitItem permitItemFromMap(Map<String, dynamic> map) {
    return PermitItem(
      id: map['id'],
      name: map['name'],
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'],
      isRequired: (map['is_required'] ?? 1) == 1,
    );
  }

  /// Convert database map to CustomLineItem
  CustomLineItem customLineItemFromMap(Map<String, dynamic> map) {
    return CustomLineItem(
      id: map['id'],
      name: map['name'],
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'],
      isTaxable: (map['is_taxable'] ?? 1) == 1,
    );
  }

  /// Convert database map to QuoteEditHistory
  Map<String, dynamic> editHistoryToMap(Map<String, dynamic> editHistory) {
    return {
      'id': editHistory['id'],
      'quote_id': editHistory['quoteId'],
      'version': editHistory['version'],
      'edit_reason': editHistory['editReason'],
      'edit_description': editHistory['editDescription'],
      'edited_at': editHistory['editedAt'],
      'changes_summary': editHistory['changesSummary'],
    };
  }

  /// Convert database map to QuoteEditHistory object structure
  Map<String, dynamic> editHistoryFromMap(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'quoteId': map['quote_id'],
      'version': map['version']?.toInt() ?? 1,
      'editReason': map['edit_reason'],
      'editDescription': map['edit_description'],
      'editedAt': map['edited_at'],
      'changesSummary': map['changes_summary'],
    };
  }
}