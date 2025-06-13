import 'package:flutter/foundation.dart';

import '../../models/business/customer.dart';
import '../../models/business/simplified_quote.dart';
import '../../models/business/roof_scope_data.dart';
import '../../models/media/project_media.dart';
import '../../../core/services/database/database_service.dart';
import '../helpers/data_loading_helper.dart';
import '../helpers/customer_helper.dart';

/// Provider responsible for managing [Customer] data and related
/// relationships. This was extracted from `AppStateProvider` to keep
/// customer logic self‑contained.
class CustomerStateProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Customer> _customers = [];

  CustomerStateProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<Customer> get customers => _customers;

  /// Loads all customers from the database.
  Future<void> loadCustomers() async {
    _customers = await DataLoadingHelper.loadCustomers(_db);
    notifyListeners();
  }

  /// Adds a new customer and persists it to the database.
  Future<void> addCustomer(Customer customer) async {
    await CustomerHelper.addCustomer(
      db: _db,
      customers: _customers,
      customer: customer,
    );
    notifyListeners();
  }

  /// Updates an existing customer in memory and storage.
  Future<void> updateCustomer(Customer customer) async {
    await CustomerHelper.updateCustomer(
      db: _db,
      customers: _customers,
      customer: customer,
    );
    notifyListeners();
  }

  /// Deletes a customer and all associated records.
  Future<void> deleteCustomer({
    required String customerId,
    required List<SimplifiedMultiLevelQuote> quotes,
    required List<RoofScopeData> roofScopes,
    required List<ProjectMedia> media,
    required Future<void> Function(String) deleteQuote,
    required Future<void> Function(String) deleteRoofScope,
    required Future<void> Function(String) deleteMedia,
  }) async {
    await CustomerHelper.deleteCustomer(
      db: _db,
      customers: _customers,
      quotes: quotes,
      roofScopes: roofScopes,
      media: media,
      deleteQuote: deleteQuote,
      deleteRoofScope: deleteRoofScope,
      deleteMedia: deleteMedia,
      customerId: customerId,
    );
    notifyListeners();
  }

  /// Returns customers matching the provided search [query].
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final lower = query.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            (c.phone?.contains(lower) ?? false))
        .toList();
  }

  /// Returns a new list of customers sorted by name.
  List<Customer> sortByName({bool ascending = true}) {
    final sorted = [..._customers];
    sorted.sort((a, b) =>
        ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    return sorted;
  }

  /// Filters customers by city, case insensitive.
  List<Customer> filterByCity(String city) {
    final lowerCity = city.toLowerCase();
    return _customers.where((c) => c.city?.toLowerCase() == lowerCity).toList();
  }
}
