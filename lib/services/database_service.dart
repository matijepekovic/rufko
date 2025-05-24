import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/quote.dart';
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/app_settings.dart';
import '../models/multi_level_quote.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  static DatabaseService get instance => _instance;

  // Hive boxes
  late Box<Customer> _customerBox;
  late Box<Product> _productBox;
  late Box<Quote> _quoteBox;
  late Box<RoofScopeData> _roofScopeBox;
  late Box<ProjectMedia> _mediaBox;
  late Box<AppSettings> _settingsBox;
  late Box<MultiLevelQuote> _multiLevelQuoteBox;

  bool _isInitialized = false;

  // Initialize database
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Open Hive boxes
      _customerBox = await Hive.openBox<Customer>('customers');
      _productBox = await Hive.openBox<Product>('products');
      _quoteBox = await Hive.openBox<Quote>('quotes');
      _roofScopeBox = await Hive.openBox<RoofScopeData>('roofscope_data');
      _mediaBox = await Hive.openBox<ProjectMedia>('project_media');
      _settingsBox = await Hive.openBox<AppSettings>('app_settings');
      _multiLevelQuoteBox = await Hive.openBox<MultiLevelQuote>('multi_level_quotes');

      _isInitialized = true;
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  // Ensure initialization
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
  }

  // Customer operations
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

  // Product operations
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
    return _productBox.values.where((p) => p.isActive).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    _ensureInitialized();
    return _productBox.values
        .where((p) => p.isActive && p.category == category)
        .toList();
  }

  Future<void> deleteProduct(String id) async {
    _ensureInitialized();
    await _productBox.delete(id);
  }

  // Quote operations
  Future<void> saveQuote(Quote quote) async {
    _ensureInitialized();
    await _quoteBox.put(quote.id, quote);
  }

  Future<Quote?> getQuote(String id) async {
    _ensureInitialized();
    return _quoteBox.get(id);
  }

  Future<List<Quote>> getAllQuotes() async {
    _ensureInitialized();
    return _quoteBox.values.toList();
  }

  Future<List<Quote>> getQuotesByCustomer(String customerId) async {
    _ensureInitialized();
    return _quoteBox.values
        .where((q) => q.customerId == customerId)
        .toList();
  }

  Future<List<Quote>> getQuotesByStatus(String status) async {
    _ensureInitialized();
    return _quoteBox.values
        .where((q) => q.status == status)
        .toList();
  }

  Future<void> deleteQuote(String id) async {
    _ensureInitialized();
    await _quoteBox.delete(id);
  }

  // RoofScope data operations
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

  Future<List<RoofScopeData>> getRoofScopeDataByCustomer(String customerId) async {
    _ensureInitialized();
    return _roofScopeBox.values
        .where((r) => r.customerId == customerId)
        .toList();
  }

  Future<void> deleteRoofScopeData(String id) async {
    _ensureInitialized();
    await _roofScopeBox.delete(id);
  }

  // Project Media operations
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

  Future<List<ProjectMedia>> getProjectMediaByCustomer(String customerId) async {
    _ensureInitialized();
    return _mediaBox.values
        .where((m) => m.customerId == customerId)
        .toList();
  }

  Future<List<ProjectMedia>> getProjectMediaByQuote(String quoteId) async {
    _ensureInitialized();
    return _mediaBox.values
        .where((m) => m.quoteId == quoteId)
        .toList();
  }

  Future<List<ProjectMedia>> getProjectMediaByCategory(String category) async {
    _ensureInitialized();
    return _mediaBox.values
        .where((m) => m.category == category)
        .toList();
  }

  Future<void> deleteProjectMedia(String id) async {
    _ensureInitialized();
    await _mediaBox.delete(id);
  }

  // AppSettings operations
  Future<AppSettings?> getAppSettings() async {
    _ensureInitialized();
    if (_settingsBox.isEmpty) return null;
    return _settingsBox.values.first;
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    _ensureInitialized();
    await _settingsBox.clear(); // Only keep one settings object
    await _settingsBox.put(settings.id, settings);
  }

  // Multi-Level Quote operations
  Future<void> saveMultiLevelQuote(MultiLevelQuote quote) async {
    _ensureInitialized();
    await _multiLevelQuoteBox.put(quote.id, quote);
  }

  Future<MultiLevelQuote?> getMultiLevelQuote(String id) async {
    _ensureInitialized();
    return _multiLevelQuoteBox.get(id);
  }

  Future<List<MultiLevelQuote>> getAllMultiLevelQuotes() async {
    _ensureInitialized();
    return _multiLevelQuoteBox.values.toList();
  }

  Future<void> deleteMultiLevelQuote(String id) async {
    _ensureInitialized();
    await _multiLevelQuoteBox.delete(id);
  }

  // Statistics and analytics
  Future<Map<String, dynamic>> getDashboardStats() async {
    _ensureInitialized();

    final customers = await getAllCustomers();
    final quotes = await getAllQuotes();
    final products = await getAllProducts();

    final totalRevenue = quotes
        .where((q) => q.status == 'accepted')
        .fold(0.0, (sum, quote) => sum + quote.total);

    final pendingQuotes = quotes.where((q) => q.status == 'sent').length;
    final draftQuotes = quotes.where((q) => q.status == 'draft').length;

    return {
      'totalCustomers': customers.length,
      'totalQuotes': quotes.length,
      'totalProducts': products.length,
      'totalRevenue': totalRevenue,
      'pendingQuotes': pendingQuotes,
      'draftQuotes': draftQuotes,
      'acceptedQuotes': quotes.where((q) => q.status == 'accepted').length,
      'declinedQuotes': quotes.where((q) => q.status == 'declined').length,
    };
  }

  // Search operations
  Future<List<Customer>> searchCustomers(String query) async {
    _ensureInitialized();

    if (query.isEmpty) return getAllCustomers();

    final customers = await getAllCustomers();
    return customers.where((customer) =>
    customer.name.toLowerCase().contains(query.toLowerCase()) ||
        (customer.phone?.contains(query) ?? false) ||
        (customer.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        (customer.address?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    _ensureInitialized();

    if (query.isEmpty) return getAllProducts();

    final products = await getAllProducts();
    return products.where((product) =>
    product.name.toLowerCase().contains(query.toLowerCase()) ||
        (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        product.category.toLowerCase().contains(query.toLowerCase()) ||
        (product.sku?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  // Backup and restore
  Future<Map<String, dynamic>> exportAllData() async {
    _ensureInitialized();

    return {
      'customers': (await getAllCustomers()).map((c) => c.toMap()).toList(),
      'products': (await getAllProducts()).map((p) => p.toMap()).toList(),
      'quotes': (await getAllQuotes()).map((q) => q.toMap()).toList(),
      'roofScopeData': (await getAllRoofScopeData()).map((r) => r.toMap()).toList(),
      'projectMedia': (await getAllProjectMedia()).map((m) => m.toMap()).toList(),
      'multiLevelQuotes': (await getAllMultiLevelQuotes()).map((q) => q.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      // Clear existing data
      await _customerBox.clear();
      await _productBox.clear();
      await _quoteBox.clear();
      await _roofScopeBox.clear();
      await _mediaBox.clear();
      await _multiLevelQuoteBox.clear();

      // Import customers
      if (data['customers'] != null) {
        for (final customerData in data['customers']) {
          final customer = Customer.fromMap(customerData);
          await saveCustomer(customer);
        }
      }

      // Import products
      if (data['products'] != null) {
        for (final productData in data['products']) {
          final product = Product.fromMap(productData);
          await saveProduct(product);
        }
      }

      // Import quotes
      if (data['quotes'] != null) {
        for (final quoteData in data['quotes']) {
          final quote = Quote.fromMap(quoteData);
          await saveQuote(quote);
        }
      }

      // Import RoofScope data
      if (data['roofScopeData'] != null) {
        for (final roofData in data['roofScopeData']) {
          final roofScopeData = RoofScopeData.fromMap(roofData);
          await saveRoofScopeData(roofScopeData);
        }
      }

      // Import project media
      if (data['projectMedia'] != null) {
        for (final mediaData in data['projectMedia']) {
          final media = ProjectMedia.fromMap(mediaData);
          await saveProjectMedia(media);
        }
      }

      // Import multi-level quotes
      if (data['multiLevelQuotes'] != null) {
        for (final quoteData in data['multiLevelQuotes']) {
          final quote = MultiLevelQuote.fromMap(quoteData);
          await saveMultiLevelQuote(quote);
        }
      }

      print('Data import completed successfully');
    } catch (e) {
      print('Error importing data: $e');
      rethrow;
    }
  }

  // Close database
  Future<void> close() async {
    if (!_isInitialized) return;

    await _customerBox.close();
    await _productBox.close();
    await _quoteBox.close();
    await _roofScopeBox.close();
    await _mediaBox.close();
    await _settingsBox.close();
    await _multiLevelQuoteBox.close();

    _isInitialized = false;
  }
}

