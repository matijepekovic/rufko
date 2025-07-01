import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/templates/message_template.dart';

/// SQLite database operations for MessageTemplate
class MessageTemplateDatabase {
  static const String tableName = 'message_templates';
  
  /// Create message templates table
  static String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      template_name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL,
      message_content TEXT NOT NULL,
      placeholders TEXT, -- JSON array
      is_active INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      user_category_key TEXT,
      FOREIGN KEY (user_category_key) REFERENCES template_categories (key) ON DELETE SET NULL
    );
  ''';

  /// Create indexes for better performance
  static List<String> get createIndexesSQL => [
    'CREATE INDEX IF NOT EXISTS idx_message_templates_category ON $tableName (category);',
    'CREATE INDEX IF NOT EXISTS idx_message_templates_is_active ON $tableName (is_active);',
    'CREATE INDEX IF NOT EXISTS idx_message_templates_user_category ON $tableName (user_category_key);',
    'CREATE INDEX IF NOT EXISTS idx_message_templates_sort_order ON $tableName (sort_order);',
  ];

  /// Insert a message template
  Future<void> insertMessageTemplate(Database db, MessageTemplate template) async {
    try {
      await db.insert(
        tableName,
        _templateToMap(template),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting message template ${template.id}: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple message templates
  Future<void> insertMessageTemplatesBatch(Database db, List<MessageTemplate> templates) async {
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
        debugPrint('✅ Inserted ${templates.length} message templates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting message templates batch: $e');
      }
      rethrow;
    }
  }

  /// Get message template by ID
  Future<MessageTemplate?> getMessageTemplateById(Database db, String id) async {
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
        debugPrint('❌ Error getting message template $id: $e');
      }
      return null;
    }
  }

  /// Get all message templates
  Future<List<MessageTemplate>> getAllMessageTemplates(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'sort_order ASC, template_name ASC',
      );

      return maps.map((map) => _mapToTemplate(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all message templates: $e');
      }
      return [];
    }
  }

  /// Get active message templates
  Future<List<MessageTemplate>> getActiveMessageTemplates(Database db) async {
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
        debugPrint('❌ Error getting active message templates: $e');
      }
      return [];
    }
  }

  /// Get message templates by category
  Future<List<MessageTemplate>> getMessageTemplatesByCategory(Database db, String category) async {
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
        debugPrint('❌ Error getting message templates by category $category: $e');
      }
      return [];
    }
  }

  /// Search message templates
  Future<List<MessageTemplate>> searchMessageTemplates(Database db, String query) async {
    try {
      final String searchPattern = '%${query.toLowerCase()}%';
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '''
          LOWER(template_name) LIKE ? OR 
          LOWER(description) LIKE ? OR 
          LOWER(category) LIKE ? OR 
          LOWER(message_content) LIKE ?
        ''',
        whereArgs: [searchPattern, searchPattern, searchPattern, searchPattern],
        orderBy: 'sort_order ASC, template_name ASC',
      );

      return maps.map((map) => _mapToTemplate(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching message templates: $e');
      }
      return [];
    }
  }

  /// Update message template
  Future<void> updateMessageTemplate(Database db, MessageTemplate template) async {
    try {
      final count = await db.update(
        tableName,
        _templateToMap(template),
        where: 'id = ?',
        whereArgs: [template.id],
      );
      
      if (count == 0) {
        throw Exception('Message template ${template.id} not found for update');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating message template ${template.id}: $e');
      }
      rethrow;
    }
  }

  /// Toggle message template active status
  Future<void> toggleMessageTemplateActive(Database db, String id) async {
    try {
      await db.rawUpdate('''
        UPDATE $tableName 
        SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END,
            updated_at = ?
        WHERE id = ?
      ''', [DateTime.now().toIso8601String(), id]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling message template active status $id: $e');
      }
      rethrow;
    }
  }

  /// Delete message template by ID
  Future<void> deleteMessageTemplate(Database db, String id) async {
    try {
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw Exception('Message template $id not found for deletion');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting message template $id: $e');
      }
      rethrow;
    }
  }

  /// Clear all message templates
  Future<void> clearAllMessageTemplates(Database db) async {
    try {
      await db.delete(tableName);
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
  Future<Map<String, dynamic>> getMessageTemplateStatistics(Database db) async {
    try {
      final totalTemplates = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
      ) ?? 0;

      final activeTemplates = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE is_active = 1'),
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
        'category_breakdown': categoryStats,
        'average_placeholders': avgPlaceholders.isNotEmpty ? avgPlaceholders.first['avg_placeholders'] : 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
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

  /// Convert MessageTemplate to Map for database storage
  Map<String, dynamic> _templateToMap(MessageTemplate template) {
    return {
      'id': template.id,
      'template_name': template.templateName,
      'description': template.description,
      'category': template.category,
      'message_content': template.messageContent,
      'placeholders': jsonEncode(template.placeholders),
      'is_active': template.isActive ? 1 : 0,
      'sort_order': template.sortOrder,
      'created_at': template.createdAt.toIso8601String(),
      'updated_at': template.updatedAt.toIso8601String(),
      'user_category_key': template.userCategoryKey,
    };
  }

  /// Convert Map from database to MessageTemplate
  MessageTemplate _mapToTemplate(Map<String, dynamic> map) {
    return MessageTemplate(
      id: map['id'] as String,
      templateName: map['template_name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      messageContent: map['message_content'] as String,
      placeholders: map['placeholders'] != null 
          ? List<String>.from(jsonDecode(map['placeholders'] as String))
          : [],
      isActive: (map['is_active'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      userCategoryKey: map['user_category_key'] as String?,
    );
  }
}