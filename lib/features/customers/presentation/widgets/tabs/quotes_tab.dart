import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/providers/state/app_state_provider.dart';

class QuotesTab extends StatelessWidget {
  final Customer customer;
  final VoidCallback onCreateQuote;
  final void Function(SimplifiedMultiLevelQuote) onOpenQuote;

  const QuotesTab({
    super.key,
    required this.customer,
    required this.onCreateQuote,
    required this.onOpenQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final quotes = appState.getSimplifiedQuotesForCustomer(customer.id);
        quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No quotes for ${customer.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onCreateQuote,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Quote'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            double representativeTotal = 0;
            String levelSummary = '${quote.levels.length} level${quote.levels.length == 1 ? '' : 's'}';

            if (quote.levels.isNotEmpty) {
              representativeTotal = quote.getDisplayTotalForLevel(quote.levels.first.id);
            }

            return Card(
              elevation: 1.5,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                  child: Icon(
                    Icons.description_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  'Quote #: ${quote.quoteNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Status: ${quote.status.toUpperCase()} - $levelSummary\nCreated: ${DateFormat('MMM dd, yyyy').format(quote.createdAt)}',
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(representativeTotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                onTap: () => onOpenQuote(quote),
                isThreeLine: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              ),
            );
          },
        );
      },
    );
  }
}
