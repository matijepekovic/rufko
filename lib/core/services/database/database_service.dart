// lib/services/database_service.dart - CLEAN SQLITE-ONLY VERSION

import '../../../data/models/business/customer.dart';
import '../../../data/models/business/product.dart';
import '../../../data/models/business/roof_scope_data.dart';
import '../../../data/models/media/project_media.dart';
import '../../../data/models/settings/app_settings.dart';
import '../../../data/models/business/simplified_quote.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/templates/pdf_template.dart';
import '../../../data/models/settings/custom_app_data.dart';
import '../../../data/models/templates/message_template.dart';
import '../../../data/models/templates/email_template.dart';
import '../../../data/models/templates/template_category.dart';
import '../../../data/models/media/inspection_document.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/quote_repository.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../../data/repositories/template_category_repository.dart';
import '../../../data/repositories/roof_scope_repository.dart';
import '../../../data/repositories/project_media_repository.dart';
import '../../../data/repositories/pdf_template_repository.dart';
import '../../../data/repositories/message_template_repository.dart';
import '../../../data/repositories/email_template_repository.dart';
import '../../../data/repositories/custom_app_data_field_repository.dart';
import '../../../data/repositories/inspection_document_repository.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  // SQLite repositories - ALL DATA IS NOW IN SQLITE
  final CustomerRepository _customerRepository = CustomerRepository();
  final ProductRepository _productRepository = ProductRepository();
  final QuoteRepository _quoteRepository = QuoteRepository();
  final AppSettingsRepository _appSettingsRepository = AppSettingsRepository();
  final TemplateCategoryRepository _templateCategoryRepository = TemplateCategoryRepository();
  final RoofScopeRepository _roofScopeRepository = RoofScopeRepository();
  final ProjectMediaRepository _projectMediaRepository = ProjectMediaRepository();
  final PDFTemplateRepository _pdfTemplateRepository = PDFTemplateRepository();
  final MessageTemplateRepository _messageTemplateRepository = MessageTemplateRepository();
  final EmailTemplateRepository _emailTemplateRepository = EmailTemplateRepository();
  final CustomAppDataFieldRepository _customAppDataFieldRepository = CustomAppDataFieldRepository();
  final InspectionDocumentRepository _inspectionDocumentRepository = InspectionDocumentRepository();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Repositories initialize themselves when first accessed
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ Database initialized successfully - SQLite only');
        await _printDatabaseStats();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing database: $e');
      }
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
  }

  /// Print database statistics
  Future<void> _printDatabaseStats() async {
    try {
      final stats = await getDatabaseStats();
      debugPrint('📊 Database Statistics:');
      debugPrint('   Customers: ${stats['customers']}');
      debugPrint('   Products: ${stats['products']}');
      debugPrint('   Quotes: ${stats['quotes']}');
      debugPrint('   App Settings: ${stats['app_settings']}');
      debugPrint('   Template Categories: ${stats['template_categories']}');
      debugPrint('   Roof Scope Data: ${stats['roof_scope_data']}');
      debugPrint('   Project Media: ${stats['project_media']}');
      debugPrint('   PDF Templates: ${stats['pdf_templates']}');
      debugPrint('   Message Templates: ${stats['message_templates']}');
      debugPrint('   Email Templates: ${stats['email_templates']}');
      debugPrint('   Custom App Data Fields: ${stats['custom_app_data_fields']}');
      debugPrint('   Inspection Documents: ${stats['inspection_documents']}');
    } catch (e) {
      debugPrint('⚠️ Could not fetch database stats: $e');
    }
  }

  /// Get comprehensive database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    _ensureInitialized();
    
    try {
      final customers = await _customerRepository.getAllCustomers();
      final products = await _productRepository.getAllProducts();
      final quotes = await _quoteRepository.getAllQuotes();
      await _appSettingsRepository.getAppSettings(); // Verify settings exist
      final templateCategories = await _templateCategoryRepository.getAllTemplateCategories();
      final roofScopeData = await _roofScopeRepository.getAllRoofScopeData();
      final projectMedia = await _projectMediaRepository.getAllProjectMedia();
      final pdfTemplates = await _pdfTemplateRepository.getAllPDFTemplates();
      final messageTemplates = await _messageTemplateRepository.getAllMessageTemplates();
      final emailTemplates = await _emailTemplateRepository.getAllEmailTemplates();
      final customAppDataFields = await _customAppDataFieldRepository.getAllCustomAppDataFields();
      final inspectionDocuments = await _inspectionDocumentRepository.getAllInspectionDocuments();

      return {
        'customers': customers.length,
        'products': products.length,
        'quotes': quotes.length,
        'app_settings': 1, // AppSettings is always present (singleton)
        'template_categories': templateCategories.length,
        'roof_scope_data': roofScopeData.length,
        'project_media': projectMedia.length,
        'pdf_templates': pdfTemplates.length,
        'message_templates': messageTemplates.length,
        'email_templates': emailTemplates.length,
        'custom_app_data_fields': customAppDataFields.length,
        'inspection_documents': inspectionDocuments.length,
        'total_records': customers.length + products.length + quotes.length + 
                        templateCategories.length + roofScopeData.length + 
                        projectMedia.length + pdfTemplates.length + 
                        messageTemplates.length + emailTemplates.length + 
                        customAppDataFields.length + inspectionDocuments.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting database stats: $e');
      return {'error': e.toString()};
    }
  }

  // ========== CUSTOMER METHODS ==========
  Future<List<Customer>> getAllCustomers() async {
    _ensureInitialized();
    return await _customerRepository.getAllCustomers();
  }

  Future<Customer?> getCustomer(String id) async {
    _ensureInitialized();
    return await _customerRepository.getCustomerById(id);
  }

  Future<void> addCustomer(Customer customer) async {
    _ensureInitialized();
    await _customerRepository.createCustomer(customer);
  }

  Future<void> updateCustomer(Customer customer) async {
    _ensureInitialized();
    await _customerRepository.updateCustomer(customer);
  }

  Future<void> deleteCustomer(String id) async {
    _ensureInitialized();
    await _customerRepository.deleteCustomer(id);
  }

  Future<void> saveCustomer(Customer customer) async {
    _ensureInitialized();
    final existing = await _customerRepository.getCustomerById(customer.id);
    if (existing != null) {
      await _customerRepository.updateCustomer(customer);
    } else {
      await _customerRepository.createCustomer(customer);
    }
  }

  // ========== PRODUCT METHODS ==========
  Future<List<Product>> getAllProducts() async {
    _ensureInitialized();
    return await _productRepository.getAllProducts();
  }

  Future<Product?> getProduct(String id) async {
    _ensureInitialized();
    return await _productRepository.getProductById(id);
  }

  Future<void> addProduct(Product product) async {
    _ensureInitialized();
    await _productRepository.createProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    _ensureInitialized();
    await _productRepository.updateProduct(product);
  }

  Future<void> deleteProduct(String id) async {
    _ensureInitialized();
    await _productRepository.deleteProduct(id);
  }

  Future<void> saveProduct(Product product) async {
    _ensureInitialized();
    final existing = await _productRepository.getProductById(product.id);
    if (existing != null) {
      await _productRepository.updateProduct(product);
    } else {
      await _productRepository.createProduct(product);
    }
  }

  // ========== QUOTE METHODS ==========
  Future<List<SimplifiedMultiLevelQuote>> getAllQuotes() async {
    _ensureInitialized();
    return await _quoteRepository.getAllQuotes();
  }

  Future<List<SimplifiedMultiLevelQuote>> getAllCurrentQuotes() async {
    _ensureInitialized();
    return await _quoteRepository.getAllCurrentQuotes();
  }

  Future<SimplifiedMultiLevelQuote?> getQuote(String id) async {
    _ensureInitialized();
    return await _quoteRepository.getQuoteById(id);
  }

  Future<void> addQuote(SimplifiedMultiLevelQuote quote) async {
    _ensureInitialized();
    await _quoteRepository.createQuote(quote);
  }

  Future<void> updateQuote(SimplifiedMultiLevelQuote quote) async {
    _ensureInitialized();
    await _quoteRepository.updateQuote(quote);
  }

  Future<void> deleteQuote(String id) async {
    _ensureInitialized();
    await _quoteRepository.deleteQuote(id);
  }

  Future<List<SimplifiedMultiLevelQuote>> getCurrentQuotesByCustomerId(String customerId) async {
    _ensureInitialized();
    return await _quoteRepository.getCurrentQuotesByCustomerId(customerId);
  }

  // Legacy method names for backward compatibility
  Future<List<SimplifiedMultiLevelQuote>> getAllSimplifiedMultiLevelQuotes() async {
    return await getAllQuotes();
  }

  Future<void> saveSimplifiedMultiLevelQuote(SimplifiedMultiLevelQuote quote) async {
    print('📀 DatabaseService.saveSimplifiedMultiLevelQuote() - Processing quote ${quote.id} v${quote.version}');
    _ensureInitialized();
    final existing = await _quoteRepository.getQuoteById(quote.id);
    if (existing != null) {
      print('📀 Found existing quote - calling updateQuote()');
      await _quoteRepository.updateQuote(quote);
    } else {
      print('📀 No existing quote - calling createQuote()');
      await _quoteRepository.createQuote(quote);
    }
    print('✅ DatabaseService.saveSimplifiedMultiLevelQuote() - Completed for quote ${quote.id}');
  }

  Future<void> deleteSimplifiedMultiLevelQuote(String id) async {
    return await deleteQuote(id);
  }

  // ========== APP SETTINGS METHODS ==========
  Future<AppSettings?> getAppSettings() async {
    _ensureInitialized();
    return await _appSettingsRepository.getAppSettings();
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    _ensureInitialized();
    await _appSettingsRepository.saveAppSettings(settings);
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    _ensureInitialized();
    await _appSettingsRepository.saveAppSettings(settings);
  }

  // ========== TEMPLATE CATEGORY METHODS ==========
  Future<List<TemplateCategory>> getAllTemplateCategories() async {
    _ensureInitialized();
    return await _templateCategoryRepository.getAllTemplateCategories();
  }

  Future<void> addTemplateCategory(TemplateCategory category) async {
    _ensureInitialized();
    await _templateCategoryRepository.createTemplateCategory(category);
  }

  Future<List<TemplateCategory>> getRawCategoriesBoxValues() async {
    _ensureInitialized();
    return await _templateCategoryRepository.getAllTemplateCategories();
  }

  Future<void> saveTemplateCategory(TemplateCategory category) async {
    _ensureInitialized();
    final existing = await _templateCategoryRepository.getTemplateCategoryById(category.id);
    if (existing != null) {
      await _templateCategoryRepository.updateTemplateCategory(category);
    } else {
      await _templateCategoryRepository.createTemplateCategory(category);
    }
  }

  Future<void> updateTemplateCategory(TemplateCategory category) async {
    _ensureInitialized();
    await _templateCategoryRepository.updateTemplateCategory(category);
  }

  Future<void> deleteTemplateCategory(String id) async {
    _ensureInitialized();
    await _templateCategoryRepository.deleteTemplateCategory(id);
  }

  Future<int> getCategoryUsageCount(String categoryId) async {
    _ensureInitialized();
    // Note: This method expects 2 parameters but we only have one
    // For now, we'll use a placeholder for the template type
    return await _templateCategoryRepository.getCategoryUsageCount('pdf_templates', categoryId);
  }

  // ========== PDF TEMPLATE METHODS ==========
  Future<List<PDFTemplate>> getAllPDFTemplates() async {
    _ensureInitialized();
    return await _pdfTemplateRepository.getAllPDFTemplates();
  }

  Future<void> addPDFTemplate(PDFTemplate template) async {
    _ensureInitialized();
    await _pdfTemplateRepository.createPDFTemplate(template);
  }

  Future<void> savePDFTemplate(PDFTemplate template) async {
    _ensureInitialized();
    final existing = await _pdfTemplateRepository.getPDFTemplateById(template.id);
    if (existing != null) {
      await _pdfTemplateRepository.updatePDFTemplate(template);
    } else {
      await _pdfTemplateRepository.createPDFTemplate(template);
    }
  }

  Future<void> deletePDFTemplate(String id) async {
    _ensureInitialized();
    await _pdfTemplateRepository.deletePDFTemplate(id);
  }

  Future<PDFTemplate?> getPDFTemplate(String id) async {
    _ensureInitialized();
    return await _pdfTemplateRepository.getPDFTemplateById(id);
  }

  Future<List<PDFTemplate>> getPDFTemplatesByType(String type) async {
    _ensureInitialized();
    return await _pdfTemplateRepository.getPDFTemplatesByFileType(type);
  }

  // ========== MESSAGE TEMPLATE METHODS ==========
  Future<List<MessageTemplate>> getAllMessageTemplates() async {
    _ensureInitialized();
    return await _messageTemplateRepository.getAllMessageTemplates();
  }

  Future<void> addMessageTemplate(MessageTemplate template) async {
    _ensureInitialized();
    await _messageTemplateRepository.createMessageTemplate(template);
  }

  Future<void> saveMessageTemplate(MessageTemplate template) async {
    _ensureInitialized();
    final existing = await _messageTemplateRepository.getMessageTemplateById(template.id);
    if (existing != null) {
      await _messageTemplateRepository.updateMessageTemplate(template);
    } else {
      await _messageTemplateRepository.createMessageTemplate(template);
    }
  }

  Future<void> deleteMessageTemplate(String id) async {
    _ensureInitialized();
    await _messageTemplateRepository.deleteMessageTemplate(id);
  }

  // ========== EMAIL TEMPLATE METHODS ==========
  Future<List<EmailTemplate>> getAllEmailTemplates() async {
    _ensureInitialized();
    return await _emailTemplateRepository.getAllEmailTemplates();
  }

  Future<void> addEmailTemplate(EmailTemplate template) async {
    _ensureInitialized();
    await _emailTemplateRepository.createEmailTemplate(template);
  }

  Future<void> saveEmailTemplate(EmailTemplate template) async {
    _ensureInitialized();
    final existing = await _emailTemplateRepository.getEmailTemplateById(template.id);
    if (existing != null) {
      await _emailTemplateRepository.updateEmailTemplate(template);
    } else {
      await _emailTemplateRepository.createEmailTemplate(template);
    }
  }

  Future<void> deleteEmailTemplate(String id) async {
    _ensureInitialized();
    await _emailTemplateRepository.deleteEmailTemplate(id);
  }

  // ========== PROJECT MEDIA METHODS ==========
  Future<List<ProjectMedia>> getAllProjectMedia() async {
    _ensureInitialized();
    return await _projectMediaRepository.getAllProjectMedia();
  }

  Future<void> addProjectMedia(ProjectMedia media) async {
    _ensureInitialized();
    await _projectMediaRepository.createProjectMedia(media);
  }

  Future<void> saveProjectMedia(ProjectMedia media) async {
    _ensureInitialized();
    final existing = await _projectMediaRepository.getProjectMediaById(media.id);
    if (existing != null) {
      await _projectMediaRepository.updateProjectMedia(media);
    } else {
      await _projectMediaRepository.createProjectMedia(media);
    }
  }

  Future<void> deleteProjectMedia(String id) async {
    _ensureInitialized();
    await _projectMediaRepository.deleteProjectMedia(id);
  }

  // ========== ROOF SCOPE DATA METHODS ==========
  Future<List<RoofScopeData>> getAllRoofScopeData() async {
    _ensureInitialized();
    return await _roofScopeRepository.getAllRoofScopeData();
  }

  Future<void> addRoofScopeData(RoofScopeData data) async {
    _ensureInitialized();
    await _roofScopeRepository.createRoofScopeData(data);
  }

  Future<void> saveRoofScopeData(RoofScopeData data) async {
    _ensureInitialized();
    final existing = await _roofScopeRepository.getRoofScopeDataById(data.id);
    if (existing != null) {
      await _roofScopeRepository.updateRoofScopeData(data);
    } else {
      await _roofScopeRepository.createRoofScopeData(data);
    }
  }

  Future<void> deleteRoofScopeData(String id) async {
    _ensureInitialized();
    await _roofScopeRepository.deleteRoofScopeData(id);
  }

  // ========== CUSTOM APP DATA FIELDS METHODS ==========
  Future<List<CustomAppDataField>> getAllCustomAppDataFields() async {
    _ensureInitialized();
    return await _customAppDataFieldRepository.getAllCustomAppDataFields();
  }

  Future<void> addCustomAppDataField(CustomAppDataField field) async {
    _ensureInitialized();
    await _customAppDataFieldRepository.createCustomAppDataField(field);
  }

  Future<void> saveCustomAppDataField(CustomAppDataField field) async {
    _ensureInitialized();
    final existing = await _customAppDataFieldRepository.getCustomAppDataFieldById(field.id);
    if (existing != null) {
      await _customAppDataFieldRepository.updateCustomAppDataField(field);
    } else {
      await _customAppDataFieldRepository.createCustomAppDataField(field);
    }
  }

  Future<void> deleteCustomAppDataField(String id) async {
    _ensureInitialized();
    await _customAppDataFieldRepository.deleteCustomAppDataField(id);
  }

  Future<void> saveMultipleCustomAppDataFields(List<CustomAppDataField> fields) async {
    _ensureInitialized();
    for (final field in fields) {
      await saveCustomAppDataField(field);
    }
  }

  // ========== INSPECTION DOCUMENT METHODS ==========
  Future<List<InspectionDocument>> getAllInspectionDocuments() async {
    _ensureInitialized();
    return await _inspectionDocumentRepository.getAllInspectionDocuments();
  }

  Future<void> addInspectionDocument(InspectionDocument document) async {
    _ensureInitialized();
    await _inspectionDocumentRepository.createInspectionDocument(document);
  }

  Future<void> saveInspectionDocument(InspectionDocument document) async {
    _ensureInitialized();
    final existing = await _inspectionDocumentRepository.getInspectionDocumentById(document.id);
    if (existing != null) {
      await _inspectionDocumentRepository.updateInspectionDocument(document);
    } else {
      await _inspectionDocumentRepository.createInspectionDocument(document);
    }
  }

  Future<void> deleteInspectionDocument(String id) async {
    _ensureInitialized();
    await _inspectionDocumentRepository.deleteInspectionDocument(id);
  }

  // ========== UTILITY METHODS ==========
  
  /// Close all database connections (cleanup)
  Future<void> close() async {
    if (!_isInitialized) return;
    
    try {
      // SQLite repositories manage their own database connections
      // No explicit close methods needed for individual repositories
      _isInitialized = false;
      debugPrint('✅ Database service closed');
    } catch (e) {
      debugPrint('⚠️ Error closing database service: $e');
    }
  }

  /// Get app information for debugging
  Future<Map<String, dynamic>> getAppInfo() async {
    try {
      final stats = await getDatabaseStats();
      return {
        'database_initialized': _isInitialized,
        'database_type': 'SQLite',
        'migration_status': 'completed',
        'statistics': stats,
      };
    } catch (e) {
      return {
        'database_initialized': _isInitialized,
        'database_type': 'SQLite',
        'migration_status': 'completed',
        'error': e.toString(),
      };
    }
  }

  /// Export all data (placeholder for future implementation)
  Future<Map<String, dynamic>> exportAllData() async {
    _ensureInitialized();
    return {
      'error': 'Export feature not yet implemented for SQLite',
      'data_available': true,
    };
  }

  /// Import all data (placeholder for future implementation)
  Future<Map<String, dynamic>> importAllData(Map<String, dynamic> data) async {
    _ensureInitialized();
    return {
      'error': 'Import feature not yet implemented for SQLite',
      'success': false,
    };
  }
}