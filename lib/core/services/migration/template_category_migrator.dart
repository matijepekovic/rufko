import 'package:flutter/foundation.dart';
import '../../../data/repositories/template_category_repository.dart';

/// Migrates TemplateCategory from Hive to SQLite
/// NOTE: Hive has been removed - this is now SQLite-only
class TemplateCategoryMigrator {

  final TemplateCategoryRepository _categoryRepository = TemplateCategoryRepository();

  /// Migrate all template categories from Hive to SQLite
  Future<Map<String, dynamic>> migrate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting TemplateCategory migration...');
      }

      // Check if SQLite already has data
      final existingData = await _categoryRepository.getAllTemplateCategories();
      if (existingData.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ SQLite already has ${existingData.length} template category records - skipping migration');
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
        debugPrint('❌ TemplateCategory migration failed: $e');
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
      final sqliteCount = (await _categoryRepository.getAllTemplateCategories()).length;
      
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
      await _categoryRepository.clearAllTemplateCategories();
      if (kDebugMode) {
        debugPrint('✅ Cleared all template categories from SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing template categories: $e');
      }
      rethrow;
    }
  }

  /// Test migration with a single record
  Future<Map<String, dynamic>> testMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing TemplateCategory database access...');
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

  /// Get template category statistics for migration reporting
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final stats = await _categoryRepository.getTemplateCategoryStatistics();
      return {
        'sqlite_stats': stats,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'sqlite_stats': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get category breakdown by type
  Future<Map<String, dynamic>> getCategoryBreakdown() async {
    try {
      // TODO: Implement getCategoriesByType in repository
      final typeBreakdown = <String, int>{};
      return {
        'types': typeBreakdown,
        'total_categories': typeBreakdown.values.fold(0, (sum, count) => sum + count),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'types': {},
        'total_categories': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}