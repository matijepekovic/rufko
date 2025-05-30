// lib/services/database_service.dart - UPDATED FOR ENHANCED MODELS

import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:convert';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/app_settings.dart';
import '../models/simplified_quote.dart'; // Enhanced quote model with discounts
import 'package:flutter/foundation.dart';
import '../models/pdf_template.dart';
import '../models/custom_app_data.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  static DatabaseService get instance => _instance;

  // Hive boxes
  late Box<CustomAppDataField> _customAppDataFieldBox;
  late Box<Customer> _customerBox;
  late Box<Product> _productBox;
  late Box<SimplifiedMultiLevelQuote> _simplifiedQuoteBox;
  late Box<RoofScopeData> _roofScopeBox;
  late Box<ProjectMedia> _mediaBox;
  late Box<AppSettings> _settingsBox;
  late Box<PDFTemplate> _pdfTemplateBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _customerBox = await Hive.openBox<Customer>('customers');
      _productBox = await Hive.openBox<Product>('products');
      _simplifiedQuoteBox = await Hive.openBox<SimplifiedMultiLevelQuote>('simplified_quotes_v3'); // Updated version for enhanced features
      _roofScopeBox = await Hive.openBox<RoofScopeData>('roofscope_data');
      _mediaBox = await Hive.openBox<ProjectMedia>('project_media');
      _settingsBox = await Hive.openBox<AppSettings>('app_settings');
      _pdfTemplateBox = await Hive.openBox<PDFTemplate>('pdf_templates');
      _customAppDataFieldBox = await Hive.openBox<CustomAppDataField>('custom_app_data_fields');
      _isInitialized = true;
      if (kDebugMode) {
        print('Database initialized successfully with enhanced models');
        print('- Customers: ${_customerBox.length}');
        print('- Products: ${_productBox.length}');
        print('- Quotes: ${_simplifiedQuoteBox.length}');
        print('- RoofScope Data: ${_roofScopeBox.length}');
        print('- Media Files: ${_mediaBox.length}');
        print('- Settings: ${_settingsBox.length}');
        print('- PDF Templates: ${_pdfTemplateBox.length}');
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

  // --- Enhanced Product Operations ---
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
    return _productBox.values.toList();
  }

  Future<List<Product>> getActiveProducts() async {
    _ensureInitialized();
    return _productBox.values.where((product) => product.isActive).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    _ensureInitialized();
    return _productBox.values
        .where((product) => product.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  Future<void> savePDFTemplate(PDFTemplate template) async {
    _ensureInitialized();
    await _pdfTemplateBox.put(template.id, template);
  }

  Future<PDFTemplate?> getPDFTemplate(String id) async {
    _ensureInitialized();
    return _pdfTemplateBox.get(id);
  }

  Future<List<PDFTemplate>> getAllPDFTemplates() async {
    _ensureInitialized();
    return _pdfTemplateBox.values.toList();
  }

  Future<List<PDFTemplate>> getActivePDFTemplates() async {
    _ensureInitialized();
    return _pdfTemplateBox.values.where((template) => template.isActive).toList();
  }

  Future<List<PDFTemplate>> getPDFTemplatesByType(String templateType) async {
    _ensureInitialized();
    return _pdfTemplateBox.values
        .where((template) => template.templateType.toLowerCase() == templateType.toLowerCase())
        .toList();
  }

  Future<void> deletePDFTemplate(String id) async {
    _ensureInitialized();
    await _pdfTemplateBox.delete(id);
  }

  Future<void> toggleTemplateActive(String templateId) async {
    _ensureInitialized();
    final template = _pdfTemplateBox.get(templateId);
    if (template != null) {
      template.isActive = !template.isActive;
      template.updatedAt = DateTime.now();
      await template.save();
    }
  }

  // --- Custom App Data Field Operations ---
  Future<void> saveCustomAppDataField(CustomAppDataField field) async {
    _ensureInitialized();
    await _customAppDataFieldBox.put(field.id, field);
  }

  Future<CustomAppDataField?> getCustomAppDataField(String fieldId) async {
    _ensureInitialized();
    return _customAppDataFieldBox.get(fieldId);
  }

  Future<List<CustomAppDataField>> getAllCustomAppDataFields() async {
    _ensureInitialized();
    return _customAppDataFieldBox.values.toList();
  }

  Future<void> deleteCustomAppDataField(String fieldId) async {
    _ensureInitialized();
    await _customAppDataFieldBox.delete(fieldId);
  }

  Future<List<CustomAppDataField>> getCustomAppDataFieldsByCategory(String category) async {
    _ensureInitialized();
    return _customAppDataFieldBox.values
        .where((field) => field.category == category)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> saveMultipleCustomAppDataFields(List<CustomAppDataField> fields) async {
    _ensureInitialized();
    final Map<String, CustomAppDataField> fieldsMap = {
      for (var field in fields) field.id: field
    };
    await _customAppDataFieldBox.putAll(fieldsMap);
  }

  Future<void> clearAllCustomAppDataFields() async {
    _ensureInitialized();
    await _customAppDataFieldBox.clear();
  }
  // --- END OF Custom App Data Field Operations ---


// Search templates
  Future<List<PDFTemplate>> searchPDFTemplates(String query) async {
    _ensureInitialized();
    if (query.isEmpty) return await getAllPDFTemplates();

    final lowerQuery = query.toLowerCase();
    return _pdfTemplateBox.values.where((template) =>
    template.templateName.toLowerCase().contains(lowerQuery) ||
        template.description.toLowerCase().contains(lowerQuery) ||
        template.templateType.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<List<Product>> getDiscountableProducts() async {
    _ensureInitialized();
    return _productBox.values.where((product) => product.isDiscountable).toList();
  }

  Future<List<Product>> getAddonProducts() async {
    _ensureInitialized();
    return _productBox.values.where((product) => product.isAddon).toList();
  }

  Future<void> deleteProduct(String id) async {
    _ensureInitialized();
    await _productBox.delete(id);
  }

  // Bulk product operations
  Future<void> bulkUpdateProductPrices(Map<String, double> priceUpdates) async {
    _ensureInitialized();
    for (final entry in priceUpdates.entries) {
      final product = _productBox.get(entry.key);
      if (product != null) {
        product.updateInfo(unitPrice: entry.value);
      }
    }
  }

  Future<void> toggleProductDiscountable(String productId) async {
    _ensureInitialized();
    final product = _productBox.get(productId);
    if (product != null) {
      product.updateInfo(isDiscountable: !product.isDiscountable);
    }
  }

  // --- Enhanced SimplifiedMultiLevelQuote Operations ---
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

  Future<List<SimplifiedMultiLevelQuote>> getQuotesByStatus(String status) async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values
        .where((quote) => quote.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  Future<List<SimplifiedMultiLevelQuote>> getQuotesByCustomer(String customerId) async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values
        .where((quote) => quote.customerId == customerId)
        .toList();
  }

  Future<List<SimplifiedMultiLevelQuote>> getExpiredQuotes() async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values.where((quote) => quote.isExpired).toList();
  }

  Future<List<SimplifiedMultiLevelQuote>> getQuotesWithDiscounts() async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values
        .where((quote) => quote.discounts.isNotEmpty)
        .toList();
  }

  Future<void> deleteSimplifiedMultiLevelQuote(String id) async {
    _ensureInitialized();
    await _simplifiedQuoteBox.delete(id);
  }

  // Quote analytics
  Future<Map<String, dynamic>> getQuoteAnalytics() async {
    _ensureInitialized();
    final quotes = _simplifiedQuoteBox.values.toList();

    double totalRevenue = 0;
    int totalDiscountsApplied = 0;
    double totalDiscountAmount = 0;

    final statusCounts = <String, int>{};

    for (final quote in quotes) {
      // Count by status
      statusCounts[quote.status] = (statusCounts[quote.status] ?? 0) + 1;

      if (quote.status.toLowerCase() == 'accepted' && quote.levels.isNotEmpty) {
        // Calculate revenue from accepted quotes (use first level as default)
        totalRevenue += quote.getDisplayTotalForLevel(quote.levels.first.id);
      }

      // Count discounts
      if (quote.discounts.isNotEmpty) {
        totalDiscountsApplied += quote.discounts.length;

        // Calculate total discount amounts
        for (final level in quote.levels) {
          final summary = quote.getDiscountSummary(level.id);
          totalDiscountAmount += summary['totalDiscount'] as double;
        }
      }
    }

    return {
      'totalQuotes': quotes.length,
      'totalRevenue': totalRevenue,
      'statusCounts': statusCounts,
      'totalDiscountsApplied': totalDiscountsApplied,
      'totalDiscountAmount': totalDiscountAmount,
      'averageQuoteValue': quotes.isNotEmpty ? totalRevenue / quotes.length : 0.0,
    };
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

  Future<List<RoofScopeData>> getRoofScopeDataByCustomer(String customerId) async {
    _ensureInitialized();
    return _roofScopeBox.values
        .where((data) => data.customerId == customerId)
        .toList();
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

  Future<List<ProjectMedia>> getProjectMediaByCustomer(String customerId) async {
    _ensureInitialized();
    return _mediaBox.values
        .where((media) => media.customerId == customerId)
        .toList();
  }

  Future<List<ProjectMedia>> getProjectMediaByQuote(String quoteId) async {
    _ensureInitialized();
    return _mediaBox.values
        .where((media) => media.quoteId == quoteId)
        .toList();
  }

  Future<void> deleteProjectMedia(String id) async {
    _ensureInitialized();
    await _mediaBox.delete(id);
  }

  Future<void> deleteProjectMediaByQuoteId(String quoteId) async {
    _ensureInitialized();
    final keysToDelete = _mediaBox.values
        .where((media) => media.quoteId == quoteId)
        .map((media) => media.key as String)
        .toList();
    await _mediaBox.deleteAll(keysToDelete);
  }

  // --- Enhanced AppSettings Operations ---
  Future<AppSettings?> getAppSettings() async {
    _ensureInitialized();
    if (_settingsBox.isEmpty) {
      // Create and save default enhanced settings
      final defaultSettings = AppSettings(
        id: 'singleton_app_settings',
        productCategories: ['Materials', 'Roofing', 'Gutters', 'Flashing', 'Labor', 'Other'],
        productUnits: ['sq ft', 'lin ft', 'each', 'hour', 'day', 'bundle', 'roll', 'sheet'],
        defaultUnit: 'sq ft',
        defaultQuoteLevelNames: ['Basic', 'Standard', 'Premium'],
        taxRate: 0.0,
        discountTypes: ['percentage', 'fixed_amount', 'voucher'],
        allowProductDiscountToggle: true,
        defaultDiscountLimit: 25.0,
      );
      await saveAppSettings(defaultSettings);
      return defaultSettings;
    }
    return _settingsBox.values.first;
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    _ensureInitialized();
    if (_settingsBox.isEmpty) {
      await _settingsBox.add(settings);
    } else {
      await _settingsBox.putAt(0, settings);
    }
  }

  // --- Backup and Restore with Enhanced Data ---
  Future<Map<String, dynamic>> exportAllData() async {
    _ensureInitialized();

    // Export PDF template files as base64
    final pdfTemplates = await getAllPDFTemplates();
    final pdfTemplatesWithFiles = <Map<String, dynamic>>[];

    for (final template in pdfTemplates) {
      final templateMap = template.toMap();
      try {
        final file = File(template.pdfFilePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          templateMap['pdfFileContent'] = base64Encode(bytes);
          templateMap['originalFileName'] = file.path.split('/').last;
          if (kDebugMode) print('📦 Exported PDF file: ${template.templateName} (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
        } else {
          if (kDebugMode) print('⚠️ PDF file not found for template: ${template.templateName}');
          templateMap['pdfFileContent'] = null;
        }
      } catch (e) {
        if (kDebugMode) print('❌ Error reading PDF file for ${template.templateName}: $e');
        templateMap['pdfFileContent'] = null;
      }
      pdfTemplatesWithFiles.add(templateMap);
    }

    return {
      'customers': (await getAllCustomers()).map((c) => c.toMap()).toList(),
      'products': (await getAllProducts()).map((p) => p.toMap()).toList(),
      'simplified_quotes': (await getAllSimplifiedMultiLevelQuotes()).map((q) => q.toMap()).toList(),
      'roofScopeData': (await getAllRoofScopeData()).map((r) => r.toMap()).toList(),
      'projectMedia': (await getAllProjectMedia()).map((m) => m.toMap()).toList(),
      'pdfTemplates': pdfTemplatesWithFiles, // Now includes actual PDF files
      'customAppDataFields': (await getAllCustomAppDataFields()).map((f) => f.toMap()).toList(), // ADDED
      'appSettings': (await getAppSettings())?.toMap(),
      'analytics': await getQuoteAnalytics(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '2.2', // Updated version for complete export
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    _ensureInitialized();
    try {
      // Clear existing data
      await _customerBox.clear();
      await _productBox.clear();
      await _simplifiedQuoteBox.clear();
      await _roofScopeBox.clear();
      await _mediaBox.clear();
      await _settingsBox.clear();
      await _pdfTemplateBox.clear();
      await _customAppDataFieldBox.clear(); // ADDED: Clear custom fields

      // Import customers
      if (data['customers'] != null) {
        for (final itemData in data['customers']) {
          await saveCustomer(Customer.fromMap(itemData));
        }
      }

      // Import products with enhanced features
      if (data['products'] != null) {
        for (final itemData in data['products']) {
          await saveProduct(Product.fromMap(itemData));
        }
      }

      // Import enhanced quotes
      if (data['simplified_quotes'] != null) {
        for (final itemData in data['simplified_quotes']) {
          await saveSimplifiedMultiLevelQuote(SimplifiedMultiLevelQuote.fromMap(itemData));
        }
      }

      // Import other data
      if (data['roofScopeData'] != null) {
        for (final itemData in data['roofScopeData']) {
          await saveRoofScopeData(RoofScopeData.fromMap(itemData));
        }
      }

      if (data['projectMedia'] != null) {
        for (final itemData in data['projectMedia']) {
          await saveProjectMedia(ProjectMedia.fromMap(itemData));
        }
      }

      if (data['appSettings'] != null) {
        await saveAppSettings(AppSettings.fromMap(data['appSettings']));
      }

      // ADDED: Import custom app data fields
      if (data['customAppDataFields'] != null) {
        for (final itemData in data['customAppDataFields']) {
          await saveCustomAppDataField(CustomAppDataField.fromMap(itemData));
        }
        if (kDebugMode) print('✅ Imported ${data['customAppDataFields'].length} custom app data fields');
      }

      // ENHANCED: Import PDF templates with actual files
      if (data['pdfTemplates'] != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final templatesDir = Directory('${appDir.path}/templates');
        if (!await templatesDir.exists()) {
          await templatesDir.create(recursive: true);
        }

        for (final itemData in data['pdfTemplates']) {
          try {
            // Create template from metadata
            final template = PDFTemplate.fromMap(itemData);

            // Restore PDF file if included
            if (itemData['pdfFileContent'] != null) {
              final base64Content = itemData['pdfFileContent'] as String;
              final fileBytes = base64Decode(base64Content);

              // Generate new filename
              final originalFileName = itemData['originalFileName'] ?? 'imported_template.pdf';
              final newFileName = '${DateTime.now().millisecondsSinceEpoch}_$originalFileName';
              final newPath = '${templatesDir.path}/$newFileName';

              // Write file to disk
              final file = File(newPath);
              await file.writeAsBytes(fileBytes);

              // Update template path to new location
              template.pdfFilePath = newPath;
              template.updatedAt = DateTime.now();

              if (kDebugMode) print('📄 Restored PDF file: ${template.templateName} to $newPath');
            } else {
              if (kDebugMode) print('⚠️ No PDF file content for template: ${template.templateName}');
            }

            await savePDFTemplate(template);
          } catch (e) {
            if (kDebugMode) print('❌ Error importing PDF template: $e');
          }
        }
        if (kDebugMode) print('✅ Imported ${data['pdfTemplates'].length} PDF templates');
      }

      if (kDebugMode) {
        print('🎉 COMPLETE data import finished successfully');
        print('Imported version: ${data['version'] ?? 'legacy'}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error importing complete data: $e');
      }
      rethrow;
    }
  }

  // --- Search Operations ---
  Future<List<Product>> searchProducts(String query) async {
    _ensureInitialized();
    if (query.isEmpty) return await getAllProducts();

    final lowerQuery = query.toLowerCase();
    return _productBox.values.where((product) =>
    product.name.toLowerCase().contains(lowerQuery) ||
        product.category.toLowerCase().contains(lowerQuery) ||
        (product.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        (product.sku?.toLowerCase().contains(lowerQuery) ?? false) ||
        product.activeLevels.any((level) => level.levelName.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  Future<List<SimplifiedMultiLevelQuote>> searchQuotes(String query) async {
    _ensureInitialized();
    if (query.isEmpty) return await getAllSimplifiedMultiLevelQuotes();

    final lowerQuery = query.toLowerCase();
    return _simplifiedQuoteBox.values.where((quote) =>
    quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
        quote.status.toLowerCase().contains(lowerQuery) ||
        (quote.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
        quote.levels.any((level) => level.name.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  // --- Maintenance Operations ---
  Future<void> compactDatabase() async {
    _ensureInitialized();
    try {
      await _customerBox.compact();
      await _productBox.compact();
      await _simplifiedQuoteBox.compact();
      await _roofScopeBox.compact();
      await _mediaBox.compact();
      await _settingsBox.compact();
      await _pdfTemplateBox.compact(); // NEW

      if (kDebugMode) {
        print('Database compaction completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during database compaction: $e');
      }
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    _ensureInitialized();
    return {
      'customers': _customerBox.length,
      'products': _productBox.length,
      'quotes': _simplifiedQuoteBox.length,
      'roofScopeData': _roofScopeBox.length,
      'projectMedia': _mediaBox.length,
      'pdfTemplates': _pdfTemplateBox.length, // NEW
      'settings': _settingsBox.length,
    };
  }
  Future<void> close() async {
    if (!_isInitialized) return;
    await Hive.close();
    _isInitialized = false;
    if (kDebugMode) {
      print('Database closed');
    }
  }
}