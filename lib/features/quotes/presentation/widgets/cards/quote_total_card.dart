import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/quote_totals_controller.dart';
import '../../../../../app/theme/rufko_theme.dart';

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
    final combinedSubtotal = controller.combinedSubtotal; // This is now the discounted amount

    final taxRate = controller.taxRate;
    final taxAmount = controller.taxAmount;
    final finalTotal = controller.finalTotal;

    return Card(
      elevation: 0,
      color: RufkoTheme.primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RufkoTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currencyFormat.format(combinedSubtotal),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RufkoTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (taxRate > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (${taxRate.toStringAsFixed(1)}%):',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: RufkoTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat.format(taxAmount),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: RufkoTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Divider(
              thickness: 2,
              color: RufkoTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: RufkoTheme.primaryColor,
                  ),
                ),
                Text(
                  currencyFormat.format(finalTotal),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: RufkoTheme.primaryColor,
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
