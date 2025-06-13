// lib/providers/app_state_provider.dart

import 'package:flutter/foundation.dart';
import '../../models/business/customer.dart';
import '../../models/business/product.dart';
import '../../models/business/simplified_quote.dart';
import '../../models/business/roof_scope_data.dart';
import '../../models/media/project_media.dart';
import '../../models/settings/app_settings.dart';
import '../../models/templates/pdf_template.dart';
import '../../models/templates/message_template.dart';
import '../../models/templates/email_template.dart';
import '../../models/templates/template_category.dart';
import '../../../core/services/database/database_service.dart';
import '../helpers/pdf_generation_helper.dart';
import '../helpers/roof_scope_helper.dart';
import '../helpers/data_loading_helper.dart';
import '../../../core/services/storage/file_service.dart';
import '../../models/settings/custom_app_data.dart';
import '../../models/media/inspection_document.dart';
import 'custom_fields_provider.dart';
import 'customer_state_provider.dart';
import 'product_state_provider.dart';
import 'quote_state_provider.dart';
import 'template_state_provider.dart';
import 'media_state_provider.dart';
import '../app_configuration_provider.dart';


class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;


  late final CustomerStateProvider customerState;
  late final ProductStateProvider productState;
  late final QuoteStateProvider quoteState;
  late final TemplateStateProvider templateState;
  late final MediaStateProvider mediaState;
  late final AppConfigurationProvider configState;
  List<RoofScopeData> _roofScopeDataList = [];
  final CustomFieldsProvider customFields = CustomFieldsProvider();

  bool _isLoading = false;
  String _loadingMessage = '';

  // Getters
  List<Customer> get customers => customerState.customers;
  List<Product> get products => productState.products;
  AppSettings? get appSettings => configState.appSettings;
  List<SimplifiedMultiLevelQuote> get simplifiedQuotes => quoteState.quotes;
  List<RoofScopeData> get roofScopeDataList => _roofScopeDataList;
  List<ProjectMedia> get projectMedia => mediaState.projectMedia;
  List<PDFTemplate> get pdfTemplates => templateState.pdfTemplates;
  List<PDFTemplate> get activePDFTemplates => templateState.activePDFTemplates;
  List<MessageTemplate> get messageTemplates => templateState.messageTemplates;
  List<MessageTemplate> get activeMessageTemplates =>
      templateState.activeMessageTemplates;
  List<EmailTemplate> get emailTemplates => templateState.emailTemplates;
  List<EmailTemplate> get activeEmailTemplates =>
      templateState.activeEmailTemplates;
  List<CustomAppDataField> get customAppDataFields => customFields.fields;
  List<InspectionDocument> get inspectionDocuments =>
      customFields.inspectionDocs;
  List<TemplateCategory> get templateCategories => templateState.categories;

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  AppStateProvider() {
    customerState = CustomerStateProvider(database: _db)
      ..addListener(notifyListeners);
    productState = ProductStateProvider(database: _db)
      ..addListener(notifyListeners);
    quoteState = QuoteStateProvider(database: _db)
      ..addListener(notifyListeners);
    templateState = TemplateStateProvider(database: _db)
      ..addListener(notifyListeners);
    mediaState = MediaStateProvider(database: _db)
      ..addListener(notifyListeners);
    configState = AppConfigurationProvider(database: _db)
      ..addListener(notifyListeners);
  }

  Future<void> initializeApp() async {
    setLoading(true, 'Initializing app data...');
    await configState.loadAppSettings();
    await loadAllData();
    setLoading(false);
  }

  void setLoading(bool loading, [String message = '']) {
    if (_isLoading == loading && _loadingMessage == message) return;
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  /// Validate PDF file exists and is readable
  Future<bool> validatePDFFile(String pdfPath) async {
    return PdfGenerationHelper.validatePDFFile(pdfPath);
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    await configState.updateAppSettings(settings);
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
        templateState.loadAll(),
        customFields.loadFields(),
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
    await mediaState.loadProjectMedia();
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
      media: mediaState.projectMedia,
      deleteQuote: deleteSimplifiedQuote,
      deleteRoofScope: deleteRoofScopeData,
      deleteMedia: deleteProjectMedia,
    );
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
        mediaState.projectMedia.where((m) => m.quoteId == quoteId).toList();
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
    await mediaState.addProjectMedia(media);
  }

  Future<void> updateProjectMedia(ProjectMedia media) async {
    await mediaState.updateProjectMedia(media);
  }

  Future<void> deleteProjectMedia(String mediaId) async {
    await mediaState.deleteProjectMedia(mediaId);
  }

  List<ProjectMedia> getProjectMediaForCustomer(String customerId) {
    return mediaState.getProjectMediaForCustomer(customerId);
  }

  List<ProjectMedia> getProjectMediaForQuote(String quoteId) {
    return mediaState.getProjectMediaForQuote(quoteId);
  }

  // --- Template Operations (delegated) ---
  Future<void> addPDFTemplate(PDFTemplate template) async {
    await templateState.addPDFTemplate(template);
  }

  Future<void> updatePDFTemplate(PDFTemplate template) async {
    await templateState.updatePDFTemplate(template);
  }

  Future<void> deletePDFTemplate(String templateId) async {
    await templateState.deletePDFTemplate(templateId);
  }

  Future<void> togglePDFTemplateActive(String templateId) async {
    await templateState.togglePDFTemplateActive(templateId);
  }

  Future<String> generatePDFFromTemplate({
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    return templateState.generatePDFFromTemplate(
      templateId: templateId,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customData: customData,
    );
  }

  Future<String> regeneratePDFFromTemplate({
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customDataOverrides,
  }) async {
    return templateState.regeneratePDFFromTemplate(
      templateId: templateId,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customDataOverrides: customDataOverrides,
    );
  }

  Future<Map<String, dynamic>> generatePDFForPreview({
    String? templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    return templateState.generatePDFForPreview(
      templateId: templateId,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customData: customData,
    );
  }

  Future<List<PDFTemplate>> validateAllTemplates() async {
    return templateState.validateAllTemplates();
  }

  Future<PDFTemplate?> createPDFTemplateFromFile(
      String pdfPath, String templateName) async {
    return templateState.createPDFTemplateFromFile(pdfPath, templateName);
  }

  Future<String> generateTemplatePreview(PDFTemplate template) async {
    return templateState.generateTemplatePreview(template);
  }

  Future<void> addMessageTemplate(MessageTemplate template) async {
    await templateState.addMessageTemplate(template);
  }

  Future<void> updateMessageTemplate(MessageTemplate template) async {
    await templateState.updateMessageTemplate(template);
  }

  Future<void> deleteMessageTemplate(String templateId) async {
    await templateState.deleteMessageTemplate(templateId);
  }

  Future<void> toggleMessageTemplateActive(String templateId) async {
    await templateState.toggleMessageTemplateActive(templateId);
  }

  List<MessageTemplate> getMessageTemplatesByCategory(String category) {
    return templateState.getMessageTemplatesByCategory(category);
  }

  List<MessageTemplate> searchMessageTemplates(String query) {
    return templateState.searchMessageTemplates(query);
  }

  Future<void> addEmailTemplate(EmailTemplate template) async {
    await templateState.addEmailTemplate(template);
  }

  Future<void> updateEmailTemplate(EmailTemplate template) async {
    await templateState.updateEmailTemplate(template);
  }

  Future<void> deleteEmailTemplate(String templateId) async {
    await templateState.deleteEmailTemplate(templateId);
  }

  Future<void> toggleEmailTemplateActive(String templateId) async {
    await templateState.toggleEmailTemplateActive(templateId);
  }

  List<EmailTemplate> getEmailTemplatesByCategory(String category) {
    return templateState.getEmailTemplatesByCategory(category);
  }

  List<EmailTemplate> searchEmailTemplates(String query) {
    return templateState.searchEmailTemplates(query);
  }

  Future<Map<String, List<Map<String, dynamic>>>>
      getAllTemplateCategories() async {
    return await templateState.getAllTemplateCategories();
  }

  Future<void> addTemplateCategory(String templateTypeKey,
      String categoryUserKey, String categoryDisplayName) async {
    await templateState.addTemplateCategory(
      templateTypeKey,
      categoryUserKey,
      categoryDisplayName,
    );
  }

  Future<void> updateTemplateCategory(String templateTypeKey,
      String categoryUserKey, String newDisplayName) async {
    await templateState.updateTemplateCategory(
      templateTypeKey,
      categoryUserKey,
      newDisplayName,
    );
  }

  Future<void> deleteTemplateCategory(
      String templateTypeKey, String categoryUserKey) async {
    await templateState.deleteTemplateCategory(
        templateTypeKey, categoryUserKey);
  }

  Future<int> getCategoryUsageCount(
      String templateType, String categoryKey) async {
    return await templateState.getCategoryUsageCount(templateType, categoryKey);
  }

  Future<void> loadTemplateCategories() async {
    await templateState.loadTemplateCategories();
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
    return configState.pickAndSaveCompanyLogo(settings);
  }

  Future<void> removeCompanyLogo(AppSettings settings) async {
    await configState.removeCompanyLogo(settings);
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
    return configState.detectTaxRate(
      city: city,
      stateAbbreviation: stateAbbreviation,
      zipCode: zipCode,
    );
  }

  Future<void> saveZipCodeTaxRate(String zipCode, double rate) async {
    await configState.saveZipCodeTaxRate(zipCode, rate);
  }

  Future<void> saveStateTaxRate(String stateAbbreviation, double rate) async {
    await configState.saveStateTaxRate(stateAbbreviation, rate);
  }

  bool get isTaxDatabaseAvailable => configState.isTaxDatabaseAvailable;
  String get taxDatabaseStatus => configState.taxDatabaseStatus;
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
