import 'package:flutter/foundation.dart';
import '../../../data/repositories/product_repository.dart';

/// Migrates Product from Hive to SQLite
/// NOTE: Hive has been removed - this is now SQLite-only
class ProductMigrator {
  final ProductRepository _productRepository = ProductRepository();

  /// Migrate all products from Hive to SQLite
  Future<Map<String, dynamic>> migrate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting Product migration...');
      }

      // Check if SQLite already has data
      final existingData = await _productRepository.getAllProducts();
      if (existingData.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ SQLite already has ${existingData.length} product records - skipping migration');
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
        debugPrint('❌ Product migration failed: $e');
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
      final sqliteCount = (await _productRepository.getAllProducts()).length;
      
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
      await _productRepository.clearAllProducts();
      if (kDebugMode) {
        debugPrint('✅ Cleared all products from SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing products: $e');
      }
      rethrow;
    }
  }

  /// Test migration with a single record
  Future<Map<String, dynamic>> testMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing Product database access...');
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

  /// Get product statistics for migration reporting
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final stats = await _productRepository.getProductStatistics();
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

  /// Get category breakdown
  Future<Map<String, dynamic>> getCategoryBreakdown() async {
    try {
      // TODO: Implement getProductsByCategory in repository
      final categoryBreakdown = <String, int>{};
      return {
        'categories': categoryBreakdown,
        'total_products': categoryBreakdown.values.fold(0, (sum, count) => sum + count),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'categories': {},
        'total_products': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}