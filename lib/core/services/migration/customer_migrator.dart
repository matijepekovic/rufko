import 'package:flutter/foundation.dart';

import '../../../data/repositories/customer_repository.dart';

/// Service to migrate customer data from Hive to SQLite
/// NOTE: Hive has been removed - this is now SQLite-only
class CustomerMigrator {
  final CustomerRepository _customerRepository = CustomerRepository();

  /// Migrate all customer data from Hive to SQLite
  Future<bool> migrateCustomers() async {
    try {
      debugPrint('✅ No Hive migration needed - SQLite is primary data source');
      return true;
    } catch (e) {
      debugPrint('❌ Customer migration check failed: $e');
      return false;
    }
  }

  /// Get customer statistics for reporting
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final customers = await _customerRepository.getAllCustomers();
      return {
        'total_customers': customers.length,
        'data_source': 'SQLite only',
        'migration_status': 'completed',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'total_customers': 0,
        'data_source': 'SQLite only',
        'migration_status': 'error',
      };
    }
  }

  /// Verify migration (compatibility method for run_customer_migration.dart)
  Future<bool> verifyMigration() async {
    try {
      final customers = await _customerRepository.getAllCustomers();
      debugPrint('✅ Customer migration verified: ${customers.length} customers found');
      return true;
    } catch (e) {
      debugPrint('❌ Customer migration verification failed: $e');
      return false;
    }
  }

  /// Get migration stats (compatibility method for run_customer_migration.dart)
  Future<Map<String, dynamic>> getMigrationStats() async {
    return await getStatistics();
  }
}