import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/business/customer.dart';
import '../../../data/providers/state/app_state_provider.dart';
import '../../../features/customers/presentation/widgets/customer_edit_dialog.dart';

/// Service that contains EXACT customer operation logic copied from CustomerActionsControllerLegacy
/// This is pure extraction - no rewriting of business logic
class CustomerOperationsService {
  
  /// EXACT COPY of the delete logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static void performCustomerDeletion({
    required BuildContext context,
    required Customer customer,
  }) {
    // EXACT COPY of lines 87-95 from CustomerActionsControllerLegacy
    context.read<AppStateProvider>().deleteCustomer(customer.id);
    Navigator.pop(context);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${customer.name} deleted successfully'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// EXACT COPY of the edit customer logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static void showEditCustomerDialog({
    required BuildContext context,
    required Customer customer,
    required VoidCallback? onCustomerUpdated,
  }) {
    // EXACT COPY of lines 29-37 from CustomerActionsControllerLegacy
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerEditDialog(
        customer: customer,
        onCustomerUpdated: onCustomerUpdated,
      ),
    );
  }

  /// EXACT COPY of the quick actions logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static void showQuickActions({
    required BuildContext context,
    required Customer customer,
    required VoidCallback editCustomer,
    required VoidCallback navigateToCreateQuoteScreen,
    required VoidCallback showQuickCommunicationOptions,
    required VoidCallback showDeleteCustomerConfirmation,
  }) {
    // EXACT COPY of lines 88-172 from CustomerActionsControllerLegacy
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    customer.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      editCustomer();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.description,
                    label: 'Quote',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      navigateToCreateQuoteScreen();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.message,
                    label: 'Contact',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      showQuickCommunicationOptions();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      showDeleteCustomerConfirmation();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// EXACT COPY of _ActionButton widget from CustomerActionsControllerLegacy
/// This is the ORIGINAL working code, just moved to a service
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}