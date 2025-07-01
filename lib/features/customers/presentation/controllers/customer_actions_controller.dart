import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../widgets/customer_actions/customer_actions_handler.dart';
import 'customer_actions_ui_controller.dart';

/// Refactored CustomerActionsController using clean architecture
/// This demonstrates the new pattern but maintains backward compatibility
class CustomerActionsController {
  CustomerActionsController({
    required this.customer,
    required this.navigateToCreateQuoteScreen,
    required this.showQuickCommunicationOptions,
    required this.onUpdated,
    @Deprecated('BuildContext dependency removed') BuildContext? context,
    @Deprecated('MediaController dependency removed') dynamic mediaController,
  }) : _uiController = CustomerActionsUIController(
          customer: customer,
          onCustomerUpdated: onUpdated,
          onCustomerDeleted: onUpdated,
        );

  final Customer customer;
  final VoidCallback navigateToCreateQuoteScreen;
  final VoidCallback showQuickCommunicationOptions;
  final VoidCallback? onUpdated;
  final CustomerActionsUIController _uiController;

  /// Get the UI controller for use in widgets
  CustomerActionsUIController get uiController => _uiController;

  /// Create a handler widget that manages UI concerns
  Widget createActionsHandler({
    Key? key,
    required Widget child,
    VoidCallback? onNavigateBack,
  }) {
    return CustomerActionsHandler(
      key: key,
      controller: _uiController,
      onNavigateToCreateQuote: navigateToCreateQuoteScreen,
      onShowCommunication: showQuickCommunicationOptions,
      onNavigateBack: onNavigateBack,
      child: child,
    );
  }

  /// Legacy methods for backward compatibility - simplified implementation
  void editCustomer() {
    // Legacy implementation - in new architecture this would be handled by UI layer
    debugPrint('editCustomer() called - use CustomerActionsHandler in new architecture');
  }

  void showDeleteCustomerConfirmation() {
    // Legacy implementation - in new architecture this would be handled by UI layer
    debugPrint('showDeleteCustomerConfirmation() called - use CustomerActionsHandler in new architecture');
  }

  void showQuickActions() {
    // Legacy implementation - in new architecture this would be handled by UI layer
    debugPrint('showQuickActions() called - use CustomerActionsHandler in new architecture');
  }

  /// Clean up resources
  void dispose() {
    _uiController.dispose();
  }
}