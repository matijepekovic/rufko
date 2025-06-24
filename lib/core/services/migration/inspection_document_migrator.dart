import 'package:flutter/foundation.dart';
import '../../../data/repositories/inspection_document_repository.dart';

/// Migrates InspectionDocument from Hive to SQLite
/// NOTE: Hive has been removed - this is now SQLite-only
class InspectionDocumentMigrator {

  final InspectionDocumentRepository _repository = InspectionDocumentRepository();

  /// Migrate all inspection documents from Hive to SQLite
  Future<Map<String, dynamic>> migrate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
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
        debugPrint('❌ InspectionDocument migration failed: $e');
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
      final sqliteCount = (await _repository.getAllInspectionDocuments()).length;
      
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
      await _repository.clearAllInspectionDocuments();
      if (kDebugMode) {
        debugPrint('✅ Cleared all inspection documents from SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing inspection documents: $e');
      }
      rethrow;
    }
  }

  /// Test migration with a single record
  Future<Map<String, dynamic>> testMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing InspectionDocument database access...');
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
}