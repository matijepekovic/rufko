import 'package:flutter/foundation.dart';
import 'customer_migrator.dart';

/// Utility to run customer migration from Hive to SQLite
/// This should be called once during the transition period
class RunCustomerMigration {
  
  /// Execute the customer migration
  static Future<bool> execute() async {
    if (!kDebugMode) {
      debugPrint('⚠️ Migration should only be run in debug mode');
      return false;
    }

    debugPrint('🚀 Starting Customer Migration Process...');
    
    try {
      final migrator = CustomerMigrator();
      
      // Step 1: Run the migration
      final success = await migrator.migrateCustomers();
      
      if (!success) {
        debugPrint('❌ Customer migration failed');
        return false;
      }
      
      // Step 2: Verify migration
      final verified = await migrator.verifyMigration();
      
      if (!verified) {
        debugPrint('❌ Customer migration verification failed');
        return false;
      }
      
      // Step 3: Get migration stats
      final stats = await migrator.getMigrationStats();
      debugPrint('📊 Migration Statistics:');
      stats.forEach((key, value) {
        debugPrint('   $key: $value');
      });
      
      debugPrint('✅ Customer Migration completed successfully!');
      debugPrint('📝 Phase 2: Customer Data Migration - COMPLETED');
      
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Migration execution failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Quick test to verify migration worked
  static Future<void> quickTest() async {
    try {
      final migrator = CustomerMigrator();
      final stats = await migrator.getMigrationStats();
      
      debugPrint('🧪 Quick Migration Test:');
      debugPrint('   Total Customers: ${stats['sqlite_customers']}');
      debugPrint('   Status: ${stats['status']}');
      
      if (stats['sqlite_customers'] > 0) {
        debugPrint('✅ Customer data found in SQLite');
      } else {
        debugPrint('⚠️ No customer data found - migration may be needed');
      }
      
    } catch (e) {
      debugPrint('❌ Migration test failed: $e');
    }
  }
}