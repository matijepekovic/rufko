import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/templates/pdf_template.dart';

/// SQLite database operations for PDFTemplate and FieldMapping
class PdfTemplateDatabase {
  static const String templatesTable = 'pdf_templates';
  static const String fieldMappingsTable = 'pdf_field_mappings';
  
  /// Create PDF templates table
  static String get createTemplatesTableSQL => '''
    CREATE TABLE IF NOT EXISTS $templatesTable (
      id TEXT PRIMARY KEY,
      template_name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      pdf_file_path TEXT NOT NULL,
      template_type TEXT NOT NULL DEFAULT 'quote',
      page_width REAL NOT NULL,
      page_height REAL NOT NULL,
      total_pages INTEGER NOT NULL DEFAULT 1,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      metadata TEXT, -- JSON field
      user_category_key TEXT,
      FOREIGN KEY (user_category_key) REFERENCES template_categories (key) ON DELETE SET NULL
    );
  ''';

  /// Create field mappings table
  static String get createFieldMappingsTableSQL => '''
    CREATE TABLE IF NOT EXISTS $fieldMappingsTable (
      field_id TEXT PRIMARY KEY,
      template_id TEXT NOT NULL,
      app_data_type TEXT NOT NULL,
      pdf_form_field_name TEXT NOT NULL,
      detected_pdf_field_type INTEGER NOT NULL DEFAULT 0,
      visual_x REAL,
      visual_y REAL,
      visual_width REAL,
      visual_height REAL,
      page_number INTEGER NOT NULL DEFAULT 0,
      font_family_override TEXT,
      font_size_override REAL,
      font_color_override TEXT,
      alignment_override TEXT,
      additional_properties TEXT, -- JSON field
      FOREIGN KEY (template_id) REFERENCES $templatesTable (id) ON DELETE CASCADE
    );
  ''';

  /// Create indexes for better performance
  static List<String> get createIndexesSQL => [
    'CREATE INDEX IF NOT EXISTS idx_pdf_templates_template_type ON $templatesTable (template_type);',
    'CREATE INDEX IF NOT EXISTS idx_pdf_templates_is_active ON $templatesTable (is_active);',
    'CREATE INDEX IF NOT EXISTS idx_pdf_templates_user_category ON $templatesTable (user_category_key);',
    'CREATE INDEX IF NOT EXISTS idx_pdf_field_mappings_template_id ON $fieldMappingsTable (template_id);',
    'CREATE INDEX IF NOT EXISTS idx_pdf_field_mappings_app_data_type ON $fieldMappingsTable (app_data_type);',
  ];

  /// Insert a PDF template with its field mappings
  Future<void> insertPdfTemplate(Database db, PDFTemplate template) async {
    try {
      await db.transaction((txn) async {
        // Insert template
        await txn.insert(
          templatesTable,
          _templateToMap(template),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert field mappings
        for (final fieldMapping in template.fieldMappings) {
          await txn.insert(
            fieldMappingsTable,
            _fieldMappingToMap(fieldMapping, template.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting PDF template ${template.id}: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple PDF templates
  Future<void> insertPdfTemplatesBatch(Database db, List<PDFTemplate> templates) async {
    try {
      await db.transaction((txn) async {
        for (final template in templates) {
          // Insert template
          await txn.insert(
            templatesTable,
            _templateToMap(template),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert field mappings
          for (final fieldMapping in template.fieldMappings) {
            await txn.insert(
              fieldMappingsTable,
              _fieldMappingToMap(fieldMapping, template.id),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      
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

  /// Get PDF template by ID with field mappings
  Future<PDFTemplate?> getPdfTemplateById(Database db, String id) async {
    try {
      // Get template
      final List<Map<String, dynamic>> templateMaps = await db.query(
        templatesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (templateMaps.isEmpty) return null;

      // Get field mappings
      final List<Map<String, dynamic>> fieldMaps = await db.query(
        fieldMappingsTable,
        where: 'template_id = ?',
        whereArgs: [id],
        orderBy: 'page_number, visual_y, visual_x',
      );

      return _mapToTemplate(templateMaps.first, fieldMaps);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF template $id: $e');
      }
      return null;
    }
  }

  /// Get all PDF templates with field mappings
  Future<List<PDFTemplate>> getAllPdfTemplates(Database db) async {
    try {
      final List<Map<String, dynamic>> templateMaps = await db.query(
        templatesTable,
        orderBy: 'template_name ASC',
      );

      final List<PDFTemplate> templates = [];
      
      for (final templateMap in templateMaps) {
        final templateId = templateMap['id'] as String;
        
        final List<Map<String, dynamic>> fieldMaps = await db.query(
          fieldMappingsTable,
          where: 'template_id = ?',
          whereArgs: [templateId],
          orderBy: 'page_number, visual_y, visual_x',
        );

        templates.add(_mapToTemplate(templateMap, fieldMaps));
      }

      return templates;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all PDF templates: $e');
      }
      return [];
    }
  }

  /// Get PDF templates by type
  Future<List<PDFTemplate>> getPdfTemplatesByType(Database db, String templateType) async {
    try {
      final List<Map<String, dynamic>> templateMaps = await db.query(
        templatesTable,
        where: 'template_type = ?',
        whereArgs: [templateType],
        orderBy: 'template_name ASC',
      );

      final List<PDFTemplate> templates = [];
      
      for (final templateMap in templateMaps) {
        final templateId = templateMap['id'] as String;
        
        final List<Map<String, dynamic>> fieldMaps = await db.query(
          fieldMappingsTable,
          where: 'template_id = ?',
          whereArgs: [templateId],
          orderBy: 'page_number, visual_y, visual_x',
        );

        templates.add(_mapToTemplate(templateMap, fieldMaps));
      }

      return templates;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF templates by type $templateType: $e');
      }
      return [];
    }
  }

  /// Get active PDF templates
  Future<List<PDFTemplate>> getActivePdfTemplates(Database db) async {
    try {
      final List<Map<String, dynamic>> templateMaps = await db.query(
        templatesTable,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'template_name ASC',
      );

      final List<PDFTemplate> templates = [];
      
      for (final templateMap in templateMaps) {
        final templateId = templateMap['id'] as String;
        
        final List<Map<String, dynamic>> fieldMaps = await db.query(
          fieldMappingsTable,
          where: 'template_id = ?',
          whereArgs: [templateId],
          orderBy: 'page_number, visual_y, visual_x',
        );

        templates.add(_mapToTemplate(templateMap, fieldMaps));
      }

      return templates;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active PDF templates: $e');
      }
      return [];
    }
  }

  /// Update PDF template
  Future<void> updatePdfTemplate(Database db, PDFTemplate template) async {
    try {
      await db.transaction((txn) async {
        // Update template
        final count = await txn.update(
          templatesTable,
          _templateToMap(template),
          where: 'id = ?',
          whereArgs: [template.id],
        );
        
        if (count == 0) {
          throw Exception('PDF template ${template.id} not found for update');
        }

        // Delete existing field mappings
        await txn.delete(
          fieldMappingsTable,
          where: 'template_id = ?',
          whereArgs: [template.id],
        );

        // Insert updated field mappings
        for (final fieldMapping in template.fieldMappings) {
          await txn.insert(
            fieldMappingsTable,
            _fieldMappingToMap(fieldMapping, template.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating PDF template ${template.id}: $e');
      }
      rethrow;
    }
  }

  /// Delete PDF template by ID
  Future<void> deletePdfTemplate(Database db, String id) async {
    try {
      await db.transaction((txn) async {
        // Delete field mappings first (foreign key constraint)
        await txn.delete(
          fieldMappingsTable,
          where: 'template_id = ?',
          whereArgs: [id],
        );

        // Delete template
        final count = await txn.delete(
          templatesTable,
          where: 'id = ?',
          whereArgs: [id],
        );
        
        if (count == 0) {
          throw Exception('PDF template $id not found for deletion');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting PDF template $id: $e');
      }
      rethrow;
    }
  }

  /// Clear all PDF templates
  Future<void> clearAllPdfTemplates(Database db) async {
    try {
      await db.transaction((txn) async {
        await txn.delete(fieldMappingsTable);
        await txn.delete(templatesTable);
      });
      
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
  Future<Map<String, dynamic>> getPdfTemplateStatistics(Database db) async {
    try {
      final totalTemplates = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $templatesTable'),
      ) ?? 0;

      final activeTemplates = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $templatesTable WHERE is_active = 1'),
      ) ?? 0;

      final totalFieldMappings = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $fieldMappingsTable'),
      ) ?? 0;

      final typeStats = await db.rawQuery('''
        SELECT template_type, COUNT(*) as count 
        FROM $templatesTable 
        GROUP BY template_type 
        ORDER BY count DESC
      ''');

      return {
        'total_templates': totalTemplates,
        'active_templates': activeTemplates,
        'total_field_mappings': totalFieldMappings,
        'template_types': typeStats,
        'timestamp': DateTime.now().toIso8601String(),
      };
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

  /// Convert PDFTemplate to Map for database storage
  Map<String, dynamic> _templateToMap(PDFTemplate template) {
    return {
      'id': template.id,
      'template_name': template.templateName,
      'description': template.description,
      'pdf_file_path': template.pdfFilePath,
      'template_type': template.templateType,
      'page_width': template.pageWidth,
      'page_height': template.pageHeight,
      'total_pages': template.totalPages,
      'is_active': template.isActive ? 1 : 0,
      'created_at': template.createdAt.toIso8601String(),
      'updated_at': template.updatedAt.toIso8601String(),
      'metadata': jsonEncode(template.metadata),
      'user_category_key': template.userCategoryKey,
    };
  }

  /// Convert FieldMapping to Map for database storage
  Map<String, dynamic> _fieldMappingToMap(FieldMapping fieldMapping, String templateId) {
    return {
      'field_id': fieldMapping.fieldId,
      'template_id': templateId,
      'app_data_type': fieldMapping.appDataType,
      'pdf_form_field_name': fieldMapping.pdfFormFieldName,
      'detected_pdf_field_type': fieldMapping.detectedPdfFieldType.index,
      'visual_x': fieldMapping.visualX,
      'visual_y': fieldMapping.visualY,
      'visual_width': fieldMapping.visualWidth,
      'visual_height': fieldMapping.visualHeight,
      'page_number': fieldMapping.pageNumber,
      'font_family_override': fieldMapping.fontFamilyOverride,
      'font_size_override': fieldMapping.fontSizeOverride,
      'font_color_override': fieldMapping.fontColorOverride,
      'alignment_override': fieldMapping.alignmentOverride,
      'additional_properties': jsonEncode(fieldMapping.additionalProperties),
    };
  }

  /// Convert Map from database to PDFTemplate
  PDFTemplate _mapToTemplate(Map<String, dynamic> templateMap, List<Map<String, dynamic>> fieldMaps) {
    final fieldMappings = fieldMaps.map((fieldMap) => _mapToFieldMapping(fieldMap)).toList();

    return PDFTemplate(
      id: templateMap['id'] as String,
      templateName: templateMap['template_name'] as String,
      description: templateMap['description'] as String? ?? '',
      pdfFilePath: templateMap['pdf_file_path'] as String,
      templateType: templateMap['template_type'] as String? ?? 'quote',
      pageWidth: (templateMap['page_width'] as num).toDouble(),
      pageHeight: (templateMap['page_height'] as num).toDouble(),
      totalPages: templateMap['total_pages'] as int? ?? 1,
      fieldMappings: fieldMappings,
      isActive: (templateMap['is_active'] as int) == 1,
      createdAt: DateTime.parse(templateMap['created_at'] as String),
      updatedAt: DateTime.parse(templateMap['updated_at'] as String),
      metadata: templateMap['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(templateMap['metadata'] as String))
          : {},
      userCategoryKey: templateMap['user_category_key'] as String?,
    );
  }

  /// Convert Map from database to FieldMapping
  FieldMapping _mapToFieldMapping(Map<String, dynamic> map) {
    return FieldMapping(
      fieldId: map['field_id'] as String,
      appDataType: map['app_data_type'] as String,
      pdfFormFieldName: map['pdf_form_field_name'] as String,
      detectedPdfFieldType: PdfFormFieldType.values[map['detected_pdf_field_type'] as int],
      visualX: (map['visual_x'] as num?)?.toDouble(),
      visualY: (map['visual_y'] as num?)?.toDouble(),
      visualWidth: (map['visual_width'] as num?)?.toDouble(),
      visualHeight: (map['visual_height'] as num?)?.toDouble(),
      pageNumber: map['page_number'] as int? ?? 0,
      fontFamilyOverride: map['font_family_override'] as String?,
      fontSizeOverride: (map['font_size_override'] as num?)?.toDouble(),
      fontColorOverride: map['font_color_override'] as String?,
      alignmentOverride: map['alignment_override'] as String?,
      additionalProperties: map['additional_properties'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['additional_properties'] as String))
          : {},
    );
  }
}