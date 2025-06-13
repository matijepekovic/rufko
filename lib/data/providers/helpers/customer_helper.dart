import 'package:flutter/foundation.dart';

import '../../models/business/customer.dart';
import '../../models/media/project_media.dart';
import '../../models/business/roof_scope_data.dart';
import '../../models/business/simplified_quote.dart';
import '../../../core/services/database/database_service.dart';

/// Helper methods for managing [Customer] records and related data.
class CustomerHelper {
  static Future<void> addCustomer({
    required DatabaseService db,
    required List<Customer> customers,
    required Customer customer,
  }) async {
    await db.saveCustomer(customer);
    customers.add(customer);
    if (kDebugMode) {
      debugPrint('➕ Added customer: ${customer.name}');
    }
  }

  static Future<void> updateCustomer({
    required DatabaseService db,
    required List<Customer> customers,
    required Customer customer,
  }) async {
    await db.saveCustomer(customer);
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      customers[index] = customer;
      if (kDebugMode) {
        debugPrint('✅ Updated customer in memory');
      }
    } else {
      customers.add(customer);
      if (kDebugMode) {
        debugPrint('⚠️ Customer not found in memory, adding it');
      }
    }
  }

  static Future<void> deleteCustomer({
    required DatabaseService db,
    required List<Customer> customers,
    required List<SimplifiedMultiLevelQuote> quotes,
    required List<RoofScopeData> roofScopes,
    required List<ProjectMedia> media,
    required Future<void> Function(String) deleteQuote,
    required Future<void> Function(String) deleteRoofScope,
    required Future<void> Function(String) deleteMedia,
    required String customerId,
  }) async {
    final quotesToDelete =
        quotes.where((q) => q.customerId == customerId).toList();
    for (final quote in quotesToDelete) {
      await deleteQuote(quote.id);
    }

    final roofScopesToDelete =
        roofScopes.where((rs) => rs.customerId == customerId).toList();
    for (final scope in roofScopesToDelete) {
      await deleteRoofScope(scope.id);
    }

    final mediaToDelete =
        media.where((pm) => pm.customerId == customerId).toList();
    for (final m in mediaToDelete) {
      await deleteMedia(m.id);
    }

    await db.deleteCustomer(customerId);
    customers.removeWhere((c) => c.id == customerId);
    if (kDebugMode) {
      debugPrint('🗑️ Deleted customer $customerId');
    }
  }
}
