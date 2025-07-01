import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/simplified_quote.dart';

class DiscountsSection extends StatelessWidget {
  final List<QuoteDiscount> discounts;
  final String? selectedLevelId;
  final SimplifiedMultiLevelQuote quote;
  final VoidCallback? onAddDiscount; // Made optional for read-only mode
  final Function(String)? onRemoveDiscount; // Made optional for read-only mode
  final NumberFormat currencyFormat;

  const DiscountsSection({
    super.key,
    required this.discounts,
    required this.selectedLevelId,
    required this.quote,
    this.onAddDiscount,
    this.onRemoveDiscount,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (discounts.isEmpty) {
      return const SizedBox.shrink(); // Hide when no discounts
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Applied Discounts:',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (onAddDiscount != null)
                  TextButton.icon(
                    onPressed: onAddDiscount,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...discounts.map((discount) => _buildDiscountItem(discount)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountItem(QuoteDiscount discount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: discount.isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: discount.isValid ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            discount.isValid ? Icons.check_circle : Icons.error,
            color: discount.isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discount.description ?? '${discount.type.toUpperCase()} Discount',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  discount.type == 'percentage'
                      ? '${discount.value.toStringAsFixed(1)}% off'
                      : currencyFormat.format(discount.value),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (discount.code != null)
                  Text('Code: ${discount.code}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (discount.isExpired)
                  Text('EXPIRED',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (onRemoveDiscount != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => onRemoveDiscount!(discount.id),
            ),
        ],
      ),
    );
  }

}
