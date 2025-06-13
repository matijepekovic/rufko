import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../widgets/customer_edit_dialog.dart';
import '../widgets/media_tab_controller.dart';

class CustomerActionsController {
  CustomerActionsController({
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerEditDialog(
        customer: customer,
        onCustomerUpdated: onUpdated,
      ),
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
              context.read<AppStateProvider>().deleteCustomer(customer.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${customer.name} deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.green),
              title: const Text('Create New Quote'),
              onTap: () {
                Navigator.pop(context);
                navigateToCreateQuoteScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(context);
                editCustomer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Add Media'),
              onTap: () {
                Navigator.pop(context);
                mediaController.showMediaOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.purple),
              title: const Text('Quick Communication'),
              onTap: () {
                Navigator.pop(context);
                showQuickCommunicationOptions();
              },
            ),
          ],
        ),
      ),
    );
  }
}
