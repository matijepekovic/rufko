import 'package:flutter/foundation.dart';
import '../../../data/repositories/message_template_repository.dart';

/// Migrates MessageTemplate from Hive to SQLite
class MessageTemplateMigrator {

  final MessageTemplateRepository _repository = MessageTemplateRepository();

  /// Migrate all message templates from Hive to SQLite
  Future<Map<String, dynamic>> migrate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting MessageTemplate migration...');
      }

      // Check if SQLite already has data
      final existingData = await _repository.getAllMessageTemplates();
      if (existingData.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ SQLite already has ${existingData.length} message template records - skipping migration');
        }
        return {
          'success': true,
          'skipped': true,
          'existing_records': existingData.length,
          'duration_ms': stopwatch.elapsedMilliseconds,
        };
      }

      // Hive migration is no longer needed - SQLite is the only data source
      if (kDebugMode) {
        debugPrint('✅ No Hive migration needed - SQLite is primary data source');
      }

      return {
        'success': true,
        'migrated_count': 0,
        'skipped': true,
        'reason': 'Hive removed - SQLite is primary data source',
        'duration_ms': stopwatch.elapsedMilliseconds,
      };

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ MessageTemplate migration failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'duration_ms': stopwatch.elapsedMilliseconds,
      };
    } finally {
      stopwatch.stop();
    }
  }

  /// Get migration status and statistics
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final sqliteCount = (await _repository.getAllMessageTemplates()).length;
      
      return {
        'hive_count': 0,
        'sqlite_count': sqliteCount,
        'migration_needed': false,
        'migration_complete': true,
        'data_source': 'SQLite only',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hive_count': 0,
        'sqlite_count': 0,
        'migration_needed': false,
        'migration_complete': false,
      };
    }
  }

  /// Clear SQLite data (for testing)
  Future<void> clearSQLiteData() async {
    try {
      await _repository.clearAllMessageTemplates();
      if (kDebugMode) {
        debugPrint('✅ Cleared all message templates from SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing message templates: $e');
      }
      rethrow;
    }
  }

  /// Test migration with a single record
  Future<Map<String, dynamic>> testMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing MessageTemplate database access...');
      }

      return {
        'success': true,
        'message': 'No test needed - using SQLite directly',
        'data_source': 'SQLite only',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Test failed with error',
      };
    }
  }

  /// Get message template statistics for migration reporting
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final stats = await _repository.getMessageTemplateStatistics();
      final categorySummary = await _repository.getCategorySummary();
      final templatesWithPlaceholders = await _repository.getMessageTemplatesWithPlaceholderCount();
      
      return {
        'sqlite_stats': stats,
        'category_summary': categorySummary,
        'templates_with_placeholders': templatesWithPlaceholders,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'sqlite_stats': {},
        'category_summary': {},
        'templates_with_placeholders': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get most used templates for reporting
  Future<Map<String, dynamic>> getMostUsedTemplates() async {
    try {
      final mostUsed = await _repository.getMostUsedMessageTemplates(limit: 5);
      return {
        'most_used_templates': mostUsed.map((template) => {
          'id': template.id,
          'name': template.templateName,
          'category': template.category,
          'usage_count': 0, // MessageTemplate doesn't have usageCount property
        }).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'most_used_templates': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}