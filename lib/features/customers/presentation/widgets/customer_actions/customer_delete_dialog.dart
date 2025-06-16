import 'package:flutter/material.dart';
import '../../../../../data/models/business/customer.dart';

/// Dialog for confirming customer deletion
/// Separated from controller logic for better UI organization
class CustomerDeleteDialog extends StatelessWidget {
  final Customer customer;
  final VoidCallback onConfirm;

  const CustomerDeleteDialog({
    super.key,
    required this.customer,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}