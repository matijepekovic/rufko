import 'package:flutter/foundation.dart';
import '../../models/business/customer.dart';
import '../../models/business/product.dart';
import '../../models/business/simplified_quote.dart';
import '../../models/business/roof_scope_data.dart';
import '../../../core/services/database/database_service.dart';
import '../helpers/roof_scope_helper.dart';

class BusinessDomainCoordinator extends ChangeNotifier {
  final DatabaseService _db;
  
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<SimplifiedMultiLevelQuote> _quotes = [];
  List<RoofScopeData> _roofScopeDataList = [];

  BusinessDomainCoordinator({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  // Getters
  List<Customer> get customers => _customers;
  List<Product> get products => _products;
  List<SimplifiedMultiLevelQuote> get simplifiedQuotes => _quotes;
  List<RoofScopeData> get roofScopeDataList => _roofScopeDataList;

  // Load Operations
  Future<void> loadBusinessData() async {
    await Future.wait([
      loadCustomers(),
      loadProducts(),
      loadQuotes(),
      loadRoofScopeData(),
    ]);
  }

  Future<void> loadCustomers() async {
    _customers = await _db.getAllCustomers();
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _products = await _db.getAllProducts();
    notifyListeners();
  }

  Future<void> loadQuotes() async {
    _quotes = await _db.getAllSimplifiedMultiLevelQuotes();
    notifyListeners();
  }

  Future<void> loadRoofScopeData() async {
    _roofScopeDataList = await _db.getAllRoofScopeData();
    notifyListeners();
  }

  // Customer Operations
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
    await _db.deleteCustomer(customerId);
    _customers.removeWhere((c) => c.id == customerId);
    _quotes.removeWhere((q) => q.customerId == customerId);
    _roofScopeDataList.removeWhere((r) => r.customerId == customerId);
    notifyListeners();
  }

  // Product Operations
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
    for (final product in productsToImport) {
      await _db.saveProduct(product);
      _products.add(product);
    }
    notifyListeners();
  }

  // Quote Operations
  Future<void> addSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    await _db.saveSimplifiedMultiLevelQuote(quote);
    _quotes.add(quote);
    notifyListeners();
  }

  Future<void> updateSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    await _db.saveSimplifiedMultiLevelQuote(quote);
    final index = _quotes.indexWhere((q) => q.id == quote.id);
    if (index != -1) _quotes[index] = quote;
    notifyListeners();
  }

  Future<void> deleteSimplifiedQuote(String quoteId) async {
    await _db.deleteSimplifiedMultiLevelQuote(quoteId);
    _quotes.removeWhere((q) => q.id == quoteId);
    notifyListeners();
  }

  List<SimplifiedMultiLevelQuote> getSimplifiedQuotesForCustomer(String customerId) {
    return _quotes.where((q) => q.customerId == customerId).toList();
  }

  Future<String> generateSimplifiedQuotePdf(
    SimplifiedMultiLevelQuote quote,
    Customer customer, {
    String? selectedLevelId,
    List<String>? selectedAddonIds,
  }) async {
    // Implementation would go here - delegated to helper
    throw UnimplementedError('PDF generation will be implemented');
  }

  // Roof Scope Operations
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
    try {
      final extractedData = await RoofScopeHelper.extractRoofScopeData(filePath, customerId);
      if (extractedData != null) {
        await addRoofScopeData(extractedData);
      }
      return extractedData;
    } catch (e) {
      if (kDebugMode) debugPrint('Error in extractRoofScopeFromPdf: $e');
      return null;
    }
  }

  // Search Operations
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final lower = query.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            (c.phone?.contains(lower) ?? false))
        .toList();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lower = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(lower) ||
            (p.description?.toLowerCase().contains(lower) ?? false))
        .toList();
  }

  List<SimplifiedMultiLevelQuote> searchSimplifiedQuotes(String query) {
    if (query.isEmpty) return _quotes;
    final lowerQuery = query.toLowerCase();
    return _quotes.where((q) {
      final customer = customers.firstWhere((c) => c.id == q.customerId,
          orElse: () => Customer(name: ""));
      return q.quoteNumber.toLowerCase().contains(lowerQuery) ||
          customer.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Dashboard Statistics
  Map<String, dynamic> getBusinessStats() {
    double totalRevenue = 0;
    for (var quote in _quotes) {
      if (quote.status.toLowerCase() == 'accepted' && quote.levels.isNotEmpty) {
        var acceptedLevelSubtotal = quote.levels
            .map((l) => l.subtotal)
            .reduce((max, e) => e > max ? e : max);
        totalRevenue += acceptedLevelSubtotal;
      }
    }
    return {
      'totalCustomers': customers.length,
      'totalQuotes': _quotes.length,
      'totalProducts': products.length,
      'totalRevenue': totalRevenue,
      'draftQuotes': _quotes
          .where((q) => q.status.toLowerCase() == 'draft')
          .length,
      'sentQuotes': _quotes
          .where((q) => q.status.toLowerCase() == 'sent')
          .length,
      'acceptedQuotes': _quotes
          .where((q) => q.status.toLowerCase() == 'accepted')
          .length,
    };
  }
}