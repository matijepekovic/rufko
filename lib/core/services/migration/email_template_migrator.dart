import 'package:flutter/foundation.dart';
import '../../../data/repositories/email_template_repository.dart';

/// Migrates EmailTemplate from Hive to SQLite
class EmailTemplateMigrator {

  final EmailTemplateRepository _repository = EmailTemplateRepository();

  /// Migrate all email templates from Hive to SQLite
  Future<Map<String, dynamic>> migrate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting EmailTemplate migration...');
      }

      // Check if SQLite already has data
      final existingData = await _repository.getAllEmailTemplates();
      if (existingData.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ SQLite already has ${existingData.length} email template records - skipping migration');
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
        debugPrint('❌ EmailTemplate migration failed: $e');
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
      final sqliteCount = (await _repository.getAllEmailTemplates()).length;
      
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
      await _repository.clearAllEmailTemplates();
      if (kDebugMode) {
        debugPrint('✅ Cleared all email templates from SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing email templates: $e');
      }
      rethrow;
    }
  }

  /// Test migration with a single record
  Future<Map<String, dynamic>> testMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing EmailTemplate database access...');
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

  /// Get email template statistics for migration reporting
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final stats = await _repository.getEmailTemplateStatistics();
      final categorySummary = await _repository.getCategoryAndTypeSummary();
      final templatesWithPlaceholders = await _repository.getEmailTemplatesWithPlaceholderCount();
      
      return {
        'sqlite_stats': stats,
        'category_and_type_summary': categorySummary,
        'templates_with_placeholders': templatesWithPlaceholders,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'sqlite_stats': {},
        'category_and_type_summary': {},
        'templates_with_placeholders': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get HTML vs Plain Text breakdown
  Future<Map<String, dynamic>> getHtmlVsPlainTextBreakdown() async {
    try {
      final htmlTemplates = await _repository.getHtmlEmailTemplates();
      final plainTextTemplates = await _repository.getPlainTextEmailTemplates();
      
      return {
        'html_templates': htmlTemplates.length,
        'plain_text_templates': plainTextTemplates.length,
        'total_templates': htmlTemplates.length + plainTextTemplates.length,
        'html_percentage': htmlTemplates.isEmpty && plainTextTemplates.isEmpty 
            ? 0.0 
            : (htmlTemplates.length / (htmlTemplates.length + plainTextTemplates.length)) * 100,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'html_templates': 0,
        'plain_text_templates': 0,
        'total_templates': 0,
        'html_percentage': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get most used templates for reporting
  Future<Map<String, dynamic>> getMostUsedTemplates() async {
    try {
      final mostUsed = await _repository.getMostUsedEmailTemplates(limit: 5);
      return {
        'most_used_templates': mostUsed.map((template) => {
          'id': template.id,
          'name': template.templateName,
          'subject': template.subject,
          'category': template.category,
          'is_html': template.isHtml,
          'usage_count': 0, // EmailTemplate doesn't have usageCount property
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