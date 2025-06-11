import 'package:flutter/foundation.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/simplified_quote.dart';
import '../../models/roof_scope_data.dart';
import '../../models/project_media.dart';
import '../../models/pdf_template.dart';
import '../../models/message_template.dart';
import '../../models/email_template.dart';
import '../../models/custom_app_data.dart';
import '../../models/template_category.dart';
import '../../models/inspection_document.dart';
import '../../services/database_service.dart';

/// Helper class for loading various pieces of application data from the
/// [DatabaseService]. Each method catches and logs errors, returning an empty
/// list when loading fails so the caller can handle failures gracefully.
class DataLoadingHelper {
  static Future<List<Customer>> loadCustomers(DatabaseService db) async {
    try {
      return await db.getAllCustomers();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading customers: $e');
      return [];
    }
  }

  static Future<List<Product>> loadProducts(DatabaseService db) async {
    try {
      return await db.getAllProducts();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading products: $e');
      return [];
    }
  }

  static Future<List<SimplifiedMultiLevelQuote>> loadSimplifiedQuotes(
      DatabaseService db) async {
    try {
      return await db.getAllSimplifiedMultiLevelQuotes();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading quotes: $e');
      return [];
    }
  }

  static Future<List<RoofScopeData>> loadRoofScopeData(
      DatabaseService db) async {
    try {
      return await db.getAllRoofScopeData();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading roof scope data: $e');
      return [];
    }
  }

  static Future<List<ProjectMedia>> loadProjectMedia(DatabaseService db) async {
    try {
      return await db.getAllProjectMedia();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading project media: $e');
      return [];
    }
  }

  static Future<List<PDFTemplate>> loadPDFTemplates(DatabaseService db) async {
    try {
      final templates = await db.getAllPDFTemplates();
      if (kDebugMode) {
        debugPrint('📄 Loaded ${templates.length} PDF templates');
      }
      return templates;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading PDF templates: $e');
      return [];
    }
  }

  static Future<List<MessageTemplate>> loadMessageTemplates(
      DatabaseService db) async {
    try {
      final templates = await db.getAllMessageTemplates();
      if (kDebugMode) {
        debugPrint('💬 Loaded ${templates.length} message templates');
      }
      return templates;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading message templates: $e');
      return [];
    }
  }

  static Future<List<EmailTemplate>> loadEmailTemplates(
      DatabaseService db) async {
    try {
      final templates = await db.getAllEmailTemplates();
      if (kDebugMode) {
        debugPrint('📧 Loaded ${templates.length} email templates');
      }
      return templates;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading email templates: $e');
      return [];
    }
  }

  static Future<List<CustomAppDataField>> loadCustomAppDataFields(
      DatabaseService db) async {
    try {
      return await db.getAllCustomAppDataFields();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading custom app data fields: $e');
      return [];
    }
  }

  static Future<List<InspectionDocument>> loadInspectionDocuments(
      DatabaseService db) async {
    try {
      final docs = await DatabaseService.instance.getAllInspectionDocuments();
      if (kDebugMode) {
        debugPrint('✅ Loaded ${docs.length} inspection documents');
      }
      return docs;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading inspection documents: $e');
      return [];
    }
  }

  static Future<List<TemplateCategory>> loadTemplateCategories(
      DatabaseService db) async {
    try {
      final categories = db.getRawCategoriesBoxValues();
      if (kDebugMode) {
        debugPrint("📚 Loaded ${categories.length} template categories");
      }
      return categories;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading template categories: $e");
      }
      return [];
    }
  }

  
}
