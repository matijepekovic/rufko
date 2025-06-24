import 'package:flutter/foundation.dart';
import '../models/templates/email_template.dart';
import '../database/email_template_database.dart';
import '../database/database_helper.dart';

/// Repository for EmailTemplate operations using SQLite
class EmailTemplateRepository {
  final EmailTemplateDatabase _database = EmailTemplateDatabase();

  /// Create a new email template
  Future<void> createEmailTemplate(EmailTemplate template) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertEmailTemplate(db, template);
      if (kDebugMode) {
        debugPrint('✅ Created email template: ${template.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating email template: $e');
      }
      rethrow;
    }
  }

  /// Get email template by ID
  Future<EmailTemplate?> getEmailTemplateById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getEmailTemplateById(db, id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email template $id: $e');
      }
      return null;
    }
  }

  /// Get all email templates
  Future<List<EmailTemplate>> getAllEmailTemplates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getAllEmailTemplates(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all email templates: $e');
      }
      return [];
    }
  }

  /// Get email templates by category
  Future<List<EmailTemplate>> getEmailTemplatesByCategory(String category) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getEmailTemplatesByCategory(db, category);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email templates for category $category: $e');
      }
      return [];
    }
  }

  /// Update email template
  Future<void> updateEmailTemplate(EmailTemplate template) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.updateEmailTemplate(db, template);
      if (kDebugMode) {
        debugPrint('✅ Updated email template: ${template.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating email template: $e');
      }
      rethrow;
    }
  }

  /// Delete email template by ID
  Future<void> deleteEmailTemplate(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteEmailTemplate(db, id);
      if (kDebugMode) {
        debugPrint('✅ Deleted email template: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting email template: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple email templates
  Future<void> insertEmailTemplatesBatch(List<EmailTemplate> templates) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertEmailTemplatesBatch(db, templates);
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

  /// Clear all email templates
  Future<void> clearAllEmailTemplates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.clearAllEmailTemplates(db);
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
  Future<Map<String, dynamic>> getEmailTemplateStatistics() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getEmailTemplateStatistics(db);
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

  /// Search email templates by name
  Future<List<EmailTemplate>> searchByName(String searchTerm) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.searchEmailTemplates(db, searchTerm);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching email templates by name: $e');
      }
      return [];
    }
  }

  /// Search email templates by subject
  Future<List<EmailTemplate>> searchBySubject(String searchTerm) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.searchEmailTemplates(db, searchTerm);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching email templates by subject: $e');
      }
      return [];
    }
  }

  /// Search email templates by body content
  Future<List<EmailTemplate>> searchByBody(String searchTerm) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.searchEmailTemplates(db, searchTerm);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching email templates by body: $e');
      }
      return [];
    }
  }

  /// Get email templates by placeholder
  Future<List<EmailTemplate>> getEmailTemplatesByPlaceholder(String placeholder) async {
    try {
      final allTemplates = await getAllEmailTemplates();
      return allTemplates.where((template) {
        return template.placeholders.contains(placeholder);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email templates by placeholder: $e');
      }
      return [];
    }
  }

  /// Get HTML email templates only
  Future<List<EmailTemplate>> getHtmlEmailTemplates() async {
    try {
      final allTemplates = await getAllEmailTemplates();
      return allTemplates.where((template) => template.isHtml).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting HTML email templates: $e');
      }
      return [];
    }
  }

  /// Get plain text email templates only
  Future<List<EmailTemplate>> getPlainTextEmailTemplates() async {
    try {
      final allTemplates = await getAllEmailTemplates();
      return allTemplates.where((template) => !template.isHtml).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting plain text email templates: $e');
      }
      return [];
    }
  }

  /// Get active email templates only
  Future<List<EmailTemplate>> getActiveEmailTemplates() async {
    try {
      final allTemplates = await getAllEmailTemplates();
      return allTemplates.where((template) => template.isActive).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active email templates: $e');
      }
      return [];
    }
  }

  /// Get email template category and type summary
  Future<Map<String, dynamic>> getCategoryAndTypeSummary() async {
    try {
      final templates = await getAllEmailTemplates();
      
      if (templates.isEmpty) {
        return {
          'total_templates': 0,
          'categories': <String, int>{},
          'html_templates': 0,
          'plain_text_templates': 0,
          'active_templates': 0,
          'inactive_templates': 0,
        };
      }

      final categories = <String, int>{};
      int htmlCount = 0;
      int activeCount = 0;
      
      for (final template in templates) {
        categories[template.category] = (categories[template.category] ?? 0) + 1;
        if (template.isHtml) htmlCount++;
        if (template.isActive) activeCount++;
      }

      return {
        'total_templates': templates.length,
        'categories': categories,
        'html_templates': htmlCount,
        'plain_text_templates': templates.length - htmlCount,
        'active_templates': activeCount,
        'inactive_templates': templates.length - activeCount,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting category and type summary: $e');
      }
      return {
        'error': e.toString(),
        'total_templates': 0,
      };
    }
  }

  /// Get recent email templates (last 30 days)
  Future<List<EmailTemplate>> getRecentEmailTemplates() async {
    try {
      final allTemplates = await getAllEmailTemplates();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      return allTemplates.where((template) => template.createdAt.isAfter(thirtyDaysAgo)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recent email templates: $e');
      }
      return [];
    }
  }

  /// Get most used email templates based on usage count
  Future<List<EmailTemplate>> getMostUsedEmailTemplates({int limit = 10}) async {
    try {
      final allTemplates = await getAllEmailTemplates();
      allTemplates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allTemplates.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting most used email templates: $e');
      }
      return [];
    }
  }

  /// Get email templates with placeholders count
  Future<List<Map<String, dynamic>>> getEmailTemplatesWithPlaceholderCount() async {
    try {
      final templates = await getAllEmailTemplates();
      
      return templates.map((template) => {
        'template': template,
        'placeholder_count': template.placeholders.length,
        'content_length': template.emailContent.length,
        'subject_length': template.subject.length,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email templates with placeholder count: $e');
      }
      return [];
    }
  }

  /// Increment usage count for a template
  Future<void> incrementUsageCount(String templateId) async {
    try {
      final template = await getEmailTemplateById(templateId);
      if (template != null) {
        final updatedTemplate = EmailTemplate(
          id: template.id,
          templateName: template.templateName,
          description: template.description,
          subject: template.subject,
          emailContent: template.emailContent,
          category: template.category,
          placeholders: template.placeholders,
          isActive: template.isActive,
          isHtml: template.isHtml,
          createdAt: template.createdAt,
          updatedAt: DateTime.now(),
        );
        await updateEmailTemplate(updatedTemplate);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error incrementing usage count: $e');
      }
      rethrow;
    }
  }

  /// Get email templates by both category and type
  Future<List<EmailTemplate>> getEmailTemplatesByCategoryAndType(String category, bool isHtml) async {
    try {
      final allTemplates = await getAllEmailTemplates();
      return allTemplates.where((template) {
        return template.category == category && template.isHtml == isHtml;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting email templates by category and type: $e');
      }
      return [];
    }
  }
}