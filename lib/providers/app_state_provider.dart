// lib/providers/app_state_provider.dart

import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/simplified_quote.dart';
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/app_settings.dart';
import '../models/pdf_template.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'helpers/pdf_generation_helper.dart';
import 'helpers/roof_scope_helper.dart';
import 'helpers/data_loading_helper.dart';
import 'helpers/template_category_helper.dart';
import 'helpers/message_template_helper.dart';
import 'helpers/email_template_helper.dart';
import '../services/template_service.dart';
import '../services/file_service.dart';
import '../services/tax_service.dart';
import '../models/message_template.dart';
import '../models/email_template.dart';
import '../models/template_category.dart';
import '../models/custom_app_data.dart';
import '../models/inspection_document.dart';
import 'custom_fields_provider.dart';
import 'customer_state_provider.dart';
import 'product_state_provider.dart';
import 'quote_state_provider.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PdfService _pdfService = PdfService();

  late final CustomerStateProvider customerState;
  late final ProductStateProvider productState;
  late final QuoteStateProvider quoteState;
  AppSettings? _appSettings;
  List<RoofScopeData> _roofScopeDataList = [];
  List<ProjectMedia> _projectMedia = [];
  List<PDFTemplate> _pdfTemplates = [];
  List<MessageTemplate> _messageTemplates = [];
  List<EmailTemplate> _emailTemplates = [];
  final CustomFieldsProvider customFields = CustomFieldsProvider();
  List<TemplateCategory> _templateCategories = [];

  bool _isLoading = false;
  String _loadingMessage = '';

  // Getters
  List<Customer> get customers => customerState.customers;
  List<Product> get products => productState.products;
  AppSettings? get appSettings => _appSettings;
  List<SimplifiedMultiLevelQuote> get simplifiedQuotes => quoteState.quotes;
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
  List<CustomAppDataField> get customAppDataFields => customFields.fields;
  List<InspectionDocument> get inspectionDocuments =>
      customFields.inspectionDocs;
  List<TemplateCategory> get templateCategories => _templateCategories;

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  AppStateProvider() {
    customerState = CustomerStateProvider(database: _db)
      ..addListener(notifyListeners);
    productState = ProductStateProvider(database: _db)
      ..addListener(notifyListeners);
    quoteState = QuoteStateProvider(database: _db)
      ..addListener(notifyListeners);
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
        customerState.loadCustomers(),
        productState.loadProducts(),
        quoteState.loadQuotes(),
        loadRoofScopeData(),
        loadProjectMedia(),
        loadPDFTemplates(),
        loadMessageTemplates(),
        loadEmailTemplates(),
        customFields.loadFields(),
        loadTemplateCategories(),
        customFields.loadInspectionDocuments(),
      ]);
      // notifyListeners(); // This is handled by setLoading(false)
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading all data: $e');
    } finally {
      setLoading(false);
    }
  }

  // Individual load methods

  Future<void> loadSimplifiedQuotes() async {
    await quoteState.loadQuotes();
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

  // --- Customer Operations ---
  Future<void> addCustomer(Customer customer) async {
    await customerState.addCustomer(customer);
  }

  Future<void> updateCustomer(Customer customer) async {
    await customerState.updateCustomer(customer);
  }

  Future<void> deleteCustomer(String customerId) async {
    await customerState.deleteCustomer(
      customerId: customerId,
      quotes: quoteState.quotes,
      roofScopes: _roofScopeDataList,
      media: _projectMedia,
      deleteQuote: deleteSimplifiedQuote,
      deleteRoofScope: deleteRoofScopeData,
      deleteMedia: deleteProjectMedia,
    );
  }

  Future<void> loadTemplateCategories() async {
    _templateCategories = await DataLoadingHelper.loadTemplateCategories(_db);
  }

  // --- Product Operations ---
  Future<void> addProduct(Product product) async {
    await productState.addProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    await productState.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await productState.deleteProduct(productId);
  }

  Future<void> importProducts(List<Product> productsToImport) async {
    setLoading(true, 'Importing products...');
    try {
      await productState.importProducts(productsToImport);
    } finally {
      setLoading(false);
    }
  }

  // --- SimplifiedMultiLevelQuote Operations ---
  Future<void> addSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    await quoteState.addSimplifiedQuote(quote);
  }

  Future<void> updateSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    await quoteState.updateSimplifiedQuote(quote);
  }

  Future<void> deleteSimplifiedQuote(String quoteId) async {
    final mediaForQuote =
        _projectMedia.where((m) => m.quoteId == quoteId).toList();
    for (var media in mediaForQuote) {
      await deleteProjectMedia(media.id);
    }
    await quoteState.deleteSimplifiedQuote(quoteId);
  }

  List<SimplifiedMultiLevelQuote> getSimplifiedQuotesForCustomer(
      String customerId) {
    return quoteState.getSimplifiedQuotesForCustomer(customerId);
  }

  Future<String> generateSimplifiedQuotePdf(
    SimplifiedMultiLevelQuote quote,
    Customer customer, {
    String? selectedLevelId,
    List<String>? selectedAddonIds,
  }) async {
    return quoteState.generateSimplifiedQuotePdf(
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
    await customFields.addField(field);
    notifyListeners();
  }

  Future<void> updateCustomAppDataField(String fieldId, String newValue) async {
    await customFields.updateFieldValue(fieldId, newValue);
    notifyListeners();
  }

  Future<void> updateCustomAppDataFieldStructure(
      CustomAppDataField updatedField) async {
    await customFields.updateFieldStructure(updatedField);
    notifyListeners();
  }

  Future<void> deleteCustomAppDataField(String fieldId) async {
    await customFields.deleteField(fieldId);
    notifyListeners();
  }

  // --- Inspection Document Management ---

  List<InspectionDocument> getInspectionDocumentsForCustomer(
      String customerId) {
    return customFields.documentsForCustomer(customerId);
  }

  Future<void> addInspectionDocument(InspectionDocument document) async {
    await customFields.addInspectionDocument(document);
    notifyListeners();
  }

  Future<void> deleteInspectionDocument(String documentId) async {
    await customFields.deleteInspectionDocument(documentId);
    notifyListeners();
  }

  Future<void> reorderCustomAppDataFields(
      String category, List<CustomAppDataField> reorderedFields) async {
    await customFields.reorderFields(category, reorderedFields);
    notifyListeners();
  }

  List<CustomAppDataField> getCustomAppDataFieldsByCategory(String category) {
    return customFields.fieldsByCategory(category);
  }

  Map<String, String> getCustomAppDataMap() {
    return customFields.dataMap();
  }

  Future<void> addTemplateFields(
      List<CustomAppDataField> templateFields) async {
    try {
      setLoading(true, 'Adding template fields...');
      await customFields.addTemplateFields(templateFields);
    } finally {
      setLoading(false);
    }
  }

  Map<String, dynamic> exportCustomAppData() {
    return customFields.exportData();
  }

  Future<void> importCustomAppData(Map<String, dynamic> data) async {
    try {
      setLoading(true, 'Importing custom app data...');
      await customFields.importData(data);
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
    return customerState.searchCustomers(query);
  }

  List<Product> searchProducts(String query) {
    return productState.searchProducts(query);
  }

  List<SimplifiedMultiLevelQuote> searchSimplifiedQuotes(String query) {
    if (query.isEmpty) return quoteState.quotes;
    final lowerQuery = query.toLowerCase();
    return quoteState.quotes.where((q) {
      final customer = customers.firstWhere((c) => c.id == q.customerId,
          orElse: () => Customer(name: ""));
      return q.quoteNumber.toLowerCase().contains(lowerQuery) ||
          customer.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // --- Dashboard Statistics ---
  Map<String, dynamic> getDashboardStats() {
    double totalRevenue = 0;
    for (var quote in quoteState.quotes) {
      if (quote.status.toLowerCase() == 'accepted' && quote.levels.isNotEmpty) {
        var acceptedLevelSubtotal = quote.levels
            .map((l) => l.subtotal)
            .reduce((max, e) => e > max ? e : max);
        totalRevenue += acceptedLevelSubtotal;
      }
    }
    return {
      'totalCustomers': customers.length,
      'totalQuotes': quoteState.quotes.length,
      'totalProducts': products.length,
      'totalRevenue': totalRevenue,
      'draftQuotes': quoteState.quotes
          .where((q) => q.status.toLowerCase() == 'draft')
          .length,
      'sentQuotes': quoteState.quotes
          .where((q) => q.status.toLowerCase() == 'sent')
          .length,
      'acceptedQuotes': quoteState.quotes
          .where((q) => q.status.toLowerCase() == 'accepted')
          .length,
    };
  }
}
