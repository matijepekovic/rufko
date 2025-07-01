import 'package:flutter/foundation.dart';
import '../models/templates/pdf_template.dart';
import '../database/pdf_template_database.dart';
import '../database/database_helper.dart';

/// Repository for PDFTemplate operations using SQLite
class PDFTemplateRepository {
  final PdfTemplateDatabase _database = PdfTemplateDatabase();

  /// Create a new PDF template
  Future<void> createPDFTemplate(PDFTemplate template) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertPdfTemplate(db, template);
      if (kDebugMode) {
        debugPrint('✅ Created PDF template: ${template.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating PDF template: $e');
      }
      rethrow;
    }
  }

  /// Get PDF template by ID
  Future<PDFTemplate?> getPDFTemplateById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getPdfTemplateById(db, id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF template $id: $e');
      }
      return null;
    }
  }

  /// Get all PDF templates
  Future<List<PDFTemplate>> getAllPDFTemplates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getAllPdfTemplates(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all PDF templates: $e');
      }
      return [];
    }
  }

  /// Get PDF templates by category
  Future<List<PDFTemplate>> getPDFTemplatesByCategory(String? categoryId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getPdfTemplatesByType(db, categoryId ?? 'quote');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF templates for category $categoryId: $e');
      }
      return [];
    }
  }

  /// Update PDF template
  Future<void> updatePDFTemplate(PDFTemplate template) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.updatePdfTemplate(db, template);
      if (kDebugMode) {
        debugPrint('✅ Updated PDF template: ${template.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating PDF template: $e');
      }
      rethrow;
    }
  }

  /// Delete PDF template by ID
  Future<void> deletePDFTemplate(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deletePdfTemplate(db, id);
      if (kDebugMode) {
        debugPrint('✅ Deleted PDF template: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting PDF template: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple PDF templates
  Future<void> insertPDFTemplatesBatch(List<PDFTemplate> templates) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertPdfTemplatesBatch(db, templates);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${templates.length} PDF templates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting PDF templates batch: $e');
      }
      rethrow;
    }
  }

  /// Clear all PDF templates
  Future<void> clearAllPDFTemplates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.clearAllPdfTemplates(db);
      if (kDebugMode) {
        debugPrint('✅ Cleared all PDF templates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing PDF templates: $e');
      }
      rethrow;
    }
  }

  /// Get PDF template statistics
  Future<Map<String, dynamic>> getPDFTemplateStatistics() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getPdfTemplateStatistics(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF template statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_templates': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Search PDF templates by name
  Future<List<PDFTemplate>> searchByName(String searchTerm) async {
    try {
      final allTemplates = await getAllPDFTemplates();
      return allTemplates.where((template) {
        return template.templateName.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching PDF templates by name: $e');
      }
      return [];
    }
  }

  /// Get PDF templates by file type
  Future<List<PDFTemplate>> getPDFTemplatesByFileType(String fileType) async {
    try {
      final allTemplates = await getAllPDFTemplates();
      return allTemplates.where((template) => template.templateType == fileType).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF templates by file type: $e');
      }
      return [];
    }
  }

  /// Get active PDF templates only
  Future<List<PDFTemplate>> getActivePDFTemplates() async {
    try {
      final allTemplates = await getAllPDFTemplates();
      return allTemplates.where((template) => template.isActive).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active PDF templates: $e');
      }
      return [];
    }
  }

  /// Get PDF template size summary
  Future<Map<String, dynamic>> getTemplateSizeSummary() async {
    try {
      final templates = await getAllPDFTemplates();
      
      if (templates.isEmpty) {
        return {
          'total_templates': 0,
          'total_size_bytes': 0,
          'average_size_bytes': 0,
          'largest_template': null,
          'file_type_breakdown': <String, int>{},
        };
      }

      final fileTypeBreakdown = <String, int>{};
      for (final template in templates) {
        fileTypeBreakdown[template.templateType] = (fileTypeBreakdown[template.templateType] ?? 0) + 1;
      }

      return {
        'total_templates': templates.length,
        'total_size_bytes': 0,
        'average_size_bytes': 0,
        'largest_template': {
          'id': templates.first.id,
          'name': templates.first.templateName,
          'size_bytes': 0,
        },
        'file_type_breakdown': fileTypeBreakdown,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting template size summary: $e');
      }
      return {
        'error': e.toString(),
        'total_templates': 0,
      };
    }
  }

  /// Get recent PDF templates (last 30 days)
  Future<List<PDFTemplate>> getRecentPDFTemplates() async {
    try {
      final allTemplates = await getAllPDFTemplates();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      return allTemplates.where((template) => template.createdAt.isAfter(thirtyDaysAgo)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recent PDF templates: $e');
      }
      return [];
    }
  }

  /// Get PDF templates with field mappings count
  Future<List<Map<String, dynamic>>> getPDFTemplatesWithMappingCount() async {
    try {
      final templates = await getAllPDFTemplates();
      
      return templates.map((template) => {
        'template': template,
        'field_mapping_count': template.fieldMappings.length,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF templates with mapping count: $e');
      }
      return [];
    }
  }
}