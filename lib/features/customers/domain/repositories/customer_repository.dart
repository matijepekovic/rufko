import '../../../../data/models/business/customer.dart';

/// Abstract repository interface for customer data operations.
/// This defines the contract for all customer data access.
abstract class CustomerRepository {
  /// Save a customer to the database
  Future<void> saveCustomer(Customer customer);

  /// Get a customer by their ID
  Future<Customer?> getCustomer(String id);

  /// Get all customers from the database
  Future<List<Customer>> getAllCustomers();

  /// Delete a customer by their ID
  Future<void> deleteCustomer(String id);

  /// Search customers by query (name, phone, email, address)
  Future<List<Customer>> searchCustomers(String query);

  /// Get customers with recent activity (last 30 days)
  Future<List<Customer>> getRecentCustomers([int days = 30]);

  /// Get customers by communication activity
  Future<List<Customer>> getCustomersWithRecentCommunication([int days = 30]);
}