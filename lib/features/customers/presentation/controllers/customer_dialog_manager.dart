import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../widgets/dialogs/customer_form_dialog.dart';
import 'customer_import_controller.dart';

class CustomerDialogManager {
  CustomerDialogManager(this.context, this.importController);

  final BuildContext context;
  final CustomerImportController importController;

  void showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => const CustomerFormDialog(),
    );
  }

  void showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(customer: customer),
    );
  }

  void showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              dialogContext
                  .read<AppStateProvider>()
                  .deleteCustomer(customer.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${customer.name} deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Customers',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.contacts, color: Colors.blue.shade700),
              ),
              title: const Text('Import from Device Contacts'),
              subtitle: const Text('Select customers from your phone contacts'),
              onTap: () {
                Navigator.pop(context);
                importController.importFromContacts();
              },
            ),
          ],
        ),
      ),
    );
  }
}
