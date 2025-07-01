import 'package:flutter/foundation.dart';
import '../models/business/customer.dart';
import '../../core/services/database/database_service.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Customer> _customers = [];

  CustomerProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<Customer> get customers => _customers;

  Future<void> loadCustomers() async {
    try {
      _customers = await _db.getAllCustomers();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addCustomer(Customer customer) async {
    await _db.saveCustomer(customer);
    _customers.add(customer);
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.saveCustomer(customer);
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) _customers[index] = customer;
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _db.deleteCustomer(id);
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final lower = query.toLowerCase();
    return _customers
        .where((c) => c.name.toLowerCase().contains(lower) ||
            (c.phone?.contains(lower) ?? false))
        .toList();
  }
}
