import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/simplified_quote.dart';

class QuoteTotalCard extends StatelessWidget {
  final SimplifiedMultiLevelQuote quote;
  final String selectedLevelId;
  final NumberFormat currencyFormat;

  const QuoteTotalCard({
    super.key,
    required this.quote,
    required this.selectedLevelId,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final level = quote.levels.firstWhere((l) => l.id == selectedLevelId);
    final levelSubtotal = level.subtotal;
    final addonSubtotal = quote.addons.fold(0.0, (sum, a) => sum + a.totalPrice);
    final combinedSubtotal = levelSubtotal + addonSubtotal;

    final discountSummary = quote.getDiscountSummary(selectedLevelId);
    final totalDiscount = discountSummary['totalDiscount'] as double;
    final subtotalAfterDiscount = combinedSubtotal - totalDiscount;

    final taxRate = quote.taxRate;
    final taxAmount = subtotalAfterDiscount * (taxRate / 100);
    final finalTotal = subtotalAfterDiscount + taxAmount;

    return Card(
      color: Theme.of(context).primaryColor.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                Text(currencyFormat.format(combinedSubtotal),
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            if (totalDiscount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:',
                      style: TextStyle(color: Colors.green, fontSize: 16)),
                  Text('-${currencyFormat.format(totalDiscount)}',
                      style:
                          const TextStyle(color: Colors.green, fontSize: 16)),
                ],
              ),
            ],
            if (taxRate > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax (${taxRate.toStringAsFixed(1)}%):',
                      style: const TextStyle(fontSize: 16)),
                  Text(currencyFormat.format(taxAmount),
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(finalTotal),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
