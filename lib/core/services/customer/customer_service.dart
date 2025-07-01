import '../../../data/models/business/customer.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Service class for customer operations
/// Separated from UI concerns for better testability and maintainability
class CustomerService {
  const CustomerService();

  /// Delete a customer and all associated data
  Future<CustomerOperationResult> deleteCustomer({
    required String customerId,
    required AppStateProvider appState,
  }) async {
    try {
      // Get customer before deletion for result
      final customer = appState.customers.firstWhere(
        (c) => c.id == customerId,
        orElse: () => throw Exception('Customer not found'),
      );

      // Perform deletion
      await appState.deleteCustomer(customerId);

      return CustomerOperationResult.success(
        message: '${customer.name} deleted successfully',
        customer: customer,
      );
    } catch (e) {
      return CustomerOperationResult.error(
        message: 'Failed to delete customer: $e',
      );
    }
  }

  /// Update customer data
  Future<CustomerOperationResult> updateCustomer({
    required Customer customer,
    required AppStateProvider appState,
  }) async {
    try {
      await appState.updateCustomer(customer);
      
      return CustomerOperationResult.success(
        message: '${customer.name} updated successfully',
        customer: customer,
      );
    } catch (e) {
      return CustomerOperationResult.error(
        message: 'Failed to update customer: $e',
      );
    }
  }

  /// Get customer statistics and related data
  CustomerStats getCustomerStats({
    required Customer customer,
    required AppStateProvider appState,
  }) {
    final quotes = appState.getSimplifiedQuotesForCustomer(customer.id);
    final inspectionDocs = appState.getInspectionDocumentsForCustomer(customer.id);
    final projectMedia = appState.getProjectMediaForCustomer(customer.id);

    return CustomerStats(
      quotesCount: quotes.length,
      documentsCount: inspectionDocs.length,
      mediaCount: projectMedia.length,
      totalValue: quotes.fold(0.0, (sum, quote) => 
        sum + quote.levels.fold(0.0, (levelSum, level) => levelSum + level.subtotal)),
    );
  }
}

/// Result class for customer operations
class CustomerOperationResult {
  const CustomerOperationResult.success({
    required this.message,
    this.customer,
  }) : isSuccess = true;
  
  const CustomerOperationResult.error({
    required this.message,
  }) : isSuccess = false,
       customer = null;

  final bool isSuccess;
  final String message;
  final Customer? customer;

  bool get isError => !isSuccess;
}

/// Customer statistics data class
class CustomerStats {
  const CustomerStats({
    required this.quotesCount,
    required this.documentsCount,
    required this.mediaCount,
    required this.totalValue,
  });

  final int quotesCount;
  final int documentsCount;
  final int mediaCount;
  final double totalValue;
}