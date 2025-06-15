// lib/widgets/quote_levels_preview.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/simplified_quote.dart';

class QuoteLevelsPreview extends StatelessWidget {
  final List<QuoteLevel> quoteLevels;
  final Product? mainProduct;
  final double mainQuantity;
  final String quoteType;

  const QuoteLevelsPreview({
    super.key,
    required this.quoteLevels,
    required this.mainProduct,
    required this.mainQuantity,
    required this.quoteType,
  });

  @override
  Widget build(BuildContext context) {
    if (quoteLevels.isEmpty) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  quoteType == 'multi-level' ? Icons.layers : Icons.description,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  quoteType == 'multi-level' ? 'Quote Levels Created' : 'Quote Created',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: quoteType == 'multi-level' ? Colors.blue.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: quoteType == 'multi-level' ? Colors.blue.shade200 : Colors.green.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mainProduct!.name} (${mainQuantity.toStringAsFixed(1)}${mainProduct!.unit})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (quoteType == 'multi-level') ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: quoteLevels.map((level) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                level.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(level.baseProductTotal),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unit Price: ${currencyFormat.format(mainProduct!.unitPrice)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Quantity: ${mainQuantity.toStringAsFixed(1)} ${mainProduct!.unit}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormat.format(quoteLevels.first.baseProductTotal),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
