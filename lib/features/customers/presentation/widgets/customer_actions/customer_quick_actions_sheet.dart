import 'package:flutter/material.dart';
import '../../../../../data/models/business/customer.dart';
import '../../../../../core/services/customer/customer_service.dart';

/// Bottom sheet for customer quick actions
/// Separated from controller logic for better UI organization
class CustomerQuickActionsSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEditCustomer;
  final VoidCallback onDeleteCustomer;
  final VoidCallback onCreateQuote;
  final VoidCallback onShowCommunication;
  final CustomerStats? customerStats;

  const CustomerQuickActionsSheet({
    super.key,
    required this.customer,
    required this.onEditCustomer,
    required this.onDeleteCustomer,
    required this.onCreateQuote,
    required this.onShowCommunication,
    this.customerStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customerStats != null)
                      Text(
                        '${customerStats!.quotesCount} quotes • ${customerStats!.documentsCount} docs • ${customerStats!.mediaCount} media',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  color: Colors.blue,
                  onTap: onEditCustomer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.description,
                  label: 'Quote',
                  color: Colors.green,
                  onTap: onCreateQuote,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.message,
                  label: 'Contact',
                  color: Colors.orange,
                  onTap: onShowCommunication,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: onDeleteCustomer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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