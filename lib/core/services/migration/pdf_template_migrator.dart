import 'package:flutter/foundation.dart';
import '../../../data/repositories/pdf_template_repository.dart';

/// Migrates PdfTemplate from Hive to SQLite
class PdfTemplateMigrator {

  final PDFTemplateRepository _repository = PDFTemplateRepository();

  /// Migrate all PDF templates from Hive to SQLite
  Future<Map<String, dynamic>> migrate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting PdfTemplate migration...');
      }

      // Check if SQLite already has data
      final existingData = await _repository.getAllPDFTemplates();
      if (existingData.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ SQLite already has ${existingData.length} PDF template records - skipping migration');
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
        debugPrint('❌ PdfTemplate migration failed: $e');
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
      final sqliteCount = (await _repository.getAllPDFTemplates()).length;
      
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
      await _repository.clearAllPDFTemplates();
      if (kDebugMode) {
        debugPrint('✅ Cleared all PDF templates from SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing PDF templates: $e');
      }
      rethrow;
    }
  }

  /// Test migration with a single record
  Future<Map<String, dynamic>> testMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing PdfTemplate database access...');
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

  /// Get PDF template statistics for migration reporting
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final stats = await _repository.getPDFTemplateStatistics();
      final sizeSummary = await _repository.getTemplateSizeSummary();
      return {
        'sqlite_stats': stats,
        'size_summary': sizeSummary,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'sqlite_stats': {},
        'size_summary': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get templates with field mapping information
  Future<Map<String, dynamic>> getTemplatesWithMappings() async {
    try {
      final templatesWithMappings = await _repository.getPDFTemplatesWithMappingCount();
      return {
        'templates_with_mappings': templatesWithMappings,
        'total_templates': templatesWithMappings.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'templates_with_mappings': [],
        'total_templates': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}