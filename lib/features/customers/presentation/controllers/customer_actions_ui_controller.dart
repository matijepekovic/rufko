import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/customer/customer_service.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for customer actions that follows clean architecture
/// Separates business logic from UI concerns using service layer and event emission
class CustomerActionsUIController extends ChangeNotifier {
  CustomerActionsUIController({
    required this.customer,
    this.onCustomerUpdated,
    this.onCustomerDeleted,
  }) : _customerService = const CustomerService();

  final Customer customer;
  final VoidCallback? onCustomerUpdated;
  final VoidCallback? onCustomerDeleted;
  final CustomerService _customerService;

  // UI state
  bool _isLoading = false;
  String? _lastError;
  String? _lastSuccess;
  CustomerStats? _customerStats;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  CustomerStats? get customerStats => _customerStats;

  /// Clear messages
  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();
  }

  /// Load customer statistics
  void loadCustomerStats(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    _customerStats = _customerService.getCustomerStats(
      customer: customer,
      appState: appState,
    );
    notifyListeners();
  }

  /// Delete customer - emits UI events instead of handling them directly
  Future<void> deleteCustomer(BuildContext context) async {
    _setLoading(true);
    clearMessages();

    try {
      final appState = context.read<AppStateProvider>();
      final result = await _customerService.deleteCustomer(
        customerId: customer.id,
        appState: appState,
      );

      if (result.isSuccess) {
        _setSuccess(result.message);
        onCustomerDeleted?.call();
      } else {
        _setError(result.message);
      }
    } catch (e) {
      _setError('Failed to delete customer: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update customer - emits UI events instead of handling them directly
  Future<void> updateCustomer(BuildContext context, Customer updatedCustomer) async {
    _setLoading(true);
    clearMessages();

    try {
      final appState = context.read<AppStateProvider>();
      final result = await _customerService.updateCustomer(
        customer: updatedCustomer,
        appState: appState,
      );

      if (result.isSuccess) {
        _setSuccess(result.message);
        onCustomerUpdated?.call();
      } else {
        _setError(result.message);
      }
    } catch (e) {
      _setError('Failed to update customer: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _lastSuccess = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _lastSuccess = success;
    _lastError = null;
    notifyListeners();
  }
}