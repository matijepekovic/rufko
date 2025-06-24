import 'package:flutter/foundation.dart';
import '../../../data/repositories/app_settings_repository.dart';

/// Migrates AppSettings from Hive to SQLite
class AppSettingsMigrator {
  final AppSettingsRepository _settingsRepository = AppSettingsRepository();

  /// Migrate all app settings from Hive to SQLite
  Future<Map<String, dynamic>> migrate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting AppSettings migration...');
      }

      // Check if SQLite already has data
      final existingSettings = await _settingsRepository.getAppSettings();
      if (existingSettings.companyName != null || 
          existingSettings.productCategories.isNotEmpty ||
          existingSettings.productUnits.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ SQLite already has app settings - skipping migration');
        }
        return {
          'success': true,
          'skipped': true,
          'existing_settings': true,
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
        debugPrint('❌ AppSettings migration failed: $e');
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
      final sqliteSettings = await _settingsRepository.getAppSettings();
      final hasSettings = sqliteSettings.companyName != null || 
                         sqliteSettings.productCategories.isNotEmpty ||
                         sqliteSettings.productUnits.isNotEmpty;
      
      return {
        'hive_count': 0,
        'sqlite_has_settings': hasSettings,
        'migration_needed': false,
        'migration_complete': true,
        'data_source': 'SQLite only',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hive_count': 0,
        'sqlite_has_settings': false,
        'migration_needed': false,
        'migration_complete': false,
      };
    }
  }

  /// Clear SQLite data (for testing)
  Future<void> clearSQLiteData() async {
    try {
      await _settingsRepository.clearAllSettings();
      if (kDebugMode) {
        debugPrint('✅ Cleared all app settings from SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing app settings: $e');
      }
      rethrow;
    }
  }

  /// Test migration with a single record
  Future<Map<String, dynamic>> testMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing AppSettings database access...');
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

  /// Get app settings statistics for migration reporting
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final stats = await _settingsRepository.getSettingsStatistics();
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
}