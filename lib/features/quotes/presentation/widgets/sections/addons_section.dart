import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/simplified_quote.dart';

class AddonsSection extends StatelessWidget {
  final SimplifiedMultiLevelQuote quote;
  final NumberFormat currencyFormat;

  const AddonsSection({
    super.key,
    required this.quote,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (quote.addons.isEmpty) {
      return const SizedBox.shrink();
    }

    final addonTotal =
        quote.addons.fold<double>(0.0, (sum, addon) => sum + addon.totalPrice);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optional Add-ons:',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...quote.addons.map(
              (addon) => ListTile(
                dense: true,
                title: Text(addon.productName),
                subtitle: Text(
                  '${addon.quantity.toStringAsFixed(1)} ${addon.unit} @ '
                  '${currencyFormat.format(addon.unitPrice)} each',
                ),
                trailing: Text(
                  currencyFormat.format(addon.totalPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add-ons Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(addonTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
