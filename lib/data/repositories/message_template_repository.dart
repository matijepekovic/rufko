import 'package:flutter/foundation.dart';
import '../models/templates/message_template.dart';
import '../database/message_template_database.dart';
import '../database/database_helper.dart';

/// Repository for MessageTemplate operations using SQLite
class MessageTemplateRepository {
  final MessageTemplateDatabase _database = MessageTemplateDatabase();

  /// Create a new message template
  Future<void> createMessageTemplate(MessageTemplate template) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertMessageTemplate(db, template);
      if (kDebugMode) {
        debugPrint('✅ Created message template: ${template.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating message template: $e');
      }
      rethrow;
    }
  }

  /// Get message template by ID
  Future<MessageTemplate?> getMessageTemplateById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getMessageTemplateById(db, id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting message template $id: $e');
      }
      return null;
    }
  }

  /// Get all message templates
  Future<List<MessageTemplate>> getAllMessageTemplates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getAllMessageTemplates(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all message templates: $e');
      }
      return [];
    }
  }

  /// Get message templates by category
  Future<List<MessageTemplate>> getMessageTemplatesByCategory(String category) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getMessageTemplatesByCategory(db, category);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting message templates for category $category: $e');
      }
      return [];
    }
  }

  /// Update message template
  Future<void> updateMessageTemplate(MessageTemplate template) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.updateMessageTemplate(db, template);
      if (kDebugMode) {
        debugPrint('✅ Updated message template: ${template.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating message template: $e');
      }
      rethrow;
    }
  }

  /// Delete message template by ID
  Future<void> deleteMessageTemplate(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteMessageTemplate(db, id);
      if (kDebugMode) {
        debugPrint('✅ Deleted message template: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting message template: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple message templates
  Future<void> insertMessageTemplatesBatch(List<MessageTemplate> templates) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertMessageTemplatesBatch(db, templates);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${templates.length} message templates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting message templates batch: $e');
      }
      rethrow;
    }
  }

  /// Clear all message templates
  Future<void> clearAllMessageTemplates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.clearAllMessageTemplates(db);
      if (kDebugMode) {
        debugPrint('✅ Cleared all message templates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing message templates: $e');
      }
      rethrow;
    }
  }

  /// Get message template statistics
  Future<Map<String, dynamic>> getMessageTemplateStatistics() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getMessageTemplateStatistics(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting message template statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_templates': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Search message templates by name
  Future<List<MessageTemplate>> searchByName(String searchTerm) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.searchMessageTemplates(db, searchTerm);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching message templates by name: $e');
      }
      return [];
    }
  }

  /// Search message templates by content
  Future<List<MessageTemplate>> searchByContent(String searchTerm) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.searchMessageTemplates(db, searchTerm);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching message templates by content: $e');
      }
      return [];
    }
  }

  /// Get message templates by placeholder
  Future<List<MessageTemplate>> getMessageTemplatesByPlaceholder(String placeholder) async {
    try {
      final allTemplates = await getAllMessageTemplates();
      return allTemplates.where((template) {
        return template.placeholders.contains(placeholder);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting message templates by placeholder: $e');
      }
      return [];
    }
  }

  /// Get active message templates only
  Future<List<MessageTemplate>> getActiveMessageTemplates() async {
    try {
      final allTemplates = await getAllMessageTemplates();
      return allTemplates.where((template) => template.isActive).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active message templates: $e');
      }
      return [];
    }
  }

  /// Get message template category summary
  Future<Map<String, dynamic>> getCategorySummary() async {
    try {
      final templates = await getAllMessageTemplates();
      
      if (templates.isEmpty) {
        return {
          'total_templates': 0,
          'categories': <String, int>{},
          'active_templates': 0,
          'inactive_templates': 0,
        };
      }

      final categories = <String, int>{};
      int activeCount = 0;
      
      for (final template in templates) {
        categories[template.category] = (categories[template.category] ?? 0) + 1;
        if (template.isActive) activeCount++;
      }

      return {
        'total_templates': templates.length,
        'categories': categories,
        'active_templates': activeCount,
        'inactive_templates': templates.length - activeCount,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting category summary: $e');
      }
      return {
        'error': e.toString(),
        'total_templates': 0,
      };
    }
  }

  /// Get recent message templates (last 30 days)
  Future<List<MessageTemplate>> getRecentMessageTemplates() async {
    try {
      final allTemplates = await getAllMessageTemplates();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      return allTemplates.where((template) => template.createdAt.isAfter(thirtyDaysAgo)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recent message templates: $e');
      }
      return [];
    }
  }

  /// Get most used message templates based on usage count
  Future<List<MessageTemplate>> getMostUsedMessageTemplates({int limit = 10}) async {
    try {
      final allTemplates = await getAllMessageTemplates();
      allTemplates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allTemplates.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting most used message templates: $e');
      }
      return [];
    }
  }

  /// Get message templates with placeholders count
  Future<List<Map<String, dynamic>>> getMessageTemplatesWithPlaceholderCount() async {
    try {
      final templates = await getAllMessageTemplates();
      
      return templates.map((template) => {
        'template': template,
        'placeholder_count': template.placeholders.length,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting message templates with placeholder count: $e');
      }
      return [];
    }
  }

  /// Increment usage count for a template
  Future<void> incrementUsageCount(String templateId) async {
    try {
      final template = await getMessageTemplateById(templateId);
      if (template != null) {
        final updatedTemplate = MessageTemplate(
          id: template.id,
          templateName: template.templateName,
          description: template.description,
          messageContent: template.messageContent,
          category: template.category,
          placeholders: template.placeholders,
          isActive: template.isActive,
          createdAt: template.createdAt,
          updatedAt: DateTime.now(),
        );
        await updateMessageTemplate(updatedTemplate);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error incrementing usage count: $e');
      }
      rethrow;
    }
  }
}