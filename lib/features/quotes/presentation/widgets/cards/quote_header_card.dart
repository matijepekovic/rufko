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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuoteHeader(context),
            const SizedBox(height: 16),
            _buildQuoteDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteHeader(BuildContext context) {
    return Row(
      children: [
        _buildQuoteAvatar(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quote ${quote.quoteNumber} v${quote.version}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Customer: ${customer.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
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
    );
  }

  Widget _buildQuoteAvatar(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.description_outlined,
        color: Theme.of(context).primaryColor,
        size: 28,
      ),
    );
  }

  Widget _buildQuoteDetails(BuildContext context) {
    return Column(
      children: [
        if (customer.fullDisplayAddress.isNotEmpty &&
            customer.fullDisplayAddress != 'No address provided')
          _buildInfoRow(context, Icons.location_on_outlined, 'Address', customer.fullDisplayAddress),
        if (customer.phone != null && customer.phone!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(context, Icons.phone_outlined, 'Phone', customer.phone!),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(context, Icons.calendar_today_outlined, 'Created', DateFormat('MMM dd, yyyy').format(quote.createdAt)),
        const SizedBox(height: 12),
        _buildInfoRow(context, Icons.schedule_outlined, 'Valid Until', DateFormat('MMM dd, yyyy').format(quote.validUntil)),
        const SizedBox(height: 12),
        _buildInfoRow(context, Icons.tag_outlined, 'Quote ID', quote.id),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
