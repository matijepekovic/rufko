import 'package:flutter/material.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../core/services/customer/customer_operations_service.dart';
import '../widgets/media_tab_controller.dart';

/// Legacy CustomerActionsController for backward compatibility
/// This maintains the old API while the new clean architecture is being rolled out
@Deprecated('Use CustomerActionsUIController with service layer pattern')
class CustomerActionsControllerLegacy {
  CustomerActionsControllerLegacy({
    required this.context,
    required this.customer,
    required this.navigateToCreateQuoteScreen,
    required this.mediaController,
    required this.showQuickCommunicationOptions,
    required this.onUpdated,
  });

  final BuildContext context;
  final Customer customer;
  final VoidCallback navigateToCreateQuoteScreen;
  final MediaTabController mediaController;
  final VoidCallback showQuickCommunicationOptions;
  final VoidCallback? onUpdated;

  void editCustomer() {
    // Call extracted service with EXACT same logic
    CustomerOperationsService.showEditCustomerDialog(
      context: context,
      customer: customer,
      onCustomerUpdated: onUpdated,
    );
  }

  void showDeleteCustomerConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete ${customer.name}?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also delete all quotes, RoofScope data, and media associated with this customer.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Call extracted service with EXACT same logic
              CustomerOperationsService.performCustomerDeletion(
                context: context,
                customer: customer,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showQuickActions() {
    // Call extracted service with EXACT same logic
    CustomerOperationsService.showQuickActions(
      context: context,
      customer: customer,
      editCustomer: editCustomer,
      navigateToCreateQuoteScreen: navigateToCreateQuoteScreen,
      showQuickCommunicationOptions: showQuickCommunicationOptions,
      showDeleteCustomerConfirmation: showDeleteCustomerConfirmation,
    );
  }
}