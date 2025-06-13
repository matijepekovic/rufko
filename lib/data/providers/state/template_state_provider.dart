import 'package:flutter/foundation.dart';
import '../../models/templates/pdf_template.dart';
import '../../models/templates/message_template.dart';
import '../../models/templates/email_template.dart';
import '../../models/templates/template_category.dart';
import '../../models/business/customer.dart';
import '../../models/business/simplified_quote.dart';
import '../../../core/services/database/database_service.dart';
import '../../../core/services/pdf/pdf_service.dart';
import '../../../core/services/template_service.dart';
import '../helpers/data_loading_helper.dart';
import '../helpers/template_category_helper.dart';
import '../helpers/message_template_helper.dart';
import '../helpers/email_template_helper.dart';
import '../helpers/pdf_generation_helper.dart';

class TemplateStateProvider extends ChangeNotifier {
  final DatabaseService _db;
  final PdfService _pdfService = PdfService();

  List<PDFTemplate> _pdfTemplates = [];
  List<MessageTemplate> _messageTemplates = [];
  List<EmailTemplate> _emailTemplates = [];
  List<TemplateCategory> _categories = [];

  bool _isLoading = false;
  String _loadingMessage = '';

  TemplateStateProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<PDFTemplate> get pdfTemplates => _pdfTemplates;
  List<PDFTemplate> get activePDFTemplates =>
      _pdfTemplates.where((t) => t.isActive).toList();
  List<MessageTemplate> get messageTemplates => _messageTemplates;
  List<MessageTemplate> get activeMessageTemplates =>
      _messageTemplates.where((t) => t.isActive).toList();
  List<EmailTemplate> get emailTemplates => _emailTemplates;
  List<EmailTemplate> get activeEmailTemplates =>
      _emailTemplates.where((t) => t.isActive).toList();
  List<TemplateCategory> get categories => _categories;

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  void _setLoading(bool loading, [String message = '']) {
    if (_isLoading == loading && _loadingMessage == message) return;
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
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

  Future<void> loadTemplateCategories() async {
    _categories = await DataLoadingHelper.loadTemplateCategories(_db);
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadPDFTemplates(),
      loadMessageTemplates(),
      loadEmailTemplates(),
      loadTemplateCategories(),
    ]);
    await _ensureInspectionCategoryExists();
  }

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

  Future<void> updatePDFTemplate(PDFTemplate template) async {
    try {
      debugPrint('🔧 TemplateState: Updating PDF template: ${template.templateName}');
      await _db.savePDFTemplate(template);

      final index = _pdfTemplates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _pdfTemplates[index] = template;
        debugPrint('✅ TemplateState: Updated PDF template in memory');
      } else {
        debugPrint('⚠️ TemplateState: PDF template not found, adding it');
        _pdfTemplates.add(template);
      }

      notifyListeners();
      debugPrint('✅ TemplateState: PDF template updated and notified');
    } catch (e) {
      debugPrint('❌ TemplateState: Error updating PDF template: $e');
      rethrow;
    }
  }

  Future<void> deletePDFTemplate(String templateId) async {
    try {
      debugPrint('🗑️ TemplateState: Deleting PDF template: $templateId');
      await _db.deletePDFTemplate(templateId);

      final removedCount = _pdfTemplates.length;
      _pdfTemplates.removeWhere((t) => t.id == templateId);
      final newCount = _pdfTemplates.length;

      debugPrint('✅ TemplateState: Removed PDF template ($removedCount -> $newCount)');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ TemplateState: Error deleting PDF template: $e');
      rethrow;
    }
  }

  Future<void> togglePDFTemplateActive(String templateId) async {
    try {
      debugPrint('🔄 TemplateState: Toggling PDF template active: $templateId');
      final index = _pdfTemplates.indexWhere((t) => t.id == templateId);
      if (index != -1) {
        final template = _pdfTemplates[index];
        final updated = template.clone()
          ..isActive = !template.isActive
          ..updatedAt = DateTime.now();
        await _db.savePDFTemplate(updated);
        _pdfTemplates[index] = updated;
        notifyListeners();
      } else {
        debugPrint('❌ TemplateState: PDF template not found: $templateId');
      }
    } catch (e) {
      debugPrint('❌ TemplateState: Error toggling PDF template: $e');
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

  Future<List<PDFTemplate>> validateAllTemplates() async {
    final invalid = <PDFTemplate>[];
    for (final t in _pdfTemplates) {
      final isValid = await TemplateService.instance.validateTemplate(t);
      if (!isValid) invalid.add(t);
    }
    if (invalid.isNotEmpty && kDebugMode) {
      debugPrint('⚠️ Found ${invalid.length} invalid templates');
    }
    return invalid;
  }

  Future<PDFTemplate?> createPDFTemplateFromFile(
      String pdfPath, String templateName) async {
    try {
      _setLoading(true, 'Processing PDF & Detecting Fields...');
      final template = await TemplateService.instance
          .createTemplateFromPDF(pdfPath, templateName);
      if (template != null) {
        await addExistingPDFTemplateToList(template);
      }
      return template;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> generateTemplatePreview(PDFTemplate template) async {
    try {
      _setLoading(true, 'Generating preview...');
      return await TemplateService.instance.generateTemplatePreview(template);
    } finally {
      _setLoading(false);
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
          debugPrint('✅ Added template to list: ${template.templateName}');
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

  Future<void> addEmailTemplate(EmailTemplate template) async {
    try {
      await EmailTemplateHelper.addEmailTemplate(
        db: _db,
        templates: _emailTemplates,
        template: template,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ TemplateState: Error adding email template: $e');
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
    } catch (e) {
      debugPrint('❌ TemplateState: Error updating email template: $e');
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
    } catch (e) {
      debugPrint('❌ TemplateState: Error deleting email template: $e');
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
      debugPrint('❌ TemplateState: Error toggling email template: $e');
      rethrow;
    }
  }

  List<EmailTemplate> getEmailTemplatesByCategory(String category) {
    return EmailTemplateHelper.getByCategory(_emailTemplates, category);
  }

  List<EmailTemplate> searchEmailTemplates(String query) {
    return EmailTemplateHelper.search(_emailTemplates, query);
  }

  Future<Map<String, List<Map<String, dynamic>>>> getAllTemplateCategories() async {
    return await TemplateCategoryHelper.fetchAll(_db);
  }

  Future<void> addTemplateCategory(
      String templateTypeKey, String categoryUserKey, String categoryDisplayName) async {
    try {
      await TemplateCategoryHelper.addCategory(
        db: _db,
        categories: _categories,
        templateTypeKey: templateTypeKey,
        categoryUserKey: categoryUserKey,
        categoryDisplayName: categoryDisplayName,
      );
      notifyListeners();
      if (kDebugMode) {
        debugPrint('➕ Added template category: $categoryDisplayName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding template category: $e');
      }
      rethrow;
    }
  }

  Future<void> updateTemplateCategory(
      String templateTypeKey, String categoryUserKey, String newDisplayName) async {
    final updated = await TemplateCategoryHelper.updateCategory(
      db: _db,
      categories: _categories,
      templateTypeKey: templateTypeKey,
      categoryUserKey: categoryUserKey,
      newDisplayName: newDisplayName,
    );
    if (updated != null) {
      notifyListeners();
      if (kDebugMode) {
        debugPrint('📝 Updated template category: $templateTypeKey/$categoryUserKey');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            "Category not found for update: Type='$templateTypeKey', Key='$categoryUserKey'");
      }
    }
  }

  Future<void> deleteTemplateCategory(
      String templateTypeKey, String categoryUserKey) async {
    final deleted = await TemplateCategoryHelper.deleteCategory(
      db: _db,
      categories: _categories,
      templateTypeKey: templateTypeKey,
      categoryUserKey: categoryUserKey,
    );
    if (deleted) {
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🗑️ Deleted template category: $templateTypeKey/$categoryUserKey');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            "Category not found for deletion: Type='$templateTypeKey', Key='$categoryUserKey'");
      }
    }
  }

  Future<int> getCategoryUsageCount(String templateType, String categoryKey) async {
    return await TemplateCategoryHelper.usageCount(_db, templateType, categoryKey);
  }

  Future<void> _ensureInspectionCategoryExists() async {
    try {
      final inspectionExists = _categories.any(
          (cat) => cat.templateType == 'custom_fields' && cat.key == 'inspection');
      if (!inspectionExists) {
        if (kDebugMode) {
          debugPrint('🔒 Creating protected inspection category...');
        }
        await addTemplateCategory('custom_fields', 'inspection', 'Inspection Fields');
        if (kDebugMode) debugPrint('✅ Protected inspection category created');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error ensuring inspection category exists: $e');
      }
    }
  }
}
