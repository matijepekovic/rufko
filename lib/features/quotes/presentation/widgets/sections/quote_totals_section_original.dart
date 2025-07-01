// lib/widgets/quote_totals_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/product.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/quote_extras.dart';

class QuoteTotalsSection extends StatelessWidget {
  final List<QuoteLevel> quoteLevels;
  final Product? mainProduct;
  final double mainQuantity;
  final double taxRate;
  final List<PermitItem> permits;
  final List<CustomLineItem> customLineItems;
  final String quoteType;

  const QuoteTotalsSection({
    super.key,
    required this.quoteLevels,
    required this.mainProduct,
    required this.mainQuantity,
    required this.taxRate,
    required this.permits,
    required this.customLineItems,
    required this.quoteType,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 3,
      color: quoteType == 'multi-level' ? Colors.blue.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: quoteType == 'multi-level' ? Colors.blue.shade700 : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  quoteType == 'multi-level' ? 'Quote Totals' : 'Quote Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: quoteType == 'multi-level' ? Colors.blue.shade800 : Colors.green.shade800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (quoteType == 'multi-level') ...[
              Column(
                children: quoteLevels.map((level) {
                  final levelSubtotal = level.subtotal;
                  final permitsTotal = permits.fold(0.0, (sum, permit) => sum + permit.amount);
                  final taxableCustomItems =
                      customLineItems.where((item) => item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);
                  final nonTaxableCustomItems =
                      customLineItems.where((item) => !item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);

                  final taxableSubtotal = levelSubtotal + permitsTotal + taxableCustomItems;
                  final nonTaxableSubtotal = nonTaxableCustomItems;
                  final totalSubtotal = taxableSubtotal + nonTaxableSubtotal;
                  final taxAmount = taxableSubtotal * (taxRate / 100);
                  final totalWithTax = totalSubtotal + taxAmount;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${mainProduct!.name} (${mainQuantity.toStringAsFixed(1)} ${mainProduct!.unit})',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              currencyFormat.format(level.baseProductTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        ...level.includedItems.map((product) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${product.productName} (${product.quantity.toStringAsFixed(1)} ${product.unit})',
                                    ),
                                  ),
                                  Text(currencyFormat.format(product.totalPrice)),
                                ],
                              ),
                            )),
                        if (permits.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'PERMITS:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(permitsTotal),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                ...permits.map((permit) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '  ${permit.name}',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                          Text(
                                            currencyFormat.format(permit.amount),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                        if (customLineItems.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CUSTOM ITEMS:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(customLineItems.fold(0.0, (sum, item) => sum + item.amount)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                ...customLineItems.map((item) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '  ${item.name}${item.isTaxable ? '' : ' (non-taxable)'}',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          ),
                                          Text(
                                            currencyFormat.format(item.amount),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SUBTOTAL:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalSubtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        if (taxRate > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TAX (${taxRate.toStringAsFixed(2)}%):',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                currencyFormat.format(taxAmount),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              Text(
                                currencyFormat.format(totalWithTax),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              _buildSingleTierTotal(currencyFormat),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleTierTotal(NumberFormat currencyFormat) {
    final level = quoteLevels.first;
    final levelSubtotal = level.subtotal;

    final permitsTotal = permits.fold(0.0, (sum, permit) => sum + permit.amount);
    final taxableCustomItems =
        customLineItems.where((item) => item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);
    final nonTaxableCustomItems =
        customLineItems.where((item) => !item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);

    final taxableSubtotal = levelSubtotal + permitsTotal + taxableCustomItems;
    final nonTaxableSubtotal = nonTaxableCustomItems;
    final totalSubtotal = taxableSubtotal + nonTaxableSubtotal;

    final taxAmount = taxableSubtotal * (taxRate / 100);
    final totalWithTax = totalSubtotal + taxAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${mainProduct!.name} (${mainQuantity.toStringAsFixed(1)} ${mainProduct!.unit})',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ),
              Text(
                currencyFormat.format(level.baseProductTotal),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          ...level.includedItems.map((product) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${product.productName} (${product.quantity.toStringAsFixed(1)} ${product.unit})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      currencyFormat.format(product.totalPrice),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              )),
          if (permits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PERMITS:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currencyFormat.format(permitsTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  ...permits.map((permit) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '  ${permit.name}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              currencyFormat.format(permit.amount),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          if (customLineItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CUSTOM ITEMS:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currencyFormat.format(customLineItems.fold(0.0, (sum, item) => sum + item.amount)),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  ...customLineItems.map((item) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '  ${item.name}${item.isTaxable ? '' : ' (non-taxable)'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              currencyFormat.format(item.amount),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUBTOTAL:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                currencyFormat.format(totalSubtotal),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          if (taxRate > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TAX (${taxRate.toStringAsFixed(2)}%):',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  currencyFormat.format(taxAmount),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  currencyFormat.format(totalWithTax),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

