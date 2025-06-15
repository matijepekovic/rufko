import 'package:flutter/foundation.dart';
import '../coordinators/business_domain_coordinator.dart';
import '../coordinators/content_domain_coordinator.dart';
import '../coordinators/data_loading_manager.dart';
import '../coordinators/app_configuration_manager.dart';
import '../../models/business/customer.dart';
import '../../models/business/product.dart';
import '../../models/business/simplified_quote.dart';
import '../../models/business/roof_scope_data.dart';
import '../../models/media/project_media.dart';
import '../../models/settings/custom_app_data.dart';
import '../../models/media/inspection_document.dart';

class AppStateProvider extends ChangeNotifier {
  late final BusinessDomainCoordinator businessCoordinator;
  late final ContentDomainCoordinator contentCoordinator;
  late final DataLoadingManager dataManager;
  late final AppConfigurationManager configManager;

  AppStateProvider() {
    businessCoordinator = BusinessDomainCoordinator()
      ..addListener(notifyListeners);
    contentCoordinator = ContentDomainCoordinator()
      ..addListener(notifyListeners);
    dataManager = DataLoadingManager(
      businessCoordinator: businessCoordinator,
      contentCoordinator: contentCoordinator,
    )..addListener(notifyListeners);
    configManager = AppConfigurationManager()
      ..addListener(notifyListeners);
  }

  // Delegated Getters - Business Domain
  List<Customer> get customers => businessCoordinator.customers;
  List<Product> get products => businessCoordinator.products;
  List<SimplifiedMultiLevelQuote> get simplifiedQuotes => businessCoordinator.simplifiedQuotes;
  List<RoofScopeData> get roofScopeDataList => businessCoordinator.roofScopeDataList;

  // Delegated Getters - Content Domain
  dynamic get pdfTemplates => contentCoordinator.pdfTemplates;
  dynamic get activePDFTemplates => contentCoordinator.activePDFTemplates;
  dynamic get messageTemplates => contentCoordinator.messageTemplates;
  dynamic get activeMessageTemplates => contentCoordinator.activeMessageTemplates;
  dynamic get emailTemplates => contentCoordinator.emailTemplates;
  dynamic get activeEmailTemplates => contentCoordinator.activeEmailTemplates;
  dynamic get templateCategories => contentCoordinator.templateCategories;
  List<ProjectMedia> get projectMedia => contentCoordinator.projectMedia;
  List<CustomAppDataField> get customAppDataFields => contentCoordinator.customAppDataFields;
  List<InspectionDocument> get inspectionDocuments => contentCoordinator.inspectionDocuments;

  // Delegated Getters - Configuration
  dynamic get appSettings => configManager.appSettings;

  // Delegated Getters - Loading State
  bool get isLoading => dataManager.isLoading;
  String get loadingMessage => dataManager.loadingMessage;

  // Core Operations
  Future<void> initializeApp() async {
    dataManager.setLoading(true, 'Initializing app data...');
    await configManager.loadAppSettings();
    await dataManager.loadAllData();
    dataManager.setLoading(false);
  }

  void setLoading(bool loading, [String message = '']) {
    dataManager.setLoading(loading, message);
  }

  Future<void> loadAllData() async {
    await dataManager.loadAllData();
  }

  // Validation
  Future<bool> validatePDFFile(String pdfPath) async {
    // Implementation would use PDF helper
    return true;
  }

  // Customer Operations
  Future<void> addCustomer(dynamic customer) async {
    await businessCoordinator.addCustomer(customer);
  }

  Future<void> updateCustomer(dynamic customer) async {
    await businessCoordinator.updateCustomer(customer);
  }

  Future<void> deleteCustomer(String customerId) async {
    await businessCoordinator.deleteCustomer(customerId);
    // Handle related deletions through coordinators
    final mediaForCustomer = contentCoordinator.getProjectMediaForCustomer(customerId);
    for (var media in mediaForCustomer) {
      await contentCoordinator.deleteProjectMedia(media.id);
    }
  }

  // Product Operations
  Future<void> addProduct(dynamic product) async {
    await businessCoordinator.addProduct(product);
  }

  Future<void> updateProduct(dynamic product) async {
    await businessCoordinator.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await businessCoordinator.deleteProduct(productId);
  }

  Future<void> importProducts(List<dynamic> productsToImport) async {
    await dataManager.importProducts(productsToImport);
  }

  // Quote Operations
  Future<void> addSimplifiedQuote(dynamic quote) async {
    await businessCoordinator.addSimplifiedQuote(quote);
  }

  Future<void> updateSimplifiedQuote(dynamic quote) async {
    await businessCoordinator.updateSimplifiedQuote(quote);
  }

  Future<void> deleteSimplifiedQuote(String quoteId) async {
    final mediaForQuote = contentCoordinator.getProjectMediaForQuote(quoteId);
    for (var media in mediaForQuote) {
      await contentCoordinator.deleteProjectMedia(media.id);
    }
    await businessCoordinator.deleteSimplifiedQuote(quoteId);
  }

  List<SimplifiedMultiLevelQuote> getSimplifiedQuotesForCustomer(String customerId) {
    return businessCoordinator.getSimplifiedQuotesForCustomer(customerId);
  }

  Future<String> generateSimplifiedQuotePdf(dynamic quote, dynamic customer, {String? selectedLevelId, List<String>? selectedAddonIds}) async {
    return businessCoordinator.generateSimplifiedQuotePdf(quote, customer, selectedLevelId: selectedLevelId, selectedAddonIds: selectedAddonIds);
  }

  Future<void> loadSimplifiedQuotes() async {
    await dataManager.loadSimplifiedQuotes();
  }

  // Roof Scope Operations
  Future<void> addRoofScopeData(dynamic data) async {
    await businessCoordinator.addRoofScopeData(data);
  }

  Future<void> updateRoofScopeData(dynamic data) async {
    await businessCoordinator.updateRoofScopeData(data);
  }

  Future<void> deleteRoofScopeData(String dataId) async {
    await businessCoordinator.deleteRoofScopeData(dataId);
  }

  List<RoofScopeData> getRoofScopeDataForCustomer(String customerId) {
    return businessCoordinator.getRoofScopeDataForCustomer(customerId);
  }

  Future<dynamic> extractRoofScopeFromPdf(String filePath, String customerId) async {
    return businessCoordinator.extractRoofScopeFromPdf(filePath, customerId);
  }

  // Project Media Operations
  Future<void> addProjectMedia(dynamic media) async {
    await contentCoordinator.addProjectMedia(media);
  }

  Future<void> updateProjectMedia(dynamic media) async {
    await contentCoordinator.updateProjectMedia(media);
  }

  Future<void> deleteProjectMedia(String mediaId) async {
    await contentCoordinator.deleteProjectMedia(mediaId);
  }

  List<ProjectMedia> getProjectMediaForCustomer(String customerId) {
    return contentCoordinator.getProjectMediaForCustomer(customerId);
  }

  List<ProjectMedia> getProjectMediaForQuote(String quoteId) {
    return contentCoordinator.getProjectMediaForQuote(quoteId);
  }

  Future<void> loadProjectMedia() async {
    await dataManager.loadProjectMedia();
  }

  // Template Operations - PDF
  Future<void> addPDFTemplate(dynamic template) async {
    await contentCoordinator.addPDFTemplate(template);
  }

  Future<void> updatePDFTemplate(dynamic template) async {
    await contentCoordinator.updatePDFTemplate(template);
  }

  Future<void> deletePDFTemplate(String templateId) async {
    await contentCoordinator.deletePDFTemplate(templateId);
  }

  Future<void> togglePDFTemplateActive(String templateId) async {
    await contentCoordinator.togglePDFTemplateActive(templateId);
  }

  Future<String> generatePDFFromTemplate({required String templateId, required dynamic quote, required dynamic customer, String? selectedLevelId, Map<String, String>? customData}) async {
    return contentCoordinator.generatePDFFromTemplate(templateId: templateId, quote: quote, customer: customer, selectedLevelId: selectedLevelId, customData: customData);
  }

  Future<String> regeneratePDFFromTemplate({required String templateId, required dynamic quote, required dynamic customer, String? selectedLevelId, Map<String, String>? customDataOverrides}) async {
    return contentCoordinator.regeneratePDFFromTemplate(templateId: templateId, quote: quote, customer: customer, selectedLevelId: selectedLevelId, customDataOverrides: customDataOverrides);
  }

  Future<Map<String, dynamic>> generatePDFForPreview({String? templateId, required dynamic quote, required dynamic customer, String? selectedLevelId, Map<String, String>? customData}) async {
    return contentCoordinator.generatePDFForPreview(templateId: templateId, quote: quote, customer: customer, selectedLevelId: selectedLevelId, customData: customData);
  }

  Future<dynamic> validateAllTemplates() async {
    return contentCoordinator.validateAllTemplates();
  }

  Future<dynamic> createPDFTemplateFromFile(String pdfPath, String templateName) async {
    return contentCoordinator.createPDFTemplateFromFile(pdfPath, templateName);
  }

  Future<String> generateTemplatePreview(dynamic template) async {
    return contentCoordinator.generateTemplatePreview(template);
  }

  // Template Operations - Message
  Future<void> addMessageTemplate(dynamic template) async {
    await contentCoordinator.addMessageTemplate(template);
  }

  Future<void> updateMessageTemplate(dynamic template) async {
    await contentCoordinator.updateMessageTemplate(template);
  }

  Future<void> deleteMessageTemplate(String templateId) async {
    await contentCoordinator.deleteMessageTemplate(templateId);
  }

  Future<void> toggleMessageTemplateActive(String templateId) async {
    await contentCoordinator.toggleMessageTemplateActive(templateId);
  }

  dynamic getMessageTemplatesByCategory(String category) {
    return contentCoordinator.getMessageTemplatesByCategory(category);
  }

  dynamic searchMessageTemplates(String query) {
    return contentCoordinator.searchMessageTemplates(query);
  }

  // Template Operations - Email
  Future<void> addEmailTemplate(dynamic template) async {
    await contentCoordinator.addEmailTemplate(template);
  }

  Future<void> updateEmailTemplate(dynamic template) async {
    await contentCoordinator.updateEmailTemplate(template);
  }

  Future<void> deleteEmailTemplate(String templateId) async {
    await contentCoordinator.deleteEmailTemplate(templateId);
  }

  Future<void> toggleEmailTemplateActive(String templateId) async {
    await contentCoordinator.toggleEmailTemplateActive(templateId);
  }

  dynamic getEmailTemplatesByCategory(String category) {
    return contentCoordinator.getEmailTemplatesByCategory(category);
  }

  dynamic searchEmailTemplates(String query) {
    return contentCoordinator.searchEmailTemplates(query);
  }

  // Template Category Operations
  Future<Map<String, List<Map<String, dynamic>>>> getAllTemplateCategories() async {
    return contentCoordinator.getAllTemplateCategories();
  }

  Future<void> addTemplateCategory(String templateTypeKey, String categoryUserKey, String categoryDisplayName) async {
    await contentCoordinator.addTemplateCategory(templateTypeKey, categoryUserKey, categoryDisplayName);
  }

  Future<void> updateTemplateCategory(String templateTypeKey, String categoryUserKey, String newDisplayName) async {
    await contentCoordinator.updateTemplateCategory(templateTypeKey, categoryUserKey, newDisplayName);
  }

  Future<void> deleteTemplateCategory(String templateTypeKey, String categoryUserKey) async {
    await contentCoordinator.deleteTemplateCategory(templateTypeKey, categoryUserKey);
  }

  Future<int> getCategoryUsageCount(String templateType, String categoryKey) async {
    return contentCoordinator.getCategoryUsageCount(templateType, categoryKey);
  }

  Future<void> loadTemplateCategories() async {
    await contentCoordinator.loadTemplateCategories();
  }

  // Custom App Data Field Operations
  Future<void> addCustomAppDataField(dynamic field) async {
    await contentCoordinator.addCustomAppDataField(field);
  }

  Future<void> updateCustomAppDataField(String fieldId, String newValue) async {
    await contentCoordinator.updateCustomAppDataField(fieldId, newValue);
  }

  Future<void> updateCustomAppDataFieldStructure(dynamic updatedField) async {
    await contentCoordinator.updateCustomAppDataFieldStructure(updatedField);
  }

  Future<void> deleteCustomAppDataField(String fieldId) async {
    await contentCoordinator.deleteCustomAppDataField(fieldId);
  }

  // Inspection Document Management
  List<InspectionDocument> getInspectionDocumentsForCustomer(String customerId) {
    return contentCoordinator.getInspectionDocumentsForCustomer(customerId);
  }

  Future<void> addInspectionDocument(dynamic document) async {
    await contentCoordinator.addInspectionDocument(document);
  }

  Future<void> deleteInspectionDocument(String documentId) async {
    await contentCoordinator.deleteInspectionDocument(documentId);
  }

  Future<void> reorderCustomAppDataFields(String category, List<dynamic> reorderedFields) async {
    await contentCoordinator.reorderCustomAppDataFields(category, reorderedFields);
  }

  List<CustomAppDataField> getCustomAppDataFieldsByCategory(String category) {
    return contentCoordinator.getCustomAppDataFieldsByCategory(category);
  }

  Map<String, String> getCustomAppDataMap() {
    return contentCoordinator.getCustomAppDataMap();
  }

  Future<void> addTemplateFields(List<dynamic> templateFields) async {
    await dataManager.addTemplateFields(templateFields);
  }

  Map<String, dynamic> exportCustomAppData() {
    return contentCoordinator.exportCustomAppData();
  }

  Future<void> importCustomAppData(Map<String, dynamic> data) async {
    await dataManager.importCustomAppData(data);
  }

  // Configuration Operations
  Future<void> updateAppSettings(dynamic settings) async {
    await configManager.updateAppSettings(settings);
  }

  Future<String?> pickAndSaveCompanyLogo(dynamic settings) async {
    return configManager.pickAndSaveCompanyLogo(settings);
  }

  Future<void> removeCompanyLogo(dynamic settings) async {
    await configManager.removeCompanyLogo(settings);
  }

  // Tax Operations
  double? detectTaxRate({String? city, String? stateAbbreviation, String? zipCode}) {
    return configManager.detectTaxRate(city: city, stateAbbreviation: stateAbbreviation, zipCode: zipCode);
  }

  Future<void> saveZipCodeTaxRate(String zipCode, double rate) async {
    await configManager.saveZipCodeTaxRate(zipCode, rate);
  }

  Future<void> saveStateTaxRate(String stateAbbreviation, double rate) async {
    await configManager.saveStateTaxRate(stateAbbreviation, rate);
  }

  bool get isTaxDatabaseAvailable => configManager.isTaxDatabaseAvailable;
  String get taxDatabaseStatus => configManager.taxDatabaseStatus;

  // Data Management Operations
  Future<String> exportAllDataToFile() async {
    return configManager.exportAllDataToFile(() => _getAllDataForExport());
  }

  Map<String, dynamic> _getAllDataForExport() {
    return {
      'customers': customers,
      'products': products,
      'quotes': simplifiedQuotes,
      'roofScopeData': roofScopeDataList,
      'projectMedia': projectMedia,
      'customAppData': exportCustomAppData(),
    };
  }

  Future<Map<String, dynamic>> pickBackupData() async {
    return configManager.pickBackupData();
  }

  Future<void> importAllDataFromFile(Map<String, dynamic> data) async {
    await configManager.importAllDataFromFile(data, loadAllData);
  }

  Future<void> clearAllData() async {
    await configManager.clearAllData(loadAllData);
  }

  // Search Operations
  List<Customer> searchCustomers(String query) {
    return businessCoordinator.searchCustomers(query);
  }

  List<Product> searchProducts(String query) {
    return businessCoordinator.searchProducts(query);
  }

  List<SimplifiedMultiLevelQuote> searchSimplifiedQuotes(String query) {
    return businessCoordinator.searchSimplifiedQuotes(query);
  }

  // Dashboard Statistics
  Map<String, dynamic> getDashboardStats() {
    return dataManager.getDashboardStats();
  }
}