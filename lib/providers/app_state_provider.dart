import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/quote.dart';
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/multi_level_quote.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PdfService _pdfService = PdfService();
  final ExcelService _excelService = ExcelService();

  // State variables
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Quote> _quotes = [];
  List<RoofScopeData> _roofScopeData = [];
  List<ProjectMedia> _projectMedia = [];
  List<MultiLevelQuote> _multiLevelQuotes = [];
  AppSettings? _appSettings;

  bool _isLoading = false;
  String _loadingMessage = '';

  // Getters
  List<Customer> get customers => _customers;
  List<Product> get products => _products;
  List<Quote> get quotes => _quotes;
  List<RoofScopeData> get roofScopeData => _roofScopeData;
  List<ProjectMedia> get projectMedia => _projectMedia;
  List<MultiLevelQuote> get multiLevelQuotes => _multiLevelQuotes;
  AppSettings? get appSettings => _appSettings;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  // Initialize app
  Future<void> initializeApp() async {
    await loadAllData();
    await _loadAppSettings();
  }

  // Set loading state
  void setLoading(bool loading, [String message = '']) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  // Load app settings
  Future<void> _loadAppSettings() async {
    try {
      final settings = await _db.getAppSettings();
      if (settings != null) {
        _appSettings = settings;
      } else {
        // Create default settings if none exist
        _appSettings = AppSettings();
        await _db.saveAppSettings(_appSettings!);
      }
      notifyListeners();
    } catch (e) {
      print('Error loading app settings: $e');
    }
  }

  // Update app settings
  Future<void> updateAppSettings(AppSettings settings) async {
    try {
      await _db.saveAppSettings(settings);
      _appSettings = settings;
      notifyListeners();
    } catch (e) {
      print('Error updating app settings: $e');
    }
  }

  // Load all data
  Future<void> loadAllData() async {
    setLoading(true, 'Loading data...');
    try {
      _customers = await _db.getAllCustomers();
      _products = await _db.getAllProducts();
      _quotes = await _db.getAllQuotes();
      _roofScopeData = await _db.getAllRoofScopeData();
      _projectMedia = await _db.getAllProjectMedia();
      _multiLevelQuotes = await _db.getAllMultiLevelQuotes();

      setLoading(false);
    } catch (e) {
      print('Error loading data: $e');
      setLoading(false);
    }
  }

  // Customer operations
  Future<void> addCustomer(Customer customer) async {
    await _db.saveCustomer(customer);
    _customers.add(customer);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.saveCustomer(customer);
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    // Delete associated data
    final customerQuotes = _quotes.where((q) => q.customerId == customerId).toList();
    for (final quote in customerQuotes) {
      await deleteQuote(quote.id);
    }

    final customerRoofScope = _roofScopeData.where((r) => r.customerId == customerId).toList();
    for (final data in customerRoofScope) {
      await _db.deleteRoofScopeData(data.id);
    }

    final customerMedia = _projectMedia.where((m) => m.customerId == customerId).toList();
    for (final media in customerMedia) {
      await _db.deleteProjectMedia(media.id);
    }

    // Delete customer
    await _db.deleteCustomer(customerId);
    _customers.removeWhere((c) => c.id == customerId);
    _roofScopeData.removeWhere((r) => r.customerId == customerId);
    _projectMedia.removeWhere((m) => m.customerId == customerId);
    notifyListeners();
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    final lowerQuery = query.toLowerCase();
    return _customers.where((customer) =>
    customer.name.toLowerCase().contains(lowerQuery) ||
        (customer.phone?.contains(query) ?? false) ||
        (customer.email?.toLowerCase().contains(lowerQuery) ?? false) ||
        (customer.address?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  // Product operations
  Future<void> addProduct(Product product) async {
    await _db.saveProduct(product);
    _products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db.saveProduct(product);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _db.deleteProduct(productId);
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;

    final lowerQuery = query.toLowerCase();
    return _products.where((product) =>
    product.name.toLowerCase().contains(lowerQuery) ||
        (product.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        product.category.toLowerCase().contains(lowerQuery) ||
        (product.sku?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  Future<void> loadProductsFromExcel(String filePath) async {
    setLoading(true, 'Analyzing Excel file...');
    try {
      setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error during Excel processing initiation: $e');
      setLoading(false);
      rethrow;
    }
  }

  Future<void> importProducts(List<Product> productsToImport) async {
    setLoading(true, 'Importing mapped products...');
    try {
      for (final product in productsToImport) {
        final existingIndex = _products.indexWhere(
                (p) => p.name.toLowerCase() == product.name.toLowerCase() &&
                       p.unit == product.unit
        );

        if (existingIndex != -1) {
          _products[existingIndex].updateInfo(
            description: product.description,
            unitPrice: product.unitPrice,
            unit: product.unit,
            category: product.category,
            sku: product.sku,
            isActive: product.isActive,
            definesLevel: product.definesLevel,
            levelName: product.levelName,
            levelNumber: product.levelNumber,
            levelPrices: product.levelPrices,
            isUpgrade: product.isUpgrade,
            isAddon: product.isAddon,
          );
          await _db.saveProduct(_products[existingIndex]);
        } else {
          if (!product.levelPrices.containsKey('base') && product.levelPrices.isEmpty) {
            product.levelPrices['base'] = product.unitPrice;
          }
          await _db.saveProduct(product);
          _products.add(product);
        }
      }
      setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error importing mapped products: $e');
      setLoading(false);
      rethrow;
    }
  }

  // Quote operations
  Future<void> addQuote(Quote quote) async {
    await _db.saveQuote(quote);
    _quotes.add(quote);
    notifyListeners();
  }

  Future<void> updateQuote(Quote quote) async {
    await _db.saveQuote(quote);
    final index = _quotes.indexWhere((q) => q.id == quote.id);
    if (index != -1) {
      _quotes[index] = quote;
      notifyListeners();
    }
  }

  Future<void> deleteQuote(String quoteId) async {
    final quoteMedia = _projectMedia.where((m) => m.quoteId == quoteId).toList();
    for (final media in quoteMedia) {
      await _db.deleteProjectMedia(media.id);
    }

    await _db.deleteQuote(quoteId);
    _quotes.removeWhere((q) => q.id == quoteId);
    _projectMedia.removeWhere((m) => m.quoteId == quoteId);
    notifyListeners();
  }

  List<Quote> getQuotesForCustomer(String customerId) {
    return _quotes.where((q) => q.customerId == customerId).toList();
  }

  Future<String> generatePdfQuote(Quote quote, Customer customer) async {
    return await _pdfService.generateQuotePdf(quote, customer);
  }

  // MultiLevelQuote operations
  Future<void> addMultiLevelQuote(MultiLevelQuote quote) async {
    await _db.saveMultiLevelQuote(quote);
    _multiLevelQuotes.add(quote);
    notifyListeners();
  }

  Future<void> updateMultiLevelQuote(MultiLevelQuote quote) async {
    await _db.saveMultiLevelQuote(quote);
    final index = _multiLevelQuotes.indexWhere((q) => q.id == quote.id);
    if (index != -1) {
      _multiLevelQuotes[index] = quote;
      notifyListeners();
    }
  }

  Future<void> deleteMultiLevelQuote(String quoteId) async {
    final quoteMedia = _projectMedia.where((m) => m.quoteId == quoteId).toList();
    for (final media in quoteMedia) {
      await _db.deleteProjectMedia(media.id);
    }

    await _db.deleteMultiLevelQuote(quoteId);
    _multiLevelQuotes.removeWhere((q) => q.id == quoteId);
    _projectMedia.removeWhere((m) => m.quoteId == quoteId);
    notifyListeners();
  }

  List<MultiLevelQuote> getMultiLevelQuotesForCustomer(String customerId) {
    return _multiLevelQuotes.where((q) => q.customerId == customerId).toList();
  }

  Future<MultiLevelQuote> createMultiLevelQuoteFromScope(
    String customerId,
    RoofScopeData scopeData,
    List<String> selectedLevels,
  ) async {
    final quote = MultiLevelQuote(
      customerId: customerId,
      roofScopeDataId: scopeData.id,
      taxRate: 0.0,
    );

    final levelDefiningProducts = _products.where((p) =>
      p.definesLevel &&
      p.levelName != null &&
      selectedLevels.contains(p.levelName!.toLowerCase())
    ).toList();

    for (final product in levelDefiningProducts) {
      final levelId = product.levelName!.toLowerCase();
      final levelName = product.levelName!;
      final levelNumber = product.levelNumber ?? selectedLevels.indexOf(levelId) + 1;

      final level = quote.addLevel(
        levelId: levelId,
        levelName: levelName,
        levelNumber: levelNumber,
      );

      level.items.add(QuoteItem(
        productId: product.id,
        productName: product.name,
        quantity: scopeData.numberOfSquares,
        unitPrice: product.getPriceForLevel(levelId),
        unit: product.unit,
        description: product.description,
      ));
    }

    quote.calculateTotals();

    await addMultiLevelQuote(quote);
    return quote;
  }

  Future<String> generateMultiLevelPdfQuote(MultiLevelQuote quote, Customer customer) async {
    return await _pdfService.generateMultiLevelQuotePdf(quote, customer);
  }

  // RoofScope operations
  Future<void> addRoofScopeData(RoofScopeData data) async {
    await _db.saveRoofScopeData(data);
    _roofScopeData.add(data);
    notifyListeners();
  }

  Future<void> updateRoofScopeData(RoofScopeData data) async {
    await _db.saveRoofScopeData(data);
    final index = _roofScopeData.indexWhere((r) => r.id == data.id);
    if (index != -1) {
      _roofScopeData[index] = data;
      notifyListeners();
    }
  }

  Future<void> deleteRoofScopeData(String dataId) async {
    await _db.deleteRoofScopeData(dataId);
    _roofScopeData.removeWhere((r) => r.id == dataId);
    notifyListeners();
  }

  List<RoofScopeData> getRoofScopeDataForCustomer(String customerId) {
    return _roofScopeData.where((r) => r.customerId == customerId).toList();
  }

  Future<RoofScopeData?> extractRoofScopeFromPdf(String filePath, String customerId) async {
    try {
      final data = await _pdfService.extractRoofScopeData(filePath, customerId);
      if (data != null) {
        await addRoofScopeData(data);
      }
      return data;
    } catch (e) {
      print('Error extracting RoofScope data: $e');
      rethrow;
    }
  }

  // Project Media operations
  Future<void> addProjectMedia(ProjectMedia media) async {
    await _db.saveProjectMedia(media);
    _projectMedia.add(media);
    notifyListeners();
  }

  Future<void> updateProjectMedia(ProjectMedia media) async {
    await _db.saveProjectMedia(media);
    final index = _projectMedia.indexWhere((m) => m.id == media.id);
    if (index != -1) {
      _projectMedia[index] = media;
      notifyListeners();
    }
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

  // Dashboard statistics
  Map<String, dynamic> getDashboardStats() {
    final totalRevenue = _quotes
        .where((q) => q.status == 'accepted')
        .fold(0.0, (sum, quote) => sum + quote.total);

    final mlqRevenue = _multiLevelQuotes
        .where((q) => q.status == 'accepted')
        .fold(0.0, (sum, quote) {
          final levelIds = quote.levels.keys.toList();
          if (levelIds.isEmpty) return sum;

          levelIds.sort((a, b) =>
            (quote.levels[b]?.levelNumber ?? 0) -
            (quote.levels[a]?.levelNumber ?? 0)
          );

          return sum + quote.getLevelTotal(levelIds.first);
        });

    final totalQuotes = _quotes.length + _multiLevelQuotes.length;
    final pendingQuotes = _quotes.where((q) => q.status == 'sent').length +
                         _multiLevelQuotes.where((q) => q.status == 'sent').length;
    final draftQuotes = _quotes.where((q) => q.status == 'draft').length +
                       _multiLevelQuotes.where((q) => q.status == 'draft').length;
    final acceptedQuotes = _quotes.where((q) => q.status == 'accepted').length +
                          _multiLevelQuotes.where((q) => q.status == 'accepted').length;
    final declinedQuotes = _quotes.where((q) => q.status == 'declined').length +
                          _multiLevelQuotes.where((q) => q.status == 'declined').length;

    return {
      'totalCustomers': _customers.length,
      'totalQuotes': totalQuotes,
      'totalProducts': _products.length,
      'totalRevenue': totalRevenue + mlqRevenue,
      'pendingQuotes': pendingQuotes,
      'draftQuotes': draftQuotes,
      'acceptedQuotes': acceptedQuotes,
      'declinedQuotes': declinedQuotes,
      'activeQuotes': totalQuotes - declinedQuotes,
    };
  }
}

