import '../../../../core/services/database/database_service.dart';
import '../../../../data/models/business/customer.dart';
import '../../domain/repositories/customer_repository.dart';

/// Concrete implementation of CustomerRepository using DatabaseService
class CustomerRepositoryImpl implements CustomerRepository {
  final DatabaseService _databaseService;

  CustomerRepositoryImpl(this._databaseService);

  @override
  Future<void> saveCustomer(Customer customer) async {
    return await _databaseService.saveCustomer(customer);
  }

  @override
  Future<Customer?> getCustomer(String id) async {
    return await _databaseService.getCustomer(id);
  }

  @override
  Future<List<Customer>> getAllCustomers() async {
    return await _databaseService.getAllCustomers();
  }

  @override
  Future<void> deleteCustomer(String id) async {
    return await _databaseService.deleteCustomer(id);
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) return await getAllCustomers();

    final allCustomers = await getAllCustomers();
    final lowerQuery = query.toLowerCase();

    return allCustomers.where((customer) {
      return customer.name.toLowerCase().contains(lowerQuery) ||
          (customer.phone?.toLowerCase().contains(lowerQuery) ?? false) ||
          (customer.email?.toLowerCase().contains(lowerQuery) ?? false) ||
          customer.fullDisplayAddress.toLowerCase().contains(lowerQuery) ||
          (customer.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Future<List<Customer>> getRecentCustomers([int days = 30]) async {
    final allCustomers = await getAllCustomers();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return allCustomers.where((customer) {
      return customer.createdAt.isAfter(cutoffDate);
    }).toList();
  }

  @override
  Future<List<Customer>> getCustomersWithRecentCommunication([int days = 30]) async {
    final allCustomers = await getAllCustomers();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return allCustomers.where((customer) {
      return customer.updatedAt.isAfter(cutoffDate) ||
          customer.communicationHistory.isNotEmpty;
    }).toList();
  }
}