import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/quote.dart';
import '../models/customer.dart';

class RecentQuotesList extends StatelessWidget {
  const RecentQuotesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final recentQuotes = appState.quotes
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final limitedQuotes = recentQuotes.take(5).toList();

        if (limitedQuotes.isEmpty) {
          return Card(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quotes yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first quote to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Quotes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (appState.quotes.length > 5)
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all quotes
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
              ),
              ...limitedQuotes.asMap().entries.map((entry) {
                final index = entry.key;
                final quote = entry.value;
                final customer = appState.customers.firstWhere(
                      (c) => c.id == quote.customerId,
                  orElse: () => Customer(name: 'Unknown'),
                );

                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1),
                    _QuoteListItem(
                      quote: quote,
                      customer: customer,
                      onTap: () {
                        // TODO: Navigate to quote detail
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing quote ${quote.quoteNumber}'),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _QuoteListItem extends StatelessWidget {
  final Quote quote;
  final Customer customer;
  final VoidCallback onTap;

  const _QuoteListItem({
    required this.quote,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getStatusColor(quote.status).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getStatusIcon(quote.status),
          color: _getStatusColor(quote.status),
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              quote.quoteNumber,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(quote.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(quote.status).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              quote.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(quote.status),
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            customer.name,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(quote.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                currencyFormat.format(quote.total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit_outlined;
      case 'sent':
        return Icons.send_outlined;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'declined':
        return Icons.cancel_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}