import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/simplified_quote.dart';

class LevelDetailsCard extends StatelessWidget {
  final QuoteLevel level;
  final SimplifiedMultiLevelQuote quote;
  final NumberFormat currencyFormat;

  const LevelDetailsCard({
    super.key,
    required this.level,
    required this.quote,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${level.name} Details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base Product: ${quote.baseProductName ?? "N/A"}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Quantity: ${level.baseQuantity.toStringAsFixed(1)} ${quote.baseProductUnit ?? "units"}') ,
                      Text('Unit Price: ${currencyFormat.format(level.basePrice)}'),
                    ],
                  ),
                  Text(currencyFormat.format(level.baseProductTotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            if (level.includedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Additional Items:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...level.includedItems.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('${item.quantity.toStringAsFixed(1)} ${item.unit} @ ${currencyFormat.format(item.unitPrice)} each'),
                        ],
                      ),
                    ),
                    Text(currencyFormat.format(item.totalPrice),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              )),
            ],
            const Divider(),
            _buildPricingBreakdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown(BuildContext context) {
    // Calculate pricing breakdown
    final levelSubtotal = level.subtotal;
    final addonsTotal = quote.addons.fold<double>(0.0, (sum, addon) => sum + addon.totalPrice);
    final subtotalWithAddons = levelSubtotal + addonsTotal;
    
    // Calculate discounts
    final discountAmount = quote.discounts.fold<double>(0.0, (sum, discount) {
      if (!discount.isValid) return sum;
      return sum + discount.calculateDiscountAmount(subtotalWithAddons);
    });
    final subtotalAfterDiscounts = subtotalWithAddons - discountAmount;
    
    // Calculate tax
    final taxAmount = subtotalAfterDiscounts * (quote.taxRate / 100);
    final finalTotal = subtotalAfterDiscounts + taxAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pricing Summary',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        // Add-ons if present
        if (addonsTotal > 0) ...[
          _buildPriceInfoRow(
            context,
            Icons.add_box_outlined,
            'Add-ons',
            currencyFormat.format(addonsTotal),
          ),
          const SizedBox(height: 8),
        ],
        
        // Subtotal in container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_outlined, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Subtotal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                currencyFormat.format(subtotalWithAddons),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // Discounts if present
        if (discountAmount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 18, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Discounts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '-${currencyFormat.format(discountAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Tax if present
        if (quote.taxRate > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_outlined, size: 18, color: Colors.amber[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tax (${quote.taxRate.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  currencyFormat.format(taxAmount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Final Total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).primaryColor.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(Icons.monetization_on_outlined, 
                   size: 20, 
                   color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Text(
                currencyFormat.format(finalTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
