// lib/providers/app_state_provider.dart

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../models/customer.dart';
import '../models/product.dart';
import '../models/simplified_quote.dart';
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/app_settings.dart';
import '../models/pdf_template.dart';
import '../models/custom_app_data.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'helpers/pdf_generation_helper.dart';
import 'helpers/roof_scope_helper.dart';
import 'helpers/data_loading_helper.dart';
import 'helpers/template_category_helper.dart';
import 'helpers/message_template_helper.dart';
import 'helpers/email_template_helper.dart';
import 'helpers/customer_helper.dart';
import '../services/template_service.dart';
import '../services/file_service.dart';
import '../services/tax_service.dart';
import '../models/message_template.dart';
import '../models/email_template.dart';
import '../models/template_category.dart';
import '../models/inspection_document.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PdfService _pdfService = PdfService();

  List<Customer> _customers = [];
  List<Product> _products = [];
  AppSettings? _appSettings;
  List<SimplifiedMultiLevelQuote> _simplifiedQuotes = [];
  List<RoofScopeData> _roofScopeDataList = [];
  List<ProjectMedia> _projectMedia = [];
  List<PDFTemplate> _pdfTemplates = [];
  List<MessageTemplate> _messageTemplates = [];
  List<EmailTemplate> _emailTemplates = [];
  List<CustomAppDataField> _customAppDataFields = [];
  final List<TemplateCategory> _templateCategories = [];
  List<InspectionDocument> _inspectionDocuments = [];

  bool _isLoading = false;
  String _loadingMessage = '';

  // Getters
  List<Customer> get customers => _customers;
  List<Product> get products => _products;
  AppSettings? get appSettings => _appSettings;
  List<SimplifiedMultiLevelQuote> get simplifiedQuotes => _simplifiedQuotes;
  List<RoofScopeData> get roofScopeDataList => _roofScopeDataList;
  List<ProjectMedia> get projectMedia => _projectMedia;
  List<PDFTemplate> get pdfTemplates => _pdfTemplates;
  List<PDFTemplate> get activePDFTemplates =>
      _pdfTemplates.where((t) => t.isActive).toList();
  List<MessageTemplate> get messageTemplates => _messageTemplates;
  List<MessageTemplate> get activeMessageTemplates =>
      _messageTemplates.where((t) => t.isActive).toList();
  List<EmailTemplate> get emailTemplates => _emailTemplates;
  List<EmailTemplate> get activeEmailTemplates =>
      _emailTemplates.where((t) => t.isActive).toList();
  List<CustomAppDataField> get customAppDataFields => _customAppDataFields;
  List<InspectionDocument> get inspectionDocuments =>
      List.unmodifiable(_inspectionDocuments);
  List<TemplateCategory> get templateCategories => _templateCategories;

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  AppStateProvider() {
    // Constructor can be used for initial setup
  }

  Future<void> initializeApp() async {
    setLoading(true, 'Initializing app data...');
    await _loadAppSettings();
    await loadAllData();
    await _ensureInspectionCategoryExists();
    setLoading(false);
  }

  void setLoading(bool loading, [String message = '']) {
    if (_isLoading == loading && _loadingMessage == message) return;
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  Future<String> regeneratePDFFromTemplate({
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customDataOverrides,
  }) async {
    return PdfGenerationHelper.regeneratePDFFromTemplate(
      templates: _pdfTemplates,
      templateId: templateId,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customDataOverrides: customDataOverrides,
    );
  }

  /// Generate PDF with enhanced options for preview system
  Future<Map<String, dynamic>> generatePDFForPreview({
    String? templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    return PdfGenerationHelper.generatePDFForPreview(
      pdfService: _pdfService,
      templates: _pdfTemplates,
      templateId: templateId,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customData: customData,
    );
  }

  /// Validate PDF file exists and is readable
  Future<bool> validatePDFFile(String pdfPath) async {
    return PdfGenerationHelper.validatePDFFile(pdfPath);
  }

  Future<void> _loadAppSettings() async {
    try {
      _appSettings = await _db.getAppSettings();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading app settings: $e');
    }
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    try {
      await _db.saveAppSettings(settings);
      _appSettings = settings;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating app settings: $e');
    }
  }

  Future<void> loadAllData() async {
    setLoading(true, 'Loading data...');
    try {
      await Future.wait([
        loadCustomers(),
        loadProducts(),
        loadSimplifiedQuotes(),
        loadRoofScopeData(),
        loadProjectMedia(),
        loadPDFTemplates(),
        loadMessageTemplates(),
        loadEmailTemplates(),
        loadCustomAppDataFields(),
        loadTemplateCategories(),
        loadInspectionDocuments(),
      ]);
      // notifyListeners(); // This is handled by setLoading(false)
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading all data: $e');
    } finally {
      setLoading(false);
    }
  }

  // Individual load methods
  Future<void> loadCustomers() async {
    _customers = await DataLoadingHelper.loadCustomers(_db);
  }

  Future<void> loadProducts() async {
    _products = await DataLoadingHelper.loadProducts(_db);
  }

  Future<void> loadSimplifiedQuotes() async {
    _simplifiedQuotes = await DataLoadingHelper.loadSimplifiedQuotes(_db);
  }

  Future<void> loadRoofScopeData() async {
    _roofScopeDataList = await DataLoadingHelper.loadRoofScopeData(_db);
  }

  Future<void> loadProjectMedia() async {
    _projectMedia = await DataLoadingHelper.loadProjectMedia(_db);
  }

  Future<void> loadPDFTemplates() async {
    _pdfTemplates = await DataLoadingHelper.loadPDFTemplates(_db);
  }

  Future<void> loadMessageTemplates() async {
    _messageTemplates = await DataLoadingHelper.loadMessageTemplates(_db);
  }

  Future<void> loadEmailTemplates() async {
    _emailTemplates = await DataLoadingHelper.loadEmailTemplates(_db);
  }

  Future<void> loadCustomAppDataFields() async {
    _customAppDataFields = await DataLoadingHelper.loadCustomAppDataFields(_db);
  }

  Future<void> loadInspectionDocuments() async {
    _inspectionDocuments = await DataLoadingHelper.loadInspectionDocuments(_db);
  }

  // --- Customer Operations ---
  Future<void> addCustomer(Customer customer) async {
    await CustomerHelper.addCustomer(
      db: _db,
      customers: _customers,
      customer: customer,
    );
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await CustomerHelper.updateCustomer(
      db: _db,
      customers: _customers,
      customer: customer,
    );
    notifyListeners();
  }

  Future<void> deleteCustomer(String customerId) async {
    await CustomerHelper.deleteCustomer(
      db: _db,
      customers: _customers,
      quotes: _simplifiedQuotes,
      roofScopes: _roofScopeDataList,
      media: _projectMedia,
      deleteQuote: deleteSimplifiedQuote,
      deleteRoofScope: deleteRoofScopeData,
      deleteMedia: deleteProjectMedia,
      customerId: customerId,
    );
    notifyListeners();
  }

  Future<void> loadTemplateCategories() async {
    _templateCategories = await DataLoadingHelper.loadTemplateCategories(_db);
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
        final existingIndex = _products.indexWhere(
            (p) => p.name.toLowerCase() == product.name.toLowerCase());
        if (existingIndex != -1) {
          await _db.saveProduct(product);
          _products[existingIndex] = product;
        } else {
          await _db.saveProduct(product);
          _products.add(product);
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error importing products: $e');
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
    final mediaForQuote =
        _projectMedia.where((m) => m.quoteId == quoteId).toList();
    for (var media in mediaForQuote) {
      await deleteProjectMedia(media.id);
    }
    await _db.deleteSimplifiedMultiLevelQuote(quoteId);
    _simplifiedQuotes.removeWhere((q) => q.id == quoteId);
    notifyListeners();
  }

  List<SimplifiedMultiLevelQuote> getSimplifiedQuotesForCustomer(
      String customerId) {
    return _simplifiedQuotes.where((q) => q.customerId == customerId).toList();
  }

  Future<String> generateSimplifiedQuotePdf(
    SimplifiedMultiLevelQuote quote,
    Customer customer, {
    String? selectedLevelId,
    List<String>? selectedAddonIds,
  }) async {
    return PdfGenerationHelper.generateSimplifiedQuotePdf(
      _pdfService,
      quote,
      customer,
      selectedLevelId: selectedLevelId,
      selectedAddonIds: selectedAddonIds,
    );
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

  Future<RoofScopeData?> extractRoofScopeFromPdf(
      String filePath, String customerId) async {
    try {
      final extractedData =
          await RoofScopeHelper.extractRoofScopeData(filePath, customerId);
      if (extractedData != null) {
        await addRoofScopeData(extractedData);
      }
      return extractedData;
    } catch (e) {
      if (kDebugMode) debugPrint('Error in extractRoofScopeFromPdf: $e');
      return null;
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

  // --- PDF Template Management Methods ---
  Future<void> addPDFTemplate(PDFTemplate template) async {
    try {
      await _db.savePDFTemplate(template);
      _pdfTemplates.add(template);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('➕ Added PDF template: ${template.templateName}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding PDF template: $e');
      }
      rethrow;
    }
  }

  /// Ensures the protected "inspection" category always exists
  Future<void> _ensureInspectionCategoryExists() async {
    try {
      // Check if inspection category already exists
      final inspectionExists = _templateCategories.any((cat) =>
          cat.templateType == 'custom_fields' && cat.key == 'inspection');

      if (!inspectionExists) {
        if (kDebugMode)
          debugPrint('🔒 Creating protected inspection category...');

        // Create the protected inspection category
        await addTemplateCategory(
            'custom_fields', 'inspection', 'Inspection Fields');

        if (kDebugMode) debugPrint('✅ Protected inspection category created');
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('Error ensuring inspection category exists: $e');
    }
  }

  Future<void> updatePDFTemplate(PDFTemplate template) async {
    try {
      debugPrint(
          '🔧 AppState: Updating PDF template: ${template.templateName}');
      await _db.savePDFTemplate(template);

      final index = _pdfTemplates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _pdfTemplates[index] = template;
        debugPrint('✅ AppState: Updated PDF template in memory');
      } else {
        debugPrint('⚠️ AppState: PDF template not found in memory, adding it');
        _pdfTemplates.add(template);
      }

      notifyListeners();
      debugPrint('✅ AppState: PDF template updated and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error updating PDF template: $e');
      rethrow;
    }
  }

  Future<void> deletePDFTemplate(String templateId) async {
    try {
      debugPrint('🗑️ AppState: Deleting PDF template: $templateId');
      await _db.deletePDFTemplate(templateId);

      final removedCount = _pdfTemplates.length;
      _pdfTemplates.removeWhere((t) => t.id == templateId);
      final newCount = _pdfTemplates.length;

      debugPrint(
          '✅ AppState: Removed PDF template ($removedCount -> $newCount)');
      notifyListeners();
      debugPrint('✅ AppState: PDF template deleted and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error deleting PDF template: $e');
      rethrow;
    }
  }

  // Replace your current togglePDFTemplateActive method (around line 676) with this:

  Future<void> togglePDFTemplateActive(String templateId) async {
    try {
      debugPrint('🔄 AppState: Toggling PDF template active: $templateId');
      final index = _pdfTemplates.indexWhere((t) => t.id == templateId);
      if (index != -1) {
        final template = _pdfTemplates[index];

        // Create updated template with new status and timestamp
        final updatedTemplate = template.clone();
        updatedTemplate.isActive = !template.isActive;
        updatedTemplate.updatedAt = DateTime.now();

        // Save to database
        await _db.savePDFTemplate(updatedTemplate);

        // Update in memory list
        _pdfTemplates[index] = updatedTemplate;

        // Notify listeners
        notifyListeners();

        debugPrint(
            '✅ AppState: PDF template toggled and notified: ${updatedTemplate.templateName} -> ${updatedTemplate.isActive}');
      } else {
        debugPrint(
            '❌ AppState: PDF template not found for toggle: $templateId');
      }
    } catch (e) {
      debugPrint('❌ AppState: Error toggling PDF template: $e');
      rethrow;
    }
  }

  Future<String> generatePDFFromTemplate({
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    return PdfGenerationHelper.generatePDFFromTemplate(
      templates: _pdfTemplates,
      templateId: templateId,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customData: customData,
    );
  }

  Future<List<PDFTemplate>> validateAllTemplates() async {
    final invalidTemplates = <PDFTemplate>[];

    for (final template in _pdfTemplates) {
      final isValid = await TemplateService.instance.validateTemplate(template);
      if (!isValid) {
        invalidTemplates.add(template);
      }
    }

    if (invalidTemplates.isNotEmpty && kDebugMode) {
      debugPrint('⚠️ Found ${invalidTemplates.length} invalid templates');
    }

    return invalidTemplates;
  }

  Future<PDFTemplate?> createPDFTemplateFromFile(
      String pdfPath, String templateName) async {
    try {
      setLoading(true, 'Processing PDF & Detecting Fields...');
      final template = await TemplateService.instance
          .createTemplateFromPDF(pdfPath, templateName);
      if (template != null) {
        await addExistingPDFTemplateToList(template);
      }
      return template;
    } finally {
      setLoading(false);
    }
  }

  Future<String> generateTemplatePreview(PDFTemplate template) async {
    try {
      setLoading(true, 'Generating preview...');
      return await TemplateService.instance.generateTemplatePreview(template);
    } finally {
      setLoading(false);
    }
  }

  Future<void> addExistingPDFTemplateToList(PDFTemplate template) async {
    try {
      final existingIndex =
          _pdfTemplates.indexWhere((t) => t.id == template.id);
      if (existingIndex == -1) {
        _pdfTemplates.add(template);
        notifyListeners();

        if (kDebugMode) {
          debugPrint(
              '✅ Added template to memory list: ${template.templateName}');
          debugPrint('📊 Total templates: ${_pdfTemplates.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error adding template to list: $e');
      rethrow;
    }
  }

  Future<void> addMessageTemplate(MessageTemplate template) async {
    await MessageTemplateHelper.addMessageTemplate(
      db: _db,
      templates: _messageTemplates,
      template: template,
    );
    notifyListeners();
  }

  Future<void> updateMessageTemplate(MessageTemplate template) async {
    await MessageTemplateHelper.updateMessageTemplate(
      db: _db,
      templates: _messageTemplates,
      template: template,
    );
    notifyListeners();
  }

  Future<void> deleteMessageTemplate(String templateId) async {
    await MessageTemplateHelper.deleteMessageTemplate(
      db: _db,
      templates: _messageTemplates,
      templateId: templateId,
    );
    notifyListeners();
  }

  Future<void> toggleMessageTemplateActive(String templateId) async {
    await MessageTemplateHelper.toggleMessageTemplateActive(
      db: _db,
      templates: _messageTemplates,
      templateId: templateId,
    );
    notifyListeners();
  }

  List<MessageTemplate> getMessageTemplatesByCategory(String category) {
    return MessageTemplateHelper.getByCategory(_messageTemplates, category);
  }

  List<MessageTemplate> searchMessageTemplates(String query) {
    return MessageTemplateHelper.search(_messageTemplates, query);
  }

// --- Email Template Operations ---
  Future<void> addEmailTemplate(EmailTemplate template) async {
    try {
      await EmailTemplateHelper.addEmailTemplate(
        db: _db,
        templates: _emailTemplates,
        template: template,
      );
      notifyListeners();
      debugPrint('✅ AppState: Email template added and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error adding email template: $e');
      rethrow;
    }
  }

  Future<void> updateEmailTemplate(EmailTemplate template) async {
    try {
      await EmailTemplateHelper.updateEmailTemplate(
        db: _db,
        templates: _emailTemplates,
        template: template,
      );
      notifyListeners();
      debugPrint('✅ AppState: Email template updated and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error updating email template: $e');
      rethrow;
    }
  }

  Future<void> deleteEmailTemplate(String templateId) async {
    try {
      await EmailTemplateHelper.deleteEmailTemplate(
        db: _db,
        templates: _emailTemplates,
        templateId: templateId,
      );
      notifyListeners();
      debugPrint('✅ AppState: Email template deleted and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error deleting email template: $e');
      rethrow;
    }
  }

  Future<void> toggleEmailTemplateActive(String templateId) async {
    try {
      await EmailTemplateHelper.toggleEmailTemplateActive(
        db: _db,
        templates: _emailTemplates,
        templateId: templateId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppState: Error toggling email template: $e');
      rethrow;
    }
  }

  List<EmailTemplate> getEmailTemplatesByCategory(String category) {
    return EmailTemplateHelper.getByCategory(_emailTemplates, category);
  }

  List<EmailTemplate> searchEmailTemplates(String query) {
    return EmailTemplateHelper.search(_emailTemplates, query);
  }

  // --- Custom App Data Field Operations ---
  Future<void> addCustomAppDataField(CustomAppDataField field) async {
    try {
      debugPrint('🆕 AppState: Adding custom field: ${field.fieldName}');
      await _db.saveCustomAppDataField(field);
      _customAppDataFields.add(field);
      notifyListeners();
      debugPrint(
          '✅ AppState: Added and notified for field: ${field.fieldName}');
    } catch (e) {
      debugPrint('❌ AppState: Error adding custom field: $e');
      rethrow;
    }
  }

  Future<void> updateCustomAppDataField(String fieldId, String newValue) async {
    try {
      debugPrint('🔄 AppState: Updating field value: $fieldId = "$newValue"');
      final fieldIndex =
          _customAppDataFields.indexWhere((f) => f.id == fieldId);
      if (fieldIndex != -1) {
        final field = _customAppDataFields[fieldIndex];
        field.updateValue(newValue);
        await _db.saveCustomAppDataField(field);
        notifyListeners();
        debugPrint('✅ AppState: Updated field value and notified');
      } else {
        debugPrint('❌ AppState: Field not found for value update: $fieldId');
      }
    } catch (e) {
      debugPrint('❌ AppState: Error updating field value: $e');
      rethrow;
    }
  }

  Future<void> updateCustomAppDataFieldStructure(
      CustomAppDataField updatedField) async {
    try {
      debugPrint(
          '🔧 AppState: Updating field structure: ${updatedField.fieldName}');
      await _db.saveCustomAppDataField(updatedField);

      final index =
          _customAppDataFields.indexWhere((f) => f.id == updatedField.id);
      if (index != -1) {
        _customAppDataFields[index] = updatedField;
        debugPrint('✅ AppState: Updated field in memory list');
      } else {
        debugPrint('⚠️ AppState: Field not found in memory, adding it');
        _customAppDataFields.add(updatedField);
      }

      notifyListeners();
      debugPrint('✅ AppState: Field structure updated and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error updating field structure: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomAppDataField(String fieldId) async {
    try {
      debugPrint('🗑️ AppState: Deleting custom field: $fieldId');
      await _db.deleteCustomAppDataField(fieldId);

      final removedCount = _customAppDataFields.length;
      _customAppDataFields.removeWhere((f) => f.id == fieldId);
      final newCount = _customAppDataFields.length;

      debugPrint(
          '✅ AppState: Removed field from memory ($removedCount -> $newCount)');
      notifyListeners();
      debugPrint('✅ AppState: Field deleted and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error deleting field: $e');
      rethrow;
    }
  }

  // --- Inspection Document Management ---

  List<InspectionDocument> getInspectionDocumentsForCustomer(
      String customerId) {
    return _inspectionDocuments
        .where((doc) => doc.customerId == customerId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> addInspectionDocument(InspectionDocument document) async {
    try {
      await DatabaseService.instance.saveInspectionDocument(document);
      _inspectionDocuments.add(document);

      if (document.sortOrder == 0) {
        final customerDocs =
            getInspectionDocumentsForCustomer(document.customerId);
        document.updateSortOrder(customerDocs.length);
        await DatabaseService.instance.saveInspectionDocument(document);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInspectionDocument(String documentId) async {
    try {
      await DatabaseService.instance.deleteInspectionDocument(documentId);
      _inspectionDocuments.removeWhere((doc) => doc.id == documentId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderCustomAppDataFields(
      String category, List<CustomAppDataField> reorderedFields) async {
    try {
      for (int i = 0; i < reorderedFields.length; i++) {
        reorderedFields[i].updateField(sortOrder: i);
      }

      await DatabaseService.instance
          .saveMultipleCustomAppDataFields(reorderedFields);

      for (final field in reorderedFields) {
        final index = _customAppDataFields.indexWhere((f) => f.id == field.id);
        if (index != -1) {
          _customAppDataFields[index] = field;
        }
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  List<CustomAppDataField> getCustomAppDataFieldsByCategory(String category) {
    return _customAppDataFields.where((f) => f.category == category).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Map<String, String> getCustomAppDataMap() {
    final dataMap = <String, String>{};
    for (final field in _customAppDataFields) {
      dataMap[field.fieldName] = field.currentValue;
    }
    return dataMap;
  }

  Future<void> addTemplateFields(
      List<CustomAppDataField> templateFields) async {
    try {
      setLoading(true, 'Adding template fields...');

      for (final field in templateFields) {
        // Check if field already exists
        final existing = _customAppDataFields
            .where((f) => f.fieldName == field.fieldName)
            .toList();
        if (existing.isEmpty) {
          await addCustomAppDataField(field);
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Added ${templateFields.length} template fields');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding template fields: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Map<String, dynamic> exportCustomAppData() {
    return {
      'customAppDataFields':
          _customAppDataFields.map((f) => f.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  Future<void> importCustomAppData(Map<String, dynamic> data) async {
    try {
      setLoading(true, 'Importing custom app data...');

      if (data['customAppDataFields'] != null) {
        final importedFields = (data['customAppDataFields'] as List)
            .map((fieldData) => CustomAppDataField.fromMap(fieldData))
            .toList();

        for (final field in importedFields) {
          // Check if field already exists
          final existingIndex = _customAppDataFields
              .indexWhere((f) => f.fieldName == field.fieldName);
          if (existingIndex != -1) {
            // Update existing field
            await updateCustomAppDataFieldStructure(field);
          } else {
            // Add new field
            await addCustomAppDataField(field);
          }
        }

        if (kDebugMode) {
          debugPrint(
              '✅ Imported ${importedFields.length} custom app data fields');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error importing custom app data: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

// --- Template Category Management ---
  Future<Map<String, List<Map<String, dynamic>>>>
      getAllTemplateCategories() async {
    return await TemplateCategoryHelper.fetchAll(_db);
  }

  Future<void> addTemplateCategory(String templateTypeKey,
      String categoryUserKey, String categoryDisplayName) async {
    try {
      await TemplateCategoryHelper.addCategory(
        db: _db,
        categories: _templateCategories,
        templateTypeKey: templateTypeKey,
        categoryUserKey: categoryUserKey,
        categoryDisplayName: categoryDisplayName,
      );
      notifyListeners();
      if (kDebugMode)
        debugPrint(
            '➕ Added template category in AppState: $categoryDisplayName for $templateTypeKey (key: $categoryUserKey)');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding template category in AppState: $e');
      }
      rethrow;
    }
  }

  Future<void> updateTemplateCategory(String templateTypeKey,
      String categoryUserKey, String newDisplayName) async {
    final updated = await TemplateCategoryHelper.updateCategory(
      db: _db,
      categories: _templateCategories,
      templateTypeKey: templateTypeKey,
      categoryUserKey: categoryUserKey,
      newDisplayName: newDisplayName,
    );
    if (updated != null) {
      notifyListeners();
      if (kDebugMode)
        debugPrint(
            '📝 Updated template category in AppState (Type: $templateTypeKey, Key: $categoryUserKey) to "$newDisplayName"');
    } else {
      if (kDebugMode)
        debugPrint(
            "Category not found in AppStateProvider for update: Type='$templateTypeKey', Key='$categoryUserKey'. Available: ${_templateCategories.map((c) => '${c.templateType}-${c.key}(id:${c.id})').join(', ')}");
    }
  }

  Future<void> deleteTemplateCategory(
      String templateTypeKey, String categoryUserKey) async {
    final deleted = await TemplateCategoryHelper.deleteCategory(
      db: _db,
      categories: _templateCategories,
      templateTypeKey: templateTypeKey,
      categoryUserKey: categoryUserKey,
    );
    if (deleted) {
      notifyListeners();
      if (kDebugMode)
        debugPrint(
            '🗑️ Deleted template category in AppState (Type: $templateTypeKey, Key: $categoryUserKey)');
    } else {
      if (kDebugMode)
        debugPrint(
            "Category not found in AppStateProvider for deletion: Type='$templateTypeKey', Key='$categoryUserKey'. Available: ${_templateCategories.map((c) => '${c.templateType}-${c.key}(id:${c.id})').join(', ')}");
    }
  }

  Future<int> getCategoryUsageCount(
      String templateType, String categoryKey) async {
    return await TemplateCategoryHelper.usageCount(
        _db, templateType, categoryKey);
  }

  // --- Data Management ---
  Future<String> exportAllDataToFile() async {
    try {
      setLoading(true, 'Exporting data...');
      final data = await _db.exportAllData();
      final filePath = await FileService.instance.saveExportedData(data);
      return filePath;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> pickBackupData() async {
    return await FileService.instance.pickAndReadBackupFile();
  }

  Future<String?> pickAndSaveCompanyLogo(AppSettings settings) async {
    final newPath = await FileService.instance.pickAndSaveCompanyLogo();
    if (newPath != null) {
      settings.updateCompanyLogo(newPath);
      await updateAppSettings(settings);
    }
    return newPath;
  }

  Future<void> removeCompanyLogo(AppSettings settings) async {
    settings.updateCompanyLogo(null);
    await updateAppSettings(settings);
  }

  Future<void> importAllDataFromFile(Map<String, dynamic> data) async {
    try {
      setLoading(true, 'Importing data...');
      await _db.importAllData(data);
      await loadAllData();
    } finally {
      setLoading(false);
    }
  }

  Future<void> clearAllData() async {
    await importAllDataFromFile({});
  }

  // --- Tax Helpers ---
  double? detectTaxRate(
      {String? city, String? stateAbbreviation, String? zipCode}) {
    return TaxService.getTaxRateByAddress(
      city: city,
      stateAbbreviation: stateAbbreviation,
      zipCode: zipCode,
    );
  }

  Future<void> saveZipCodeTaxRate(String zipCode, double rate) async {
    await TaxService.setZipCodeRate(zipCode, rate);
  }

  Future<void> saveStateTaxRate(String stateAbbreviation, double rate) async {
    await TaxService.setStateRate(stateAbbreviation, rate);
  }

  bool get isTaxDatabaseAvailable => TaxService.isDatabaseAvailable;
  String get taxDatabaseStatus => TaxService.getDatabaseStatus();
  // --- Search Operations ---
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final lowerQuery = query.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            (c.phone?.contains(lowerQuery) ?? false))
        .toList();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(lowerQuery) ||
            (p.category.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  List<SimplifiedMultiLevelQuote> searchSimplifiedQuotes(String query) {
    if (query.isEmpty) return _simplifiedQuotes;
    final lowerQuery = query.toLowerCase();
    return _simplifiedQuotes.where((q) {
      final customer = _customers.firstWhere((c) => c.id == q.customerId,
          orElse: () => Customer(name: ""));
      return q.quoteNumber.toLowerCase().contains(lowerQuery) ||
          customer.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // --- Dashboard Statistics ---
  Map<String, dynamic> getDashboardStats() {
    double totalRevenue = 0;
    for (var quote in _simplifiedQuotes) {
      if (quote.status.toLowerCase() == 'accepted' && quote.levels.isNotEmpty) {
        var acceptedLevelSubtotal = quote.levels
            .map((l) => l.subtotal)
            .reduce((max, e) => e > max ? e : max);
        totalRevenue += acceptedLevelSubtotal;
      }
    }
    return {
      'totalCustomers': _customers.length,
      'totalQuotes': _simplifiedQuotes.length,
      'totalProducts': _products.length,
      'totalRevenue': totalRevenue,
      'draftQuotes': _simplifiedQuotes
          .where((q) => q.status.toLowerCase() == 'draft')
          .length,
      'sentQuotes': _simplifiedQuotes
          .where((q) => q.status.toLowerCase() == 'sent')
          .length,
      'acceptedQuotes': _simplifiedQuotes
          .where((q) => q.status.toLowerCase() == 'accepted')
          .length,
    };
  }
}
