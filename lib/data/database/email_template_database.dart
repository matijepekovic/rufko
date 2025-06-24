import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/templates/email_template.dart';

/// SQLite database operations for EmailTemplate
class EmailTemplateDatabase {
  static const String tableName = 'email_templates';
  
  /// Create email templates table
  static String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      template_name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL,
      subject TEXT NOT NULL,
      email_content TEXT NOT NULL,
      placeholders TEXT, -- JSON array
      is_active INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_html INTEGER NOT NULL DEFAULT 0,
      user_category_key TEXT,
      FOREIGN KEY (user_category_key) REFERENCES template_categories (key) ON DELETE SET NULL
    );
  ''';

  /// Create indexes for better performance
  static List<String> get createIndexesSQL => [
    'CREATE INDEX IF NOT EXISTS idx_email_templates_category ON $tableName (category);',
    'CREATE INDEX IF NOT EXISTS idx_email_templates_is_active ON $tableName (is_active);',
    'CREATE INDEX IF NOT EXISTS idx_email_templates_user_category ON $tableName (user_category_key);',
    'CREATE INDEX IF NOT EXISTS idx_email_templates_sort_order ON $tableName (sort_order);',
    'CREATE INDEX IF NOT EXISTS idx_email_templates_is_html ON $tableName (is_html);',
  ];

  /// Insert an email template
  Future<void> insertEmailTemplate(Database db, EmailTemplate template) async {
    try {
      await db.insert(
        tableName,
        _templateToMap(template),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting email template ${template.id}: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple email templates
  Future<void> insertEmailTemplatesBatch(Database db, List<EmailTemplate> templates) async {
    final batch = db.batch();
    
    for (final template in templates) {
      batch.insert(
        tableName,
        _templateToMap(template),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    try {
      await batch.commit(noResult: true);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${templates.length} email templates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting email templates batch: $e');
      }
      rethrow;
    }
  }

  /// Get email template by ID
  Future<EmailTemplate?> getEmailTemplateById(Database db, String id) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToTemplate(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email template $id: $e');
      }
      return null;
    }
  }

  /// Get all email templates
  Future<List<EmailTemplate>> getAllEmailTemplates(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'sort_order ASC, template_name ASC',
      );

      return maps.map((map) => _mapToTemplate(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all email templates: $e');
      }
      return [];
    }
  }

  /// Get active email templates
  Future<List<EmailTemplate>> getActiveEmailTemplates(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'sort_order ASC, template_name ASC',
      );

      return maps.map((map) => _mapToTemplate(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active email templates: $e');
      }
      return [];
    }
  }

  /// Get email templates by category
  Future<List<EmailTemplate>> getEmailTemplatesByCategory(Database db, String category) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'sort_order ASC, template_name ASC',
      );

      return maps.map((map) => _mapToTemplate(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email templates by category $category: $e');
      }
      return [];
    }
  }

  /// Get HTML email templates
  Future<List<EmailTemplate>> getHtmlEmailTemplates(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'is_html = ?',
        whereArgs: [1],
        orderBy: 'sort_order ASC, template_name ASC',
      );

      return maps.map((map) => _mapToTemplate(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting HTML email templates: $e');
      }
      return [];
    }
  }

  /// Search email templates
  Future<List<EmailTemplate>> searchEmailTemplates(Database db, String query) async {
    try {
      final String searchPattern = '%${query.toLowerCase()}%';
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '''
          LOWER(template_name) LIKE ? OR 
          LOWER(description) LIKE ? OR 
          LOWER(category) LIKE ? OR 
          LOWER(subject) LIKE ? OR 
          LOWER(email_content) LIKE ?
        ''',
        whereArgs: [searchPattern, searchPattern, searchPattern, searchPattern, searchPattern],
        orderBy: 'sort_order ASC, template_name ASC',
      );

      return maps.map((map) => _mapToTemplate(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching email templates: $e');
      }
      return [];
    }
  }

  /// Update email template
  Future<void> updateEmailTemplate(Database db, EmailTemplate template) async {
    try {
      final count = await db.update(
        tableName,
        _templateToMap(template),
        where: 'id = ?',
        whereArgs: [template.id],
      );
      
      if (count == 0) {
        throw Exception('Email template ${template.id} not found for update');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating email template ${template.id}: $e');
      }
      rethrow;
    }
  }

  /// Toggle email template active status
  Future<void> toggleEmailTemplateActive(Database db, String id) async {
    try {
      await db.rawUpdate('''
        UPDATE $tableName 
        SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END,
            updated_at = ?
        WHERE id = ?
      ''', [DateTime.now().toIso8601String(), id]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling email template active status $id: $e');
      }
      rethrow;
    }
  }

  /// Delete email template by ID
  Future<void> deleteEmailTemplate(Database db, String id) async {
    try {
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw Exception('Email template $id not found for deletion');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting email template $id: $e');
      }
      rethrow;
    }
  }

  /// Clear all email templates
  Future<void> clearAllEmailTemplates(Database db) async {
    try {
      await db.delete(tableName);
      if (kDebugMode) {
        debugPrint('✅ Cleared all email templates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing email templates: $e');
      }
      rethrow;
    }
  }

  /// Get email template statistics
  Future<Map<String, dynamic>> getEmailTemplateStatistics(Database db) async {
    try {
      final totalTemplates = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
      ) ?? 0;

      final activeTemplates = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE is_active = 1'),
      ) ?? 0;

      final htmlTemplates = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE is_html = 1'),
      ) ?? 0;

      final categoryStats = await db.rawQuery('''
        SELECT category, COUNT(*) as count 
        FROM $tableName 
        GROUP BY category 
        ORDER BY count DESC
      ''');

      final avgPlaceholders = await db.rawQuery('''
        SELECT AVG(json_array_length(placeholders)) as avg_placeholders 
        FROM $tableName 
        WHERE placeholders IS NOT NULL
      ''');

      return {
        'total_templates': totalTemplates,
        'active_templates': activeTemplates,
        'html_templates': htmlTemplates,
        'category_breakdown': categoryStats,
        'average_placeholders': avgPlaceholders.isNotEmpty ? avgPlaceholders.first['avg_placeholders'] : 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email template statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_templates': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Convert EmailTemplate to Map for database storage
  Map<String, dynamic> _templateToMap(EmailTemplate template) {
    return {
      'id': template.id,
      'template_name': template.templateName,
      'description': template.description,
      'category': template.category,
      'subject': template.subject,
      'email_content': template.emailContent,
      'placeholders': jsonEncode(template.placeholders),
      'is_active': template.isActive ? 1 : 0,
      'sort_order': template.sortOrder,
      'created_at': template.createdAt.toIso8601String(),
      'updated_at': template.updatedAt.toIso8601String(),
      'is_html': template.isHtml ? 1 : 0,
      'user_category_key': template.userCategoryKey,
    };
  }

  /// Convert Map from database to EmailTemplate
  EmailTemplate _mapToTemplate(Map<String, dynamic> map) {
    return EmailTemplate(
      id: map['id'] as String,
      templateName: map['template_name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      subject: map['subject'] as String,
      emailContent: map['email_content'] as String,
      placeholders: map['placeholders'] != null 
          ? List<String>.from(jsonDecode(map['placeholders'] as String))
          : [],
      isActive: (map['is_active'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isHtml: (map['is_html'] as int) == 1,
      userCategoryKey: map['user_category_key'] as String?,
    );
  }
}