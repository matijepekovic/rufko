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
              ...level.includedItems.map((item) => ListTile(
                    dense: true,
                    title: Text(item.productName),
                    subtitle: Text('${item.quantity.toStringAsFixed(1)} ${item.unit} @ ${currencyFormat.format(item.unitPrice)} each'),
                    trailing: Text(currencyFormat.format(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Level Subtotal:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(level.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
