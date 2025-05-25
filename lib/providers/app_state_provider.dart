// lib/providers/app_state_provider.dart

import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/product.dart';
// import '../models/quote.dart'; // OLD - QuoteItem is now imported by simplified_quote.dart
// import '../models/multi_level_quote.dart' as old_mlq; // OLD - REMOVED
import '../models/simplified_quote.dart'; // NEW - Primary quote model
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PdfService _pdfService = PdfService();

  List<Customer> _customers = [];
  List<Product> _products = [];
  AppSettings? _appSettings;
  List<SimplifiedMultiLevelQuote> _simplifiedQuotes = []; // Primary quote list
  List<RoofScopeData> _roofScopeDataList = [];
  List<ProjectMedia> _projectMedia = [];

  // OLD Quote System data - for temporary access or migration


  bool _isLoading = false;
  String _loadingMessage = '';

  // Getters
  List<Customer> get customers => _customers;
  List<Product> get products => _products;
  AppSettings? get appSettings => _appSettings;
  List<SimplifiedMultiLevelQuote> get simplifiedQuotes => _simplifiedQuotes;
  List<RoofScopeData> get roofScopeDataList => _roofScopeDataList;
  List<ProjectMedia> get projectMedia => _projectMedia;

  @Deprecated('Use simplifiedQuotes. This will be removed.')

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  AppStateProvider() {
    // Constructor can be used for initial setup if not relying on external initializeApp calls
    // For instance, if initializeApp is called right after creating the provider instance.
  }

  Future<void> initializeApp() async {
    setLoading(true, 'Initializing app data...');
    // DatabaseService.instance.init() should have been called in main.dart *before* this provider is created or initializeApp is called.
    await _loadAppSettings();
    await loadAllData(); // This will load data using the already initialized DB
    setLoading(false);
  }

  void setLoading(bool loading, [String message = '']) {
    if (_isLoading == loading && _loadingMessage == message) return; // Avoid redundant notifications
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  Future<void> _loadAppSettings() async {
    try {
      _appSettings = await _db.getAppSettings(); // getAppSettings now handles default creation
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading app settings: $e');
    }
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    try {
      await _db.saveAppSettings(settings);
      _appSettings = settings; // Update local copy
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error updating app settings: $e');
    }
  }

  Future<void> loadAllData() async {
    setLoading(true, 'Loading data...');
    try {
      _customers = await _db.getAllCustomers();
      _products = await _db.getAllProducts();
      _simplifiedQuotes = await _db.getAllSimplifiedMultiLevelQuotes();
      _roofScopeDataList = await _db.getAllRoofScopeData();
      _projectMedia = await _db.getAllProjectMedia();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading all data: $e');
    } finally {
      setLoading(false);
    }
  }

  // --- Customer Operations ---
  Future<void> addCustomer(Customer customer) async {
    await _db.saveCustomer(customer);
    _customers.add(customer);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.saveCustomer(customer);
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) _customers[index] = customer;
    notifyListeners();
  }

  Future<void> deleteCustomer(String customerId) async {
    // Cascade delete related SimplifiedMultiLevelQuotes
    final quotesToDelete = _simplifiedQuotes.where((q) => q.customerId == customerId).toList();
    for (final quote in quotesToDelete) {
      await deleteSimplifiedQuote(quote.id); // This will also handle DB deletion
    }
    // Cascade delete RoofScopeData
    final roofScopesToDelete = _roofScopeDataList.where((rs) => rs.customerId == customerId).toList();
    for (final scope in roofScopesToDelete) {
      await deleteRoofScopeData(scope.id);
    }
    // Cascade delete ProjectMedia
    final mediaToDelete = _projectMedia.where((pm) => pm.customerId == customerId).toList();
    for (final media in mediaToDelete) {
      await deleteProjectMedia(media.id);
    }

    await _db.deleteCustomer(customerId);
    _customers.removeWhere((c) => c.id == customerId);
    notifyListeners();
  }

  // --- Product Operations ---
  Future<void> addProduct(Product product) async {
    await _db.saveProduct(product);
    _products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db.saveProduct(product);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) _products[index] = product;
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _db.deleteProduct(productId);
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }
  Future<void> importProducts(List<Product> productsToImport) async {
    setLoading(true, 'Importing products...');
    try {
      for (final product in productsToImport) {
        final existingIndex = _products.indexWhere((p) => p.name.toLowerCase() == product.name.toLowerCase());
        if (existingIndex != -1) {
          _products[existingIndex].updateInfo( /* update relevant fields from imported product */ );
          await _db.saveProduct(_products[existingIndex]);
        } else {
          await _db.saveProduct(product);
          _products.add(product);
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error importing products: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }


  // --- SimplifiedMultiLevelQuote Operations ---
  Future<void> addSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    await _db.saveSimplifiedMultiLevelQuote(quote);
    _simplifiedQuotes.add(quote);
    notifyListeners();
  }

  Future<void> updateSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    quote.updatedAt = DateTime.now();
    await _db.saveSimplifiedMultiLevelQuote(quote);
    final index = _simplifiedQuotes.indexWhere((q) => q.id == quote.id);
    if (index != -1) _simplifiedQuotes[index] = quote;
    notifyListeners();
  }

  Future<void> deleteSimplifiedQuote(String quoteId) async {
    // Also delete associated media if any
    final mediaForQuote = _projectMedia.where((m) => m.quoteId == quoteId).toList();
    for(var media in mediaForQuote){
      await deleteProjectMedia(media.id); // This handles DB and list removal
    }
    await _db.deleteSimplifiedMultiLevelQuote(quoteId);
    _simplifiedQuotes.removeWhere((q) => q.id == quoteId);
    notifyListeners();
  }

  List<SimplifiedMultiLevelQuote> getSimplifiedQuotesForCustomer(String customerId) {
    return _simplifiedQuotes.where((q) => q.customerId == customerId).toList();
  }

  Future<String> generateSimplifiedQuotePdf(SimplifiedMultiLevelQuote quote, Customer customer, {String? selectedLevelId, List<String>? selectedAddonIds}) async {
    // Pass selectedLevelId and selectedAddonIds to PDF service if PDF needs to reflect a specific configuration
    return await _pdfService.generateSimplifiedMultiLevelQuotePdf(quote, customer, selectedLevelId: selectedLevelId, selectedAddonIds: selectedAddonIds);
  }


  // --- RoofScopeData Operations ---
  Future<void> addRoofScopeData(RoofScopeData data) async {
    await _db.saveRoofScopeData(data);
    _roofScopeDataList.add(data);
    notifyListeners();
  }
  Future<void> updateRoofScopeData(RoofScopeData data) async {
    await _db.saveRoofScopeData(data);
    final index = _roofScopeDataList.indexWhere((r) => r.id == data.id);
    if (index != -1) _roofScopeDataList[index] = data;
    notifyListeners();
  }
  Future<void> deleteRoofScopeData(String dataId) async {
    await _db.deleteRoofScopeData(dataId);
    _roofScopeDataList.removeWhere((r) => r.id == dataId);
    notifyListeners();
  }
  List<RoofScopeData> getRoofScopeDataForCustomer(String customerId) {
    return _roofScopeDataList.where((r) => r.customerId == customerId).toList();
  }
  Future<RoofScopeData?> extractRoofScopeFromPdf(String filePath, String customerId) async {
    setLoading(true, 'Extracting RoofScope data...');
    try {
      final data = await _pdfService.extractRoofScopeData(filePath, customerId);
      if (data != null) {
        final existingData = _roofScopeDataList.any((rs) => rs.customerId == customerId && rs.sourceFileName == data.sourceFileName);
        if (!existingData) {
          await addRoofScopeData(data);
        } else {
          if (kDebugMode) print('RoofScope data for $customerId from ${data.sourceFileName} already exists.');
        }
      }
      return data;
    } catch (e) {
      if (kDebugMode) print('Error extracting RoofScope data: $e'); rethrow;
    } finally {
      setLoading(false);
    }
  }

  // --- ProjectMedia Operations ---
  Future<void> addProjectMedia(ProjectMedia media) async {
    await _db.saveProjectMedia(media);
    _projectMedia.add(media);
    notifyListeners();
  }
  Future<void> updateProjectMedia(ProjectMedia media) async {
    await _db.saveProjectMedia(media);
    final index = _projectMedia.indexWhere((m) => m.id == media.id);
    if (index != -1) _projectMedia[index] = media;
    notifyListeners();
  }
  Future<void> deleteProjectMedia(String mediaId) async {
    await _db.deleteProjectMedia(mediaId);
    _projectMedia.removeWhere((m) => m.id == mediaId);
    notifyListeners();
  }
  List<ProjectMedia> getProjectMediaForCustomer(String customerId) {
    return _projectMedia.where((m) => m.customerId == customerId).toList();
  }
  List<ProjectMedia> getProjectMediaForQuote(String quoteId) {
    return _projectMedia.where((m) => m.quoteId == quoteId).toList();
  }


  // --- Search Operations (Example - can be expanded) ---
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final lowerQuery = query.toLowerCase();
    return _customers.where((c) => c.name.toLowerCase().contains(lowerQuery) || (c.phone?.contains(lowerQuery) ?? false)).toList();
  }
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products.where((p) => p.name.toLowerCase().contains(lowerQuery) || (p.category.toLowerCase().contains(lowerQuery))).toList();
  }
  List<SimplifiedMultiLevelQuote> searchSimplifiedQuotes(String query) {
    if (query.isEmpty) return _simplifiedQuotes;
    final lowerQuery = query.toLowerCase();
    return _simplifiedQuotes.where((q) {
      final customer = _customers.firstWhere((c) => c.id == q.customerId, orElse: () => Customer(name: ""));
      return q.quoteNumber.toLowerCase().contains(lowerQuery) || customer.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // --- Dashboard Statistics (Example) ---
  Map<String, dynamic> getDashboardStats() {
    double totalRevenue = 0;
    for (var quote in _simplifiedQuotes) {
      if (quote.status.toLowerCase() == 'accepted' && quote.levels.isNotEmpty) {
        // Business logic: assume the 'best' (highest subtotal) accepted level, or a specifically marked 'acceptedLevelId' on the quote
        var acceptedLevelSubtotal = quote.levels.map((l) => l.subtotal).reduce((max, e) => e > max ? e : max);
        // This needs more nuanced logic if addons also contribute to accepted revenue
        totalRevenue += acceptedLevelSubtotal; // Simplified for now
      }
    }
    return {
      'totalCustomers': _customers.length,
      'totalQuotes': _simplifiedQuotes.length,
      'totalProducts': _products.length,
      'totalRevenue': totalRevenue,
      'draftQuotes': _simplifiedQuotes.where((q) => q.status.toLowerCase() == 'draft').length,
      'sentQuotes': _simplifiedQuotes.where((q) => q.status.toLowerCase() == 'sent').length,
      'acceptedQuotes': _simplifiedQuotes.where((q) => q.status.toLowerCase() == 'accepted').length,
    };
  }

// Add other legacy methods if absolutely needed for a UI piece you haven't refactored yet.
}