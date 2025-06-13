// lib/widgets/customer_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/business/customer.dart'; // Ensure this uses the updated Customer model

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final int quoteCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.quoteCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final greyColor600 = Colors.grey[600];
    final greyColor500 = Colors.grey[500];
    final greyColor400 = Colors.grey[400];

    // Use the new getter for a combined address display
    final String displayAddress = customer.fullDisplayAddress;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer.phone != null || customer.email != null)
                          Text(
                            customer.phone ?? customer.email!,
                            style: textTheme.bodyMedium?.copyWith(color: greyColor600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: greyColor600),
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                        if (onDelete != null)
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))])),
                      ],
                    ),
                ],
              ),

              // UPDATED: Displaying the full address using the new getter
              if (displayAddress.isNotEmpty && displayAddress != 'No address provided') ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: greyColor600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayAddress, // Use the new combined address
                        style: textTheme.bodySmall?.copyWith(color: greyColor600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 16, color: greyColor600),
                  const SizedBox(width: 8),
                  Text(
                    '$quoteCount Quote${quoteCount == 1 ? "" : "s"}',
                    style: textTheme.bodySmall?.copyWith(color: greyColor600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Added: ${dateFormat.format(customer.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(color: greyColor500),
                  ),
                  Row(
                    children: [
                      if (customer.communicationHistory.isNotEmpty) ...[
                        Icon(Icons.chat_bubble_outline, size: 14, color: greyColor500),
                        const SizedBox(width: 4),
                        Text(
                          '${customer.communicationHistory.length}',
                          style: textTheme.bodySmall?.copyWith(color: greyColor500),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.arrow_forward_ios, size: 12, color: greyColor400),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}