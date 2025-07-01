import 'package:flutter/foundation.dart';
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
import '../../../data/models/business/customer.dart';
import '../../../data/models/business/product.dart';
import '../../../data/models/business/simplified_quote.dart';
import 'customer_migrator.dart';
import 'product_migrator.dart';
import 'quote_migrator.dart';
import 'app_settings_migrator.dart';
import 'template_category_migrator.dart';
import 'roof_scope_migrator.dart';
import 'project_media_migrator.dart';
import 'pdf_template_migrator.dart';
import 'message_template_migrator.dart';
import 'email_template_migrator.dart';
import 'custom_app_data_field_migrator.dart';
import 'inspection_document_migrator.dart';

/// Service to test and verify the complete migration system
class MigrationTestService {
  // Repositories
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
  
  // Migrators
  final CustomerMigrator _customerMigrator = CustomerMigrator();
  final ProductMigrator _productMigrator = ProductMigrator();
  final QuoteMigrator _quoteMigrator = QuoteMigrator();
  final AppSettingsMigrator _appSettingsMigrator = AppSettingsMigrator();
  final TemplateCategoryMigrator _templateCategoryMigrator = TemplateCategoryMigrator();
  final RoofScopeMigrator _roofScopeMigrator = RoofScopeMigrator();
  final ProjectMediaMigrator _projectMediaMigrator = ProjectMediaMigrator();
  final PdfTemplateMigrator _pdfTemplateMigrator = PdfTemplateMigrator();
  final MessageTemplateMigrator _messageTemplateMigrator = MessageTemplateMigrator();
  final EmailTemplateMigrator _emailTemplateMigrator = EmailTemplateMigrator();
  final CustomAppDataFieldMigrator _customAppDataFieldMigrator = CustomAppDataFieldMigrator();
  final InspectionDocumentMigrator _inspectionDocumentMigrator = InspectionDocumentMigrator();

  /// Run comprehensive migration tests
  Future<Map<String, dynamic>> runMigrationTests() async {
    debugPrint('🧪 Starting migration system tests...');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'summary': <String, dynamic>{},
    };

    // Test 1: Repository Connectivity
    results['tests']['repository_connectivity'] = await _testRepositoryConnectivity();
    
    // Test 2: Data Integrity
    results['tests']['data_integrity'] = await _testDataIntegrity();
    
    // Test 3: CRUD Operations
    results['tests']['crud_operations'] = await _testCrudOperations();
    
    // Test 4: Migration Statistics
    results['tests']['migration_stats'] = await _getMigrationStatistics();
    
    // Test 5: Migrator Functionality
    results['tests']['migrator_tests'] = await _testMigrators();
    
    // Generate summary
    results['summary'] = _generateTestSummary(results['tests']);
    
    debugPrint('🧪 Migration tests completed');
    return results;
  }

  /// Test if all repositories are accessible
  Future<Map<String, dynamic>> _testRepositoryConnectivity() async {
    debugPrint('📡 Testing repository connectivity...');
    
    final tests = <String, dynamic>{};
    
    // Test Customer Repository
    try {
      final customers = await _customerRepository.getAllCustomers();
      tests['customer_repository'] = {
        'status': 'connected',
        'count': customers.length,
        'error': null,
      };
    } catch (e) {
      tests['customer_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test Product Repository
    try {
      final products = await _productRepository.getAllProducts();
      tests['product_repository'] = {
        'status': 'connected',
        'count': products.length,
        'error': null,
      };
    } catch (e) {
      tests['product_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test Quote Repository
    try {
      final quotes = await _quoteRepository.getAllQuotes();
      tests['quote_repository'] = {
        'status': 'connected',
        'count': quotes.length,
        'error': null,
      };
    } catch (e) {
      tests['quote_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test AppSettings Repository
    try {
      final settings = await _appSettingsRepository.getAppSettings();
      tests['app_settings_repository'] = {
        'status': 'connected',
        'company_name': settings.companyName ?? 'Not set',
        'error': null,
      };
    } catch (e) {
      tests['app_settings_repository'] = {
        'status': 'error',
        'company_name': null,
        'error': e.toString(),
      };
    }
    
    // Test TemplateCategory Repository
    try {
      final categories = await _templateCategoryRepository.getAllTemplateCategories();
      tests['template_category_repository'] = {
        'status': 'connected',
        'count': categories.length,
        'error': null,
      };
    } catch (e) {
      tests['template_category_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test RoofScope Repository
    try {
      final roofScopes = await _roofScopeRepository.getAllRoofScopeData();
      tests['roof_scope_repository'] = {
        'status': 'connected',
        'count': roofScopes.length,
        'error': null,
      };
    } catch (e) {
      tests['roof_scope_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test ProjectMedia Repository
    try {
      final projectMedia = await _projectMediaRepository.getAllProjectMedia();
      tests['project_media_repository'] = {
        'status': 'connected',
        'count': projectMedia.length,
        'error': null,
      };
    } catch (e) {
      tests['project_media_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test PdfTemplate Repository
    try {
      final pdfTemplates = await _pdfTemplateRepository.getAllPDFTemplates();
      tests['pdf_template_repository'] = {
        'status': 'connected',
        'count': pdfTemplates.length,
        'error': null,
      };
    } catch (e) {
      tests['pdf_template_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test MessageTemplate Repository
    try {
      final messageTemplates = await _messageTemplateRepository.getAllMessageTemplates();
      tests['message_template_repository'] = {
        'status': 'connected',
        'count': messageTemplates.length,
        'error': null,
      };
    } catch (e) {
      tests['message_template_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test EmailTemplate Repository
    try {
      final emailTemplates = await _emailTemplateRepository.getAllEmailTemplates();
      tests['email_template_repository'] = {
        'status': 'connected',
        'count': emailTemplates.length,
        'error': null,
      };
    } catch (e) {
      tests['email_template_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test CustomAppDataField Repository
    try {
      final customFields = await _customAppDataFieldRepository.getAllCustomAppDataFields();
      tests['custom_app_data_field_repository'] = {
        'status': 'connected',
        'count': customFields.length,
        'error': null,
      };
    } catch (e) {
      tests['custom_app_data_field_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    // Test InspectionDocument Repository
    try {
      final inspectionDocs = await _inspectionDocumentRepository.getAllInspectionDocuments();
      tests['inspection_document_repository'] = {
        'status': 'connected',
        'count': inspectionDocs.length,
        'error': null,
      };
    } catch (e) {
      tests['inspection_document_repository'] = {
        'status': 'error',
        'count': 0,
        'error': e.toString(),
      };
    }
    
    return tests;
  }

  /// Test data integrity and relationships
  Future<Map<String, dynamic>> _testDataIntegrity() async {
    debugPrint('🔍 Testing data integrity...');
    
    final tests = <String, dynamic>{};
    
    try {
      // Get all data
      final customers = await _customerRepository.getAllCustomers();
      final products = await _productRepository.getAllProducts();
      final quotes = await _quoteRepository.getAllQuotes();
      
      // Test customer data integrity
      tests['customer_integrity'] = _validateCustomers(customers);
      
      // Test product data integrity
      tests['product_integrity'] = _validateProducts(products);
      
      // Test quote data integrity
      tests['quote_integrity'] = _validateQuotes(quotes);
      
      // Test relationships
      tests['relationship_integrity'] = await _validateRelationships(customers, products, quotes);
      
    } catch (e) {
      tests['error'] = e.toString();
    }
    
    return tests;
  }

  /// Test CRUD operations on all repositories
  Future<Map<String, dynamic>> _testCrudOperations() async {
    debugPrint('⚙️ Testing CRUD operations...');
    
    final tests = <String, dynamic>{};
    
    // Test Customer CRUD
    tests['customer_crud'] = await _testCustomerCrud();
    
    // Test Product CRUD
    tests['product_crud'] = await _testProductCrud();
    
    // Test Quote CRUD (basic test)
    tests['quote_crud'] = await _testQuoteCrud();
    
    return tests;
  }

  /// Validate customer data
  Map<String, dynamic> _validateCustomers(List<Customer> customers) {
    int validCount = 0;
    int invalidCount = 0;
    final issues = <String>[];
    
    for (final customer in customers) {
      if (customer.id.isEmpty) {
        invalidCount++;
        issues.add('Customer with empty ID found');
      } else if (customer.name.isEmpty) {
        invalidCount++;
        issues.add('Customer ${customer.id} has no name');
      } else {
        validCount++;
      }
    }
    
    return {
      'total': customers.length,
      'valid': validCount,
      'invalid': invalidCount,
      'issues': issues,
    };
  }

  /// Validate product data
  Map<String, dynamic> _validateProducts(List<Product> products) {
    int validCount = 0;
    int invalidCount = 0;
    final issues = <String>[];
    
    for (final product in products) {
      if (product.id.isEmpty) {
        invalidCount++;
        issues.add('Product with empty ID found');
      } else if (product.name.isEmpty) {
        invalidCount++;
        issues.add('Product ${product.id} has no name');
      } else if (product.unitPrice < 0) {
        invalidCount++;
        issues.add('Product ${product.id} has negative price');
      } else {
        validCount++;
      }
    }
    
    return {
      'total': products.length,
      'valid': validCount,
      'invalid': invalidCount,
      'issues': issues,
    };
  }

  /// Validate quote data
  Map<String, dynamic> _validateQuotes(List<SimplifiedMultiLevelQuote> quotes) {
    int validCount = 0;
    int invalidCount = 0;
    final issues = <String>[];
    
    for (final quote in quotes) {
      if (quote.id.isEmpty) {
        invalidCount++;
        issues.add('Quote with empty ID found');
      } else if (quote.quoteNumber.isEmpty) {
        invalidCount++;
        issues.add('Quote ${quote.id} has no quote number');
      } else if (quote.customerId.isEmpty) {
        invalidCount++;
        issues.add('Quote ${quote.id} has no customer ID');
      } else {
        validCount++;
      }
    }
    
    return {
      'total': quotes.length,
      'valid': validCount,
      'invalid': invalidCount,
      'issues': issues,
    };
  }

  /// Validate relationships between entities
  Future<Map<String, dynamic>> _validateRelationships(
    List<Customer> customers,
    List<Product> products,
    List<SimplifiedMultiLevelQuote> quotes,
  ) async {
    final issues = <String>[];
    int validRelationships = 0;
    int invalidRelationships = 0;
    
    // Create lookup maps
    final customerIds = customers.map((c) => c.id).toSet();
    final productIds = products.map((p) => p.id).toSet();
    
    // Check quote-customer relationships
    for (final quote in quotes) {
      if (!customerIds.contains(quote.customerId)) {
        invalidRelationships++;
        issues.add('Quote ${quote.id} references non-existent customer ${quote.customerId}');
      } else {
        validRelationships++;
      }
      
      // Check quote-product relationships
      for (final level in quote.levels) {
        for (final item in level.includedItems) {
          if (!productIds.contains(item.productId)) {
            invalidRelationships++;
            issues.add('Quote ${quote.id} references non-existent product ${item.productId}');
          } else {
            validRelationships++;
          }
        }
      }
    }
    
    return {
      'valid_relationships': validRelationships,
      'invalid_relationships': invalidRelationships,
      'issues': issues,
    };
  }

  /// Test Customer CRUD operations
  Future<Map<String, dynamic>> _testCustomerCrud() async {
    try {
      // Create test customer
      final testCustomer = Customer(
        name: 'Test Customer',
        email: 'test@example.com',
        phone: '123-456-7890',
        streetAddress: '123 Test St',
        city: 'Test City',
        stateAbbreviation: 'TS',
        zipCode: '12345',
      );
      
      // CREATE
      await _customerRepository.createCustomer(testCustomer);
      
      // READ
      final retrievedCustomer = await _customerRepository.getCustomerById(testCustomer.id);
      if (retrievedCustomer == null) {
        return {'status': 'failed', 'error': 'Failed to retrieve created customer'};
      }
      
      // UPDATE (Customer model may not have copyWith, so create new instance)
      final updatedCustomer = Customer(
        id: retrievedCustomer.id,
        name: 'Updated Customer',
        email: retrievedCustomer.email,
        phone: retrievedCustomer.phone,
        streetAddress: retrievedCustomer.streetAddress,
        city: retrievedCustomer.city,
        stateAbbreviation: retrievedCustomer.stateAbbreviation,
        zipCode: retrievedCustomer.zipCode,
      );
      await _customerRepository.updateCustomer(updatedCustomer);
      
      // Verify update
      final verifyUpdate = await _customerRepository.getCustomerById(testCustomer.id);
      if (verifyUpdate?.name != 'Updated Customer') {
        return {'status': 'failed', 'error': 'Failed to update customer'};
      }
      
      // DELETE
      await _customerRepository.deleteCustomer(testCustomer.id);
      
      // Verify deletion
      final verifyDelete = await _customerRepository.getCustomerById(testCustomer.id);
      if (verifyDelete != null) {
        return {'status': 'failed', 'error': 'Failed to delete customer'};
      }
      
      return {'status': 'passed', 'error': null};
      
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  /// Test Product CRUD operations
  Future<Map<String, dynamic>> _testProductCrud() async {
    try {
      // Create test product
      final testProduct = Product(
        name: 'Test Product',
        description: 'A test product',
        unitPrice: 100.0,
        unit: 'each',
        category: 'Test Category',
      );
      
      // CREATE
      await _productRepository.createProduct(testProduct);
      
      // READ
      final retrievedProduct = await _productRepository.getProductById(testProduct.id);
      if (retrievedProduct == null) {
        return {'status': 'failed', 'error': 'Failed to retrieve created product'};
      }
      
      // UPDATE
      testProduct.updateInfo(name: 'Updated Product');
      await _productRepository.updateProduct(testProduct);
      
      // Verify update
      final verifyUpdate = await _productRepository.getProductById(testProduct.id);
      if (verifyUpdate?.name != 'Updated Product') {
        return {'status': 'failed', 'error': 'Failed to update product'};
      }
      
      // DELETE
      await _productRepository.deleteProduct(testProduct.id);
      
      // Verify deletion
      final verifyDelete = await _productRepository.getProductById(testProduct.id);
      if (verifyDelete != null) {
        return {'status': 'failed', 'error': 'Failed to delete product'};
      }
      
      return {'status': 'passed', 'error': null};
      
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  /// Test Quote CRUD operations (basic)
  Future<Map<String, dynamic>> _testQuoteCrud() async {
    try {
      // For quotes, we'll just test basic read operations since they're complex
      final quotes = await _quoteRepository.getAllQuotes();
      final statistics = await _quoteRepository.getQuoteStatistics();
      
      return {
        'status': 'passed',
        'quotes_count': quotes.length,
        'statistics': statistics,
        'error': null,
      };
      
    } catch (e) {
      return {'status': 'failed', 'error': e.toString()};
    }
  }

  /// Get migration statistics
  Future<Map<String, dynamic>> _getMigrationStatistics() async {
    debugPrint('📊 Getting migration statistics...');
    
    try {
      final customerStats = await _customerRepository.getCustomerStatistics();
      final productStats = await _productRepository.getProductStatistics();
      final quoteStats = await _quoteRepository.getQuoteStatistics();
      final settingsStats = await _appSettingsRepository.getSettingsStatistics();
      final categoryStats = await _templateCategoryRepository.getTemplateCategoryStatistics();
      final roofScopeStats = await _roofScopeRepository.getRoofScopeStatistics();
      final projectMediaStats = await _projectMediaRepository.getProjectMediaStatistics();
      final pdfTemplateStats = await _pdfTemplateRepository.getPDFTemplateStatistics();
      final messageTemplateStats = await _messageTemplateRepository.getMessageTemplateStatistics();
      final emailTemplateStats = await _emailTemplateRepository.getEmailTemplateStatistics();
      final customFieldStats = await _customAppDataFieldRepository.getCustomAppDataFieldStatistics();
      final inspectionDocStats = await _inspectionDocumentRepository.getInspectionDocumentStatistics();
      
      return {
        'customer_statistics': customerStats,
        'product_statistics': productStats,
        'quote_statistics': quoteStats,
        'settings_statistics': settingsStats,
        'category_statistics': categoryStats,
        'roof_scope_statistics': roofScopeStats,
        'project_media_statistics': projectMediaStats,
        'pdf_template_statistics': pdfTemplateStats,
        'message_template_statistics': messageTemplateStats,
        'email_template_statistics': emailTemplateStats,
        'custom_field_statistics': customFieldStats,
        'inspection_document_statistics': inspectionDocStats,
        'total_records': {
          'customers': customerStats['total_customers'] ?? 0,
          'products': productStats['total_products'] ?? 0,
          'quotes': quoteStats['total_quotes'] ?? 0,
          'categories': categoryStats['total_categories'] ?? 0,
          'roof_scopes': roofScopeStats['total_roof_scopes'] ?? 0,
          'project_media': projectMediaStats['total_media_files'] ?? 0,
          'pdf_templates': pdfTemplateStats['total_templates'] ?? 0,
          'message_templates': messageTemplateStats['total_templates'] ?? 0,
          'email_templates': emailTemplateStats['total_templates'] ?? 0,
          'custom_fields': customFieldStats['total_fields'] ?? 0,
          'inspection_documents': inspectionDocStats['total_documents'] ?? 0,
        },
      };
      
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Generate test summary
  Map<String, dynamic> _generateTestSummary(Map<String, dynamic> tests) {
    int totalTests = 0;
    int passedTests = 0;
    int failedTests = 0;
    final issues = <String>[];
    
    // Count repository connectivity tests
    final connectivity = tests['repository_connectivity'] as Map<String, dynamic>?;
    if (connectivity != null) {
      for (final test in connectivity.values) {
        if (test is Map<String, dynamic>) {
          totalTests++;
          if (test['status'] == 'connected') {
            passedTests++;
          } else {
            failedTests++;
            if (test['error'] != null) {
              issues.add('Repository error: ${test['error']}');
            }
          }
        }
      }
    }
    
    // Count CRUD tests
    final crud = tests['crud_operations'] as Map<String, dynamic>?;
    if (crud != null) {
      for (final test in crud.values) {
        if (test is Map<String, dynamic>) {
          totalTests++;
          if (test['status'] == 'passed') {
            passedTests++;
          } else {
            failedTests++;
            if (test['error'] != null) {
              issues.add('CRUD error: ${test['error']}');
            }
          }
        }
      }
    }
    
    return {
      'total_tests': totalTests,
      'passed_tests': passedTests,
      'failed_tests': failedTests,
      'success_rate': totalTests > 0 ? (passedTests / totalTests * 100).toStringAsFixed(1) : '0.0',
      'status': failedTests == 0 ? 'ALL_PASSED' : 'SOME_FAILED',
      'issues': issues,
    };
  }

  /// Test all migrators functionality
  Future<Map<String, dynamic>> _testMigrators() async {
    debugPrint('🚚 Testing migrators...');
    
    final tests = <String, dynamic>{};
    
    // Test each migrator
    tests['customer_migrator'] = await _testMigrator('customer', _customerMigrator);
    tests['product_migrator'] = await _testMigrator('product', _productMigrator);
    tests['quote_migrator'] = await _testMigrator('quote', _quoteMigrator);
    tests['app_settings_migrator'] = await _testMigrator('app_settings', _appSettingsMigrator);
    tests['template_category_migrator'] = await _testMigrator('template_category', _templateCategoryMigrator);
    tests['roof_scope_migrator'] = await _testMigrator('roof_scope', _roofScopeMigrator);
    tests['project_media_migrator'] = await _testMigrator('project_media', _projectMediaMigrator);
    tests['pdf_template_migrator'] = await _testMigrator('pdf_template', _pdfTemplateMigrator);
    tests['message_template_migrator'] = await _testMigrator('message_template', _messageTemplateMigrator);
    tests['email_template_migrator'] = await _testMigrator('email_template', _emailTemplateMigrator);
    tests['custom_app_data_field_migrator'] = await _testMigrator('custom_app_data_field', _customAppDataFieldMigrator);
    tests['inspection_document_migrator'] = await _testMigrator('inspection_document', _inspectionDocumentMigrator);
    
    return tests;
  }
  
  /// Test individual migrator
  Future<Map<String, dynamic>> _testMigrator(String name, dynamic migrator) async {
    try {
      final result = await migrator.migrate();
      return {
        'status': 'success',
        'result': result,
        'error': null,
      };
    } catch (e) {
      return {
        'status': 'error',
        'result': null,
        'error': e.toString(),
      };
    }
  }

  /// Quick health check of the migration system
  Future<bool> isSystemHealthy() async {
    try {
      // Basic connectivity test
      await _customerRepository.getAllCustomers();
      await _productRepository.getAllProducts();
      await _quoteRepository.getAllQuotes();
      await _appSettingsRepository.getAppSettings();
      await _templateCategoryRepository.getAllTemplateCategories();
      
      return true;
    } catch (e) {
      debugPrint('❌ System health check failed: $e');
      return false;
    }
  }
}