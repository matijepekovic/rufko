import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';

import 'quote_filter_controller.dart';
import 'quote_navigation_controller.dart';

/// Builds list views and empty state widgets for quotes.
class QuoteListBuilder {
  QuoteListBuilder(this.context, this.navigation);

  final BuildContext context;
  final QuoteNavigationController navigation;

  Widget buildQuotesList({
    required AppStateProvider appState,
    required String statusFilter,
    required String searchQuery,
  }) {
    final filter = QuoteFilterController(appState);
    final quotes = filter.getFilteredQuotes(
      status: statusFilter,
      searchQuery: searchQuery,
    );

    if (quotes.isEmpty) {
      return buildEmptyState(statusFilter, searchQuery);
    }

    return RefreshIndicator(
      onRefresh: () => appState.loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          final customer = appState.customers.firstWhere(
            (c) => c.id == quote.customerId,
            orElse: () => Customer(name: 'Unknown Customer'),
          );
          return _buildQuoteCard(quote, customer);
        },
      ),
    );
  }

  Widget buildEmptyState(String status, String searchQuery) {
    final title =
        searchQuery.isEmpty ? 'No quotes for "$status"' : 'No quotes found';
    final subtitle = searchQuery.isEmpty
        ? 'Create a new quote to see it here.'
        : 'Try a different search or filter.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (status == 'All' && searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: navigation.navigateToCreateQuote,
              icon: const Icon(Icons.add),
              label: const Text('Create New Quote'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildQuoteCard(SimplifiedMultiLevelQuote quote, Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Quote #: ${quote.quoteNumber}'),
        subtitle: Text(
          'Customer: ${customer.name}\nStatus: ${quote.status} - Levels: ${quote.levels.length}',
        ),
        trailing: Text(
          quote.levels.isNotEmpty
              ? NumberFormat.currency(symbol: '\$')
                  .format(quote.getDisplayTotalForLevel(quote.levels.first.id))
              : '\$0.00',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () =>
            navigation.navigateToSimplifiedQuoteDetail(quote, customer),
        isThreeLine: true,
      ),
    );
  }
}
