// lib/services/database_service.dart - UPDATED FOR ENHANCED MODELS & CATEGORY FIX

import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:convert';
import '../../../data/models/business/customer.dart';
import '../../../data/models/business/product.dart';
import '../../../data/models/business/roof_scope_data.dart';
import '../../../data/models/media/project_media.dart';
import '../../../data/models/settings/app_settings.dart';
import '../../../data/models/business/simplified_quote.dart'; // Enhanced quote model with discounts
import 'package:flutter/foundation.dart';
import '../../../data/models/templates/pdf_template.dart';
import '../../../data/models/settings/custom_app_data.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/templates/message_template.dart';
import '../../../data/models/templates/email_template.dart';
import '../../../data/models/templates/template_category.dart';
import '../../../data/models/media/inspection_document.dart';

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
  late Box<MessageTemplate> _messageTemplateBox;
  late Box<EmailTemplate> _emailTemplateBox;
  late Box<dynamic> _categoriesBox; // MODIFIED: Changed to Box<dynamic>
  late Box<InspectionDocument> _inspectionDocumentBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _customerBox = await Hive.openBox<Customer>('customers');
      _productBox = await Hive.openBox<Product>('products');
      _simplifiedQuoteBox = await Hive.openBox<SimplifiedMultiLevelQuote>('simplified_quotes_v3');
      _roofScopeBox = await Hive.openBox<RoofScopeData>('roofscope_data');
      _mediaBox = await Hive.openBox<ProjectMedia>('project_media');
      _settingsBox = await Hive.openBox<AppSettings>('app_settings');
      _pdfTemplateBox = await Hive.openBox<PDFTemplate>('pdf_templates');
      _customAppDataFieldBox = await Hive.openBox<CustomAppDataField>('custom_app_data_fields');
      _messageTemplateBox = await Hive.openBox<MessageTemplate>('message_templates');
      _emailTemplateBox = await Hive.openBox<EmailTemplate>('email_templates');
      _categoriesBox = await Hive.openBox<dynamic>('template_categories');
      _inspectionDocumentBox = await Hive.openBox<InspectionDocument>('inspection_documents');

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('Database initialized successfully with enhanced models');
        debugPrint('- Customers: ${_customerBox.length}');
        debugPrint('- Products: ${_productBox.length}');
        debugPrint('- Quotes: ${_simplifiedQuoteBox.length}');
        debugPrint('- RoofScope Data: ${_roofScopeBox.length}');
        debugPrint('- Media Files: ${_mediaBox.length}');
        debugPrint('- Settings: ${_settingsBox.length}');
        debugPrint('- PDF Templates: ${_pdfTemplateBox.length}');
        debugPrint('- Message Templates: ${_messageTemplateBox.length}');
        debugPrint('- Email Templates: ${_emailTemplateBox.length}');
        debugPrint('- Template Categories: ${_categoriesBox.length}');
        debugPrint('- Inspection Documents: ${_inspectionDocumentBox.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing database: $e');
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
        .where((product) =>
    product.category.toLowerCase() == category.toLowerCase())
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
    return _pdfTemplateBox.values
        .where((template) => template.isActive)
        .toList();
  }

  Future<List<PDFTemplate>> getPDFTemplatesByType(String templateType) async {
    _ensureInitialized();
    return _pdfTemplateBox.values
        .where((template) =>
    template.templateType.toLowerCase() == templateType.toLowerCase())
        .toList();
  }

  Future<void> deletePDFTemplate(String id) async {
    _ensureInitialized();
    await _pdfTemplateBox.delete(id);
  }

  // --- Message Template Operations ---
  Future<void> saveMessageTemplate(MessageTemplate template) async {
    _ensureInitialized();
    await _messageTemplateBox.put(template.id, template);
  }

  Future<MessageTemplate?> getMessageTemplate(String id) async {
    _ensureInitialized();
    return _messageTemplateBox.get(id);
  }

  Future<List<MessageTemplate>> getAllMessageTemplates() async {
    _ensureInitialized();
    return _messageTemplateBox.values.toList();
  }

  Future<List<MessageTemplate>> getActiveMessageTemplates() async {
    _ensureInitialized();
    return _messageTemplateBox.values
        .where((template) => template.isActive)
        .toList();
  }

  Future<List<MessageTemplate>> getMessageTemplatesByCategory(
      String category) async {
    _ensureInitialized();
    return _messageTemplateBox.values
        .where((template) =>
    template.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  Future<void> deleteMessageTemplate(String id) async {
    _ensureInitialized();
    await _messageTemplateBox.delete(id);
  }

  Future<void> toggleMessageTemplateActive(String templateId) async {
    _ensureInitialized();
    final template = _messageTemplateBox.get(templateId);
    if (template != null) {
      final updatedTemplate = template.copyWith(
        isActive: !template.isActive,
        updatedAt: DateTime.now(),
      );
      await _messageTemplateBox.put(templateId, updatedTemplate);
    }
  }

  Future<List<MessageTemplate>> searchMessageTemplates(String query) async {
    _ensureInitialized();
    if (query.isEmpty) return await getAllMessageTemplates();

    final lowerQuery = query.toLowerCase();
    return _messageTemplateBox.values.where((template) =>
    template.templateName.toLowerCase().contains(lowerQuery) ||
        template.description.toLowerCase().contains(lowerQuery) ||
        template.category.toLowerCase().contains(lowerQuery) ||
        template.messageContent.toLowerCase().contains(lowerQuery)
    ).toList();
  }


  Future<void> toggleTemplateActive(String templateId) async {
    _ensureInitialized();
    final template = _pdfTemplateBox.get(templateId);
    if (template != null) {
      template.isActive = !template.isActive;
      template.updatedAt = DateTime.now();
      await template.save(); // HiveObject's save method
    }
  }

// --- Email Template Operations ---
  Future<void> saveEmailTemplate(EmailTemplate template) async {
    _ensureInitialized();
    await _emailTemplateBox.put(template.id, template);
  }

  Future<EmailTemplate?> getEmailTemplate(String id) async {
    _ensureInitialized();
    return _emailTemplateBox.get(id);
  }

  Future<List<EmailTemplate>> getAllEmailTemplates() async {
    _ensureInitialized();
    return _emailTemplateBox.values.toList();
  }

  Future<List<EmailTemplate>> getActiveEmailTemplates() async {
    _ensureInitialized();
    return _emailTemplateBox.values
        .where((template) => template.isActive)
        .toList();
  }

  Future<List<EmailTemplate>> getEmailTemplatesByCategory(
      String category) async {
    _ensureInitialized();
    return _emailTemplateBox.values
        .where((template) =>
    template.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  Future<void> deleteEmailTemplate(String id) async {
    _ensureInitialized();
    await _emailTemplateBox.delete(id);
  }

  Future<void> toggleEmailTemplateActive(String templateId) async {
    _ensureInitialized();
    final template = _emailTemplateBox.get(templateId);
    if (template != null) {
      final updatedTemplate = template.copyWith(
        isActive: !template.isActive,
        updatedAt: DateTime.now(),
      );
      await _emailTemplateBox.put(templateId, updatedTemplate);
    }
  }

  Future<List<EmailTemplate>> searchEmailTemplates(String query) async {
    _ensureInitialized();
    if (query.isEmpty) return await getAllEmailTemplates();

    final lowerQuery = query.toLowerCase();
    return _emailTemplateBox.values.where((template) =>
    template.templateName.toLowerCase().contains(lowerQuery) ||
        template.description.toLowerCase().contains(lowerQuery) ||
        template.category.toLowerCase().contains(lowerQuery) ||
        template.subject.toLowerCase().contains(lowerQuery) ||
        template.emailContent.toLowerCase().contains(lowerQuery)
    ).toList();
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

  Future<List<CustomAppDataField>> getCustomAppDataFieldsByCategory(
      String category) async {
    _ensureInitialized();
    return _customAppDataFieldBox.values
        .where((field) => field.category == category)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> saveMultipleCustomAppDataFields(
      List<CustomAppDataField> fields) async {
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
    return _productBox.values
        .where((product) => product.isDiscountable)
        .toList();
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
        // No need to call product.save() if updateInfo handles it and it's in a box.
      }
    }
  }

  Future<void> toggleProductDiscountable(String productId) async {
    _ensureInitialized();
    final product = _productBox.get(productId);
    if (product != null) {
      product.updateInfo(isDiscountable: !product.isDiscountable);
      // No need to call product.save() if updateInfo handles it.
    }
  }

  // --- Enhanced SimplifiedMultiLevelQuote Operations ---
  Future<void> saveSimplifiedMultiLevelQuote(
      SimplifiedMultiLevelQuote quote) async {
    _ensureInitialized();
    await _simplifiedQuoteBox.put(quote.id, quote);
  }

  Future<SimplifiedMultiLevelQuote?> getSimplifiedMultiLevelQuote(
      String id) async {
    _ensureInitialized();
    return _simplifiedQuoteBox.get(id);
  }

  Future<List<
      SimplifiedMultiLevelQuote>> getAllSimplifiedMultiLevelQuotes() async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values.toList();
  }

  Future<List<SimplifiedMultiLevelQuote>> getQuotesByStatus(
      String status) async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values
        .where((quote) => quote.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  Future<List<SimplifiedMultiLevelQuote>> getQuotesByCustomer(
      String customerId) async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values
        .where((quote) => quote.customerId == customerId)
        .toList();
  }

  Future<List<SimplifiedMultiLevelQuote>> getExpiredQuotes() async {
    _ensureInitialized();
    return _simplifiedQuoteBox.values
        .where((quote) => quote.isExpired)
        .toList();
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
      'averageQuoteValue': quotes.isNotEmpty
          ? totalRevenue / quotes.length
          : 0.0,
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

  Future<List<RoofScopeData>> getRoofScopeDataByCustomer(
      String customerId) async {
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

  Future<List<ProjectMedia>> getProjectMediaByCustomer(
      String customerId) async {
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
        .map((media) => media.key as String) // HiveObject's key
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
        productCategories: [
          'Materials',
          'Roofing',
          'Gutters',
          'Flashing',
          'Labor',
          'Other'
        ],
        productUnits: [
          'sq ft',
          'lin ft',
          'each',
          'hour',
          'day',
          'bundle',
          'roll',
          'sheet'
        ],
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
          templateMap['originalFileName'] = file.path
              .split('/')
              .last;
          if (kDebugMode) {
            debugPrint(
              '📦 Exported PDF file: ${template.templateName} (${(bytes.length /
                  1024).toStringAsFixed(1)} KB)');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              '⚠️ PDF file not found for template: ${template.templateName}');
          }
          templateMap['pdfFileContent'] = null;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '❌ Error reading PDF file for ${template.templateName}: $e');
        }
        templateMap['pdfFileContent'] = null;
      }
      pdfTemplatesWithFiles.add(templateMap);
    }

    return {
      'customers': (await getAllCustomers()).map((c) => c.toMap()).toList(),
      'products': (await getAllProducts()).map((p) => p.toMap()).toList(),
      'simplified_quotes': (await getAllSimplifiedMultiLevelQuotes()).map((q) =>
          q.toMap()).toList(),
      'roofScopeData': (await getAllRoofScopeData())
          .map((r) => r.toMap())
          .toList(),
      'projectMedia': (await getAllProjectMedia())
          .map((m) => m.toMap())
          .toList(),
      'pdfTemplates': pdfTemplatesWithFiles, // Now includes actual PDF files
      'customAppDataFields': (await getAllCustomAppDataFields()).map((f) =>
          f.toMap()).toList(), // ADDED
      'appSettings': (await getAppSettings())?.toMap(),
      'analytics': await getQuoteAnalytics(),
      'exportDate': DateTime.now().toIso8601String(),
      'inspectionDocuments': (await getAllInspectionDocuments()).map((d) => d.toMap()).toList(),
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
      await _customAppDataFieldBox.clear(); // ADDED: Clear fields
      await _inspectionDocumentBox.clear(); // ADDED: Clear fields
      await _categoriesBox.clear(); // Clear template categories
      await _messageTemplateBox.clear();
      await _emailTemplateBox.clear();


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
          await saveSimplifiedMultiLevelQuote(
              SimplifiedMultiLevelQuote.fromMap(itemData));
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
        if (kDebugMode) {
          debugPrint('✅ Imported ${data['customAppDataFields']
            .length} custom app data fields');
        }
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
              final originalFileName = itemData['originalFileName'] ??
                  'imported_template.pdf';
              final newFileName = '${DateTime
                  .now()
                  .millisecondsSinceEpoch}_$originalFileName';
              final newPath = '${templatesDir.path}/$newFileName';

              // Write file to disk
              final file = File(newPath);
              await file.writeAsBytes(fileBytes);

              // Update template path to new location
              template.pdfFilePath = newPath;
              template.updatedAt = DateTime.now();

              if (kDebugMode) {
                debugPrint(
                  '📄 Restored PDF file: ${template.templateName} to $newPath');
              }
            } else {
              if (kDebugMode) {
                debugPrint(
                  '⚠️ No PDF file content for template: ${template
                      .templateName}');
              }
            }

            await savePDFTemplate(template);
          } catch (e) {
            if (kDebugMode) debugPrint('❌ Error importing PDF template: $e');
          }
        }
        if (kDebugMode) {
          debugPrint(
            '✅ Imported ${data['pdfTemplates'].length} PDF templates');
        }
      }

      // Import Message Templates
      if (data['message_templates'] != null) {
        for (final itemData in data['message_templates']) {
          await saveMessageTemplate(MessageTemplate.fromJson(itemData));
        }
        if (kDebugMode) debugPrint('✅ Imported ${data['message_templates'].length} Message templates');
      }

      // Import Email Templates
      if (data['email_templates'] != null) {
        for (final itemData in data['email_templates']) {
          await saveEmailTemplate(EmailTemplate.fromJson(itemData));
        }
        if (kDebugMode) debugPrint('✅ Imported ${data['email_templates'].length} Email templates');
      }

      // Import Template Categories
      if (data['template_categories'] != null) {
        for (final itemData in data['template_categories']) {
          await _categoriesBox.add(TemplateCategory.fromMap(itemData));
        }
        // Import Inspection Documents
        if (data['inspectionDocuments'] != null) {
          for (final itemData in data['inspectionDocuments']) {
            await saveInspectionDocument(InspectionDocument.fromMap(itemData));
          }
          if (kDebugMode) debugPrint('✅ Imported ${data['inspectionDocuments'].length} Inspection Documents');
        }
        debugPrint('🎉 COMPLETE data import finished successfully');
        debugPrint('Imported version: ${data['version'] ?? 'legacy'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error importing complete data: $e');
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
        product.activeLevels.any((level) =>
            level.levelName.toLowerCase().contains(lowerQuery))
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
        quote.levels.any((level) =>
            level.name.toLowerCase().contains(lowerQuery))
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
      await _pdfTemplateBox.compact();
      await _messageTemplateBox.compact();
      await _emailTemplateBox.compact();
      await _categoriesBox.compact();
      await _inspectionDocumentBox.compact();

      if (kDebugMode) {
        debugPrint('Database compaction completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during database compaction: $e');
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
      'pdfTemplates': _pdfTemplateBox.length,
      'messageTemplates': _messageTemplateBox.length,
      'emailTemplates': _emailTemplateBox.length,
      'templateCategories': _categoriesBox.length,
      'settings': _settingsBox.length,
      'inspectionDocuments': _inspectionDocumentBox.length,
    };
  }

  // --- Template Category Management (DatabaseService) ---

  // --- Template Category Management (DatabaseService) ---

  // In lib/services/database_service.dart
  List<TemplateCategory> getRawCategoriesBoxValues() {
    _ensureInitialized();
    final List<TemplateCategory> typedCategories = [];

    if (_categoriesBox.isEmpty) {
      if (kDebugMode) {
        debugPrint("Category box is empty in getRawCategoriesBoxValues.");
      }
      return typedCategories;
    }

    for (var key in _categoriesBox.keys) {
      dynamic item;
      try {
        // Since _categoriesBox is Box<dynamic>, .get(key) returns dynamic.
        item = _categoriesBox.get(key);
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint("CRITICAL ERROR getting item with key '$key' from _categoriesBox: $e");
          debugPrint("Stack trace for _categoriesBox.get(key) error: $s");
        }
        continue; // Skip this problematic entry
      }

      if (item is TemplateCategory) {
        typedCategories.add(item);
      } else if (item is Map) {
        try {
          // Attempt to convert from map using the robust fromMap factory
          typedCategories.add(TemplateCategory.fromMap(Map<String, dynamic>.from(item)));
        } catch (e, s) {
          if (kDebugMode) {
            debugPrint("Error converting map to TemplateCategory in getRawCategoriesBoxValues (key: $key): $e. Map: $item");
            debugPrint("Stack trace for fromMap error: $s");
          }
        }
      } else if (item != null) {
        if (kDebugMode) {
          debugPrint("Skipping unexpected data type in _categoriesBox (key: $key) in getRawCategoriesBoxValues: ${item.runtimeType}. Value: $item");
        }
      } else {
        if (kDebugMode) {
          debugPrint("Item with key '$key' is null in _categoriesBox.");
        }
      }
    }
    if (kDebugMode) {
      debugPrint("getRawCategoriesBoxValues returning ${typedCategories.length} categories.");
    }
    return typedCategories;
  }




  /// Saves a TemplateCategory object to the database.
  Future<void> saveTemplateCategory(TemplateCategory category) async {
    _ensureInitialized();
    // Ensure the category object has a valid ID before saving
    // TemplateCategory constructor now always assigns an ID, so direct put is fine.
    await _categoriesBox.put(category.id, category);
    if (kDebugMode) {
      debugPrint("Saved TemplateCategory with ID: ${category.id} and key: ${category.key} to _categoriesBox");
    }
  }

  /// Retrieves all template categories, structured for UI display.
  /// This method is robust against data that might be stored as Maps.
  /// Retrieves all template categories, structured for UI display, ensuring dynamic loading for all types.
  Future<Map<String, List<Map<String, dynamic>>>> getAllTemplateCategories() async {
    _ensureInitialized();

    // Use the now robust getRawCategoriesBoxValues() method
    final List<TemplateCategory> typedCategories = getRawCategoriesBoxValues();

    final result = <String, List<Map<String, dynamic>>>{
      'pdf_templates': [],
      'message_templates': [],
      'email_templates': [],
      'custom_fields': [],
    };

    for (final category in typedCategories) {
      final String typeKey = category.templateType;

      final categoryDataMap = {
        'id': category.id,
        'key': category.key,
        'name': category.name,
      };

      if (result.containsKey(typeKey)) {
        result[typeKey]!.add(categoryDataMap);
      } else if (kDebugMode) {
        debugPrint(
            "Warning: TemplateCategory with templateType '$typeKey' found in Hive, "
                "but no matching key in `result` map for dynamic loading in getAllTemplateCategories. "
                "Category Name: '${category.name}'. This category will not be displayed if the UI relies on these specific keys.");
      }
    }
    if (kDebugMode) {
      debugPrint("getAllTemplateCategories (for CategoryManagementScreen) returning: $result");
    }
    return result;
  }



  /// Updates an existing template category's name using its unique ID.
  Future<void> updateTemplateCategory(String categoryId, String newName) async {
    _ensureInitialized();
    final category = _categoriesBox.get(categoryId);
    if (category is TemplateCategory) { // Check type
      final updatedCategory = category.copyWith(name: newName, updatedAt: DateTime.now());
      await _categoriesBox.put(categoryId, updatedCategory);
    } else {
      if (kDebugMode) {
        debugPrint("Category with ID $categoryId not found or not a TemplateCategory for update in DatabaseService.");
      }
    }
  }

  /// Deletes a template category using its unique ID.
  Future<void> deleteTemplateCategory(String categoryId) async {
    _ensureInitialized();
    await _categoriesBox.delete(categoryId);
  }

  /// Counts how many items (PDFs, Messages, Emails, CustomAppDataFields) use a specific category key.
  Future<int> getCategoryUsageCount(String templateTypeScreenName, String categoryKey) async {
    _ensureInitialized();

    // This `templateTypeScreenName` comes from the UI (e.g., "PDF Templates", "Message Templates").
    // We need to match it to how different models store their category information.
    // For PDFTemplate, MessageTemplate, EmailTemplate, they have a `category` field which should store the `categoryKey`.
    // For CustomAppDataField, it also has a `category` field.

    // Normalize the screen name to an internal key if necessary, or ensure consistency.
    // For now, let's assume the `categoryKey` passed is the one used in the models' `category` field.

    switch (templateTypeScreenName) { // Using the string passed from UI/AppStateProvider
      case 'PDF Templates':
      // This implies PDFTemplate objects have a 'category' field that stores the categoryKey.
      // If PDFTemplate.templateType is used for categorization, this needs to align.
      // Let's assume PDFTemplate itself can be categorized by a 'categoryKey' separate from its main 'templateType' (quote/invoice).
      // This might require adding a 'categoryKey' field to PDFTemplate if it's meant to be user-categorized like messages/emails.
      // For now, if PDF templates are not categorized by these user-defined categories, this will return 0.
      // If PDFTemplate.templateType is what we match against categoryKey:
        return _pdfTemplateBox.values
            .where((t) => t.templateType == categoryKey) // This line might need review based on PDFTemplate model's category field
            .length;
      case 'Message Templates':
        return _messageTemplateBox.values
            .where((t) => t.category == categoryKey)
            .length;
      case 'Email Templates':
        return _emailTemplateBox.values
            .where((t) => t.category == categoryKey)
            .length;
      case 'Fields': // This refers to the category of CustomAppDataField itself
        return _customAppDataFieldBox.values
            .where((f) => f.category == categoryKey)
            .length;
      default:
        if (kDebugMode) {
          debugPrint("Warning: Unhandled templateTypeScreenName in getCategoryUsageCount (DatabaseService): $templateTypeScreenName");
        }
        return 0;
    }
  }
  Future<InspectionDocument?> getInspectionDocument(String id) async {
    _ensureInitialized();
    return _inspectionDocumentBox.get(id);
  }

  Future<List<InspectionDocument>> getAllInspectionDocuments() async {
    _ensureInitialized();
    return _inspectionDocumentBox.values.toList();
  }

  Future<List<InspectionDocument>> getInspectionDocumentsByQuote(
      String quoteId) async {
    _ensureInitialized();
    return _inspectionDocumentBox.values
        .where((doc) => doc.quoteId == quoteId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<InspectionDocument>> getInspectionDocumentsByType(
      String customerId, String type) async {
    _ensureInitialized();
    return _inspectionDocumentBox.values
        .where((doc) => doc.customerId == customerId && doc.type == type)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> deleteInspectionDocumentsByCustomer(String customerId) async {
    _ensureInitialized();
    final keysToDelete = _inspectionDocumentBox.values
        .where((doc) => doc.customerId == customerId)
        .map((doc) => doc.key as String)
        .toList();
    await _inspectionDocumentBox.deleteAll(keysToDelete);
  }

  Future<void> updateInspectionDocumentSortOrders(
      List<InspectionDocument> documents) async {
    _ensureInitialized();
    for (int i = 0; i < documents.length; i++) {
      documents[i].updateSortOrder(i);
    }
  }
  // --- Inspection Document Operations ---
  Future<void> saveInspectionDocument(InspectionDocument document) async {
    _ensureInitialized();
    await _inspectionDocumentBox.put(document.id, document);
  }

  Future<List<InspectionDocument>> getInspectionDocumentsByCustomer(
      String customerId) async {
    _ensureInitialized();
    return _inspectionDocumentBox.values
        .where((doc) => doc.customerId == customerId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> deleteInspectionDocument(String id) async {
    _ensureInitialized();
    await _inspectionDocumentBox.delete(id);
  }

  Future<void> close() async {
    if (!_isInitialized) return;
    await Hive.close();
    _isInitialized = false;
    if (kDebugMode) {
      debugPrint('Database closed');
    }
  }
}