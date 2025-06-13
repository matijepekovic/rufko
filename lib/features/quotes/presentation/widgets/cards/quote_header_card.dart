import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/customer.dart';

class QuoteHeaderCard extends StatelessWidget {
  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  const QuoteHeaderCard({
    super.key,
    required this.quote,
    required this.customer,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: ${customer.name}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (customer.fullDisplayAddress.isNotEmpty &&
                          customer.fullDisplayAddress != 'No address provided')
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(customer.fullDisplayAddress,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      Text('Quote ID: ${quote.id}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('Created: ${DateFormat('MMM dd, yyyy').format(quote.createdAt)}'),
                      Text('Valid Until: ${DateFormat('MMM dd, yyyy').format(quote.validUntil)}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(quote.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    quote.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
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
