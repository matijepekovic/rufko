import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/quote_totals_controller.dart';

class QuoteTotalCard extends StatelessWidget {
  final QuoteTotalsController controller;
  final NumberFormat currencyFormat;

  const QuoteTotalCard({
    super.key,
    required this.controller,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final combinedSubtotal = controller.combinedSubtotal;

    final totalDiscount = controller.totalDiscount;

    final taxRate = controller.taxRate;
    final taxAmount = controller.taxAmount;
    final finalTotal = controller.finalTotal;

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
