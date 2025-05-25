// lib/services/database_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/quote.dart'; // For QuoteItem, and OLD Quote if kept temporarily
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/app_settings.dart';
import '../models/simplified_quote.dart'; // NEW primary quote model
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance; // Singleton accessor
  DatabaseService._internal();
  static DatabaseService get instance => _instance;

  // Hive boxes
  late Box<Customer> _customerBox;
  late Box<Product> _productBox;
  late Box<QuoteItem> _quoteItemBox; // If you want to store QuoteItems independently (less common)
  // More likely, QuoteItems are part of QuoteLevel/SimplifiedMultiLevelQuote

  // --- NEW Primary Quote System Box ---
  late Box<SimplifiedMultiLevelQuote> _simplifiedQuoteBox;

  // --- OLD Quote System Boxes (to be phased out or if migrating) ---
  // late Box<old_mlq.MultiLevelQuote> _legacyMultiLevelQuoteBox; // For the old complex MLQ model - REMOVED

  late Box<RoofScopeData> _roofScopeBox;
  late Box<ProjectMedia> _mediaBox;
  late Box<AppSettings> _settingsBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _customerBox = await Hive.openBox<Customer>('customers');
      _productBox = await Hive.openBox<Product>('products');
      // _quoteItemBox = await Hive.openBox<QuoteItem>('quote_items'); // Only if storing independently

      // NEW primary quote system
      _simplifiedQuoteBox = await Hive.openBox<SimplifiedMultiLevelQuote>('simplified_quotes_v2'); // Added _v2 to ensure fresh box if old one existed with same name

      // OLD quote systems (open them if you need to read old data for migration)
      // _legacyMultiLevelQuoteBox = await Hive.openBox<old_mlq.MultiLevelQuote>('multi_level_quotes'); // REMOVED

      _roofScopeBox = await Hive.openBox<RoofScopeData>('roofscope_data');
      _mediaBox = await Hive.openBox<ProjectMedia>('project_media');
      _settingsBox = await Hive.openBox<AppSettings>('app_settings');

      _isInitialized = true;
      if (kDebugMode) {
        print('Database initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
  }

  // --- Customer Operations ---
  Future<void> saveCustomer(Customer customer) async {
    _ensureInitialized();
    await _customerBox.put(customer.id, customer);
  }
  Future<Customer?> getCustomer(String id) async {
    _ensureInitialized();
    return _customerBox.get(id);
  }
  Future<List<Customer>> getAllCustomers() async {
    _ensureInitialized();
    return _customerBox.values.toList();
  }
  Future<void> deleteCustomer(String id) async {
    _ensureInitialized();
    await _customerBox.delete(id);
  }

  // --- Product Operations ---
  Future<void> saveProduct(Product product) async {
    _ensureInitialized();
    await _productBox.put(product.id, product);
  }
  Future<Product?> getProduct(String id) async {
    _ensureInitialized();
    return _productBox.get(id);
  }
  Future<List<Product>> getAllProducts() async {
    _ensureInitialized();
    return _productBox.values.toList(); // Consider filtering by isActive here if needed widely
  }
  Future<void> deleteProduct(String id) async {
    _ensureInitialized();
    await _productBox.delete(id);
  }

  // --- NEW SimplifiedMultiLevelQuote Operations ---
  Future<void> saveSimplifiedMultiLevelQuote(SimplifiedMultiLevelQuote quote) async {
    _ensureInitialized();
    await _simplifiedQuoteBox.put(quote.id, quote);
  }
  Future<SimplifiedMultiLevelQuote?> getSimplifiedMultiLevelQuote(String id) async {
    _ensureInitialized();
    return _simplifiedQuoteBox.get(id);
  }
  Future<List<SimplifiedMultiLevelQuote>> getAllSimplifiedMultiLevelQuotes() async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values.toList();
  }
  Future<void> deleteSimplifiedMultiLevelQuote(String id) async {
    _ensureInitialized();
    await _simplifiedQuoteBox.delete(id);
  }

  // --- RoofScopeData Operations ---
  Future<void> saveRoofScopeData(RoofScopeData data) async {
    _ensureInitialized();
    await _roofScopeBox.put(data.id, data);
  }
  Future<RoofScopeData?> getRoofScopeData(String id) async {
    _ensureInitialized();
    return _roofScopeBox.get(id);
  }
  Future<List<RoofScopeData>> getAllRoofScopeData() async {
    _ensureInitialized();
    return _roofScopeBox.values.toList();
  }
  Future<void> deleteRoofScopeData(String id) async {
    _ensureInitialized();
    await _roofScopeBox.delete(id);
  }

  // --- ProjectMedia Operations ---
  Future<void> saveProjectMedia(ProjectMedia media) async {
    _ensureInitialized();
    await _mediaBox.put(media.id, media);
  }
  Future<ProjectMedia?> getProjectMedia(String id) async {
    _ensureInitialized();
    return _mediaBox.get(id);
  }
  Future<List<ProjectMedia>> getAllProjectMedia() async {
    _ensureInitialized();
    return _mediaBox.values.toList();
  }
  Future<void> deleteProjectMedia(String id) async {
    _ensureInitialized();
    await _mediaBox.delete(id);
  }
  // Add deleteProjectMediaByQuoteId or similar if needed for cascading deletes
  Future<void> deleteProjectMediaByQuoteId(String quoteId) async {
    _ensureInitialized();
    final keysToDelete = _mediaBox.values.where((media) => media.quoteId == quoteId).map((media) => media.key as String).toList();
    await _mediaBox.deleteAll(keysToDelete);
  }


  // --- AppSettings Operations ---
  Future<AppSettings?> getAppSettings() async {
    _ensureInitialized();
    if (_settingsBox.isEmpty) {
      // Create and save default settings if none exist
      final defaultSettings = AppSettings();
      await saveAppSettings(defaultSettings);
      return defaultSettings;
    }
    return _settingsBox.values.first;
  }
  Future<void> saveAppSettings(AppSettings settings) async {
    _ensureInitialized();
    // Assuming AppSettings uses a fixed key or you always replace the first one
    if (_settingsBox.isEmpty) {
      await _settingsBox.add(settings); // Or put with a fixed key like 'singleton_app_settings'
    } else {
      await _settingsBox.putAt(0, settings); // Or put with a fixed key
    }
  }

  // --- OLD Quote System Operations (DEPRECATED - for migration or temp use) ---

  // --- OLD MultiLevelQuote (complex one) was REMOVED, so its DB methods are also removed ---
  // @Deprecated('Use saveSimplifiedMultiLevelQuote instead.')
  // Future<void> saveMultiLevelQuote(old_mlq.MultiLevelQuote quote) async {...}
  // @Deprecated('Use getAllSimplifiedMultiLevelQuotes instead.')
  // Future<List<old_mlq.MultiLevelQuote>> getAllMultiLevelQuotes() async {...}
  // @Deprecated('Use deleteSimplifiedMultiLevelQuote instead.')
  // Future<void> deleteMultiLevelQuote(String id) async {...}


  // --- Backup and Restore (Needs to be updated for SimplifiedMultiLevelQuote) ---
  Future<Map<String, dynamic>> exportAllData() async {
    _ensureInitialized();
    return {
      'customers': (await getAllCustomers()).map((c) => c.toMap()).toList(),
      'products': (await getAllProducts()).map((p) => p.toMap()).toList(),
      'simplified_quotes': (await getAllSimplifiedMultiLevelQuotes()).map((q) => q.toMap()).toList(), // UPDATED
      'roofScopeData': (await getAllRoofScopeData()).map((r) => r.toMap()).toList(),
      'projectMedia': (await getAllProjectMedia()).map((m) => m.toMap()).toList(),
      'appSettings': (await getAppSettings())?.toMap(), // Handle potential null
      // 'legacy_quotes': (await getAllQuotes()).map((q) => q.toMap()).toList(), // If migrating
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    _ensureInitialized();
    try {
      await _customerBox.clear();
      await _productBox.clear();
      await _simplifiedQuoteBox.clear(); // UPDATED
      await _roofScopeBox.clear();
      await _mediaBox.clear();
      await _settingsBox.clear();
      // await _legacyQuoteBox.clear(); // If migrating

      if (data['customers'] != null) {
        for (final itemData in data['customers']) { await saveCustomer(Customer.fromMap(itemData)); }
      }
      if (data['products'] != null) {
        for (final itemData in data['products']) { await saveProduct(Product.fromMap(itemData)); }
      }
      if (data['simplified_quotes'] != null) { // UPDATED
        for (final itemData in data['simplified_quotes']) { await saveSimplifiedMultiLevelQuote(SimplifiedMultiLevelQuote.fromMap(itemData)); }
      }
      if (data['roofScopeData'] != null) {
        for (final itemData in data['roofScopeData']) { await saveRoofScopeData(RoofScopeData.fromMap(itemData)); }
      }
      if (data['projectMedia'] != null) {
        for (final itemData in data['projectMedia']) { await saveProjectMedia(ProjectMedia.fromMap(itemData)); }
      }
      if (data['appSettings'] != null) {
        await saveAppSettings(AppSettings.fromMap(data['appSettings']));
      }
      // if (data['legacy_quotes'] != null) { // If migrating
      //   for (final itemData in data['legacy_quotes']) { await saveQuote(Quote.fromMap(itemData)); }
      // }
      if (kDebugMode) {
        print('Data import completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error importing data: $e');
      }
      rethrow;
    }
  }

  Future<void> close() async {
    if (!_isInitialized) return;
    await Hive.close(); // Closes all boxes
    _isInitialized = false;
  }
}