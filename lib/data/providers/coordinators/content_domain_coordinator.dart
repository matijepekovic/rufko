import 'package:flutter/foundation.dart';
import '../../models/media/project_media.dart';
import '../../models/settings/custom_app_data.dart';
import '../../models/media/inspection_document.dart';
import '../../../core/services/database/database_service.dart';
import '../state/template_state_provider.dart';
import '../state/media_state_provider.dart';
import '../state/custom_fields_provider.dart';

class ContentDomainCoordinator extends ChangeNotifier {
  final DatabaseService _db;
  
  late final TemplateStateProvider templateState;
  late final MediaStateProvider mediaState;
  late final CustomFieldsProvider customFields;

  ContentDomainCoordinator({DatabaseService? database})
      : _db = database ?? DatabaseService.instance {
    templateState = TemplateStateProvider(database: _db)
      ..addListener(notifyListeners);
    mediaState = MediaStateProvider(database: _db)
      ..addListener(notifyListeners);
    customFields = CustomFieldsProvider()
      ..addListener(notifyListeners);
  }

  // Getters - Templates
  dynamic get pdfTemplates => templateState.pdfTemplates;
  dynamic get activePDFTemplates => templateState.activePDFTemplates;
  dynamic get messageTemplates => templateState.messageTemplates;
  dynamic get activeMessageTemplates => templateState.activeMessageTemplates;
  dynamic get emailTemplates => templateState.emailTemplates;
  dynamic get activeEmailTemplates => templateState.activeEmailTemplates;
  dynamic get templateCategories => templateState.categories;

  // Getters - Media & Custom Fields
  List<ProjectMedia> get projectMedia => mediaState.projectMedia;
  List<CustomAppDataField> get customAppDataFields => customFields.fields;
  List<InspectionDocument> get inspectionDocuments => customFields.inspectionDocs;

  // Load Operations
  Future<void> loadContentData() async {
    await Future.wait([
      templateState.loadAll(),
      mediaState.loadProjectMedia(),
      customFields.loadFields(),
      customFields.loadInspectionDocuments(),
    ]);
  }

  // Template Operations - PDF Templates
  Future<void> addPDFTemplate(dynamic template) async {
    await templateState.addPDFTemplate(template);
  }

  Future<void> updatePDFTemplate(dynamic template) async {
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
    required dynamic quote,
    required dynamic customer,
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
    required dynamic quote,
    required dynamic customer,
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
    required dynamic quote,
    required dynamic customer,
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

  Future<List<dynamic>> validateAllTemplates() async {
    return templateState.validateAllTemplates();
  }

  Future<dynamic> createPDFTemplateFromFile(String pdfPath, String templateName) async {
    return templateState.createPDFTemplateFromFile(pdfPath, templateName);
  }

  Future<String> generateTemplatePreview(dynamic template) async {
    return templateState.generateTemplatePreview(template);
  }

  // Template Operations - Message Templates
  Future<void> addMessageTemplate(dynamic template) async {
    await templateState.addMessageTemplate(template);
  }

  Future<void> updateMessageTemplate(dynamic template) async {
    await templateState.updateMessageTemplate(template);
  }

  Future<void> deleteMessageTemplate(String templateId) async {
    await templateState.deleteMessageTemplate(templateId);
  }

  Future<void> toggleMessageTemplateActive(String templateId) async {
    await templateState.toggleMessageTemplateActive(templateId);
  }

  dynamic getMessageTemplatesByCategory(String category) {
    return templateState.getMessageTemplatesByCategory(category);
  }

  dynamic searchMessageTemplates(String query) {
    return templateState.searchMessageTemplates(query);
  }

  // Template Operations - Email Templates
  Future<void> addEmailTemplate(dynamic template) async {
    await templateState.addEmailTemplate(template);
  }

  Future<void> updateEmailTemplate(dynamic template) async {
    await templateState.updateEmailTemplate(template);
  }

  Future<void> deleteEmailTemplate(String templateId) async {
    await templateState.deleteEmailTemplate(templateId);
  }

  Future<void> toggleEmailTemplateActive(String templateId) async {
    await templateState.toggleEmailTemplateActive(templateId);
  }

  dynamic getEmailTemplatesByCategory(String category) {
    return templateState.getEmailTemplatesByCategory(category);
  }

  dynamic searchEmailTemplates(String query) {
    return templateState.searchEmailTemplates(query);
  }

  // Template Category Operations
  Future<Map<String, List<Map<String, dynamic>>>> getAllTemplateCategories() async {
    return templateState.getAllTemplateCategories();
  }

  Future<void> addTemplateCategory(String templateTypeKey, String categoryUserKey, String categoryDisplayName) async {
    await templateState.addTemplateCategory(templateTypeKey, categoryUserKey, categoryDisplayName);
  }

  Future<void> updateTemplateCategory(String templateTypeKey, String categoryUserKey, String newDisplayName) async {
    await templateState.updateTemplateCategory(templateTypeKey, categoryUserKey, newDisplayName);
  }

  Future<void> deleteTemplateCategory(String templateTypeKey, String categoryUserKey) async {
    await templateState.deleteTemplateCategory(templateTypeKey, categoryUserKey);
  }

  Future<int> getCategoryUsageCount(String templateType, String categoryKey) async {
    return templateState.getCategoryUsageCount(templateType, categoryKey);
  }

  Future<void> loadTemplateCategories() async {
    await templateState.loadTemplateCategories();
  }

  // Project Media Operations
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

  // Custom App Data Field Operations
  Future<void> addCustomAppDataField(CustomAppDataField field) async {
    await customFields.addField(field);
  }

  Future<void> updateCustomAppDataField(String fieldId, String newValue) async {
    await customFields.updateFieldValue(fieldId, newValue);
  }

  Future<void> updateCustomAppDataFieldStructure(CustomAppDataField updatedField) async {
    await customFields.updateFieldStructure(updatedField);
  }

  Future<void> deleteCustomAppDataField(String fieldId) async {
    await customFields.deleteField(fieldId);
  }

  // Inspection Document Management
  List<InspectionDocument> getInspectionDocumentsForCustomer(String customerId) {
    return customFields.documentsForCustomer(customerId);
  }

  Future<void> addInspectionDocument(InspectionDocument document) async {
    await customFields.addInspectionDocument(document);
  }

  Future<void> deleteInspectionDocument(String documentId) async {
    await customFields.deleteInspectionDocument(documentId);
  }

  Future<void> reorderCustomAppDataFields(String category, List<dynamic> reorderedFields) async {
    await customFields.reorderFields(category, reorderedFields.cast<CustomAppDataField>());
  }

  List<CustomAppDataField> getCustomAppDataFieldsByCategory(String category) {
    return customFields.fieldsByCategory(category);
  }

  Map<String, String> getCustomAppDataMap() {
    return customFields.dataMap();
  }

  Future<void> addTemplateFields(List<CustomAppDataField> templateFields) async {
    await customFields.addTemplateFields(templateFields);
  }

  Map<String, dynamic> exportCustomAppData() {
    return customFields.exportData();
  }

  Future<void> importCustomAppData(Map<String, dynamic> data) async {
    await customFields.importData(data);
  }
}