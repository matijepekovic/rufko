import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/quote/quote_service.dart';

import 'quote_filter_controller.dart';
import 'quote_navigation_controller.dart';
import 'quote_status_ui_controller.dart';
import '../widgets/status/quote_status_badge.dart';

/// Builds list views and empty state widgets for quotes.
class QuoteListBuilder {
  QuoteListBuilder(this.context, this.navigation) {
    _service = QuoteService();
    _statusController = QuoteStatusUIController.fromContext(context);
  }

  final BuildContext context;
  final QuoteNavigationController navigation;
  late final QuoteService _service;
  late final QuoteStatusUIController _statusController;

  Widget buildQuotesList({
    required AppStateProvider appState,
    required QuoteFilterController filter,
  }) {
    final quotes = filter.getFilteredQuotes();

    if (quotes.isEmpty) {
      return buildEmptyState(filter.selectedStatus, filter.searchQuery);
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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => navigation.navigateToSimplifiedQuoteDetail(quote, customer),
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
                        Text(
                          'Quote #: ${quote.quoteNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${customer.name}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Levels: ${quote.levels.length}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (value) => _handleMenuAction(value, quote, customer),
                        itemBuilder: (context) => _buildMenuItems(quote),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quote.levels.isNotEmpty
                          ? NumberFormat.currency(symbol: '\$')
                              .format(quote.getDisplayTotalForLevel(quote.levels.first.id))
                          : '\$0.00',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  QuoteStatusBadge(quote: quote),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if mark buttons should be shown for this quote
  bool _shouldShowMarkButtons(SimplifiedMultiLevelQuote quote) {
    return _service.shouldShowMarkButtons(quote);
  }

  /// Check if undo option should be shown for this quote
  bool _shouldShowUndoOption(SimplifiedMultiLevelQuote quote) {
    return _service.shouldShowUndoOption(quote);
  }

  /// Get accept button text based on quote levels
  String _getAcceptButtonText(SimplifiedMultiLevelQuote quote) {
    return _service.getMarkAcceptedButtonText(quote);
  }

  /// Get undo button text based on quote status
  String _getUndoButtonText(SimplifiedMultiLevelQuote quote) {
    return _service.getUndoButtonText(quote);
  }

  /// Handle mark accepted button tap
  void _handleMarkAccepted(SimplifiedMultiLevelQuote quote) {
    _statusController.handleMarkAccepted(context, quote);
  }

  /// Handle mark declined button tap
  void _handleMarkDeclined(SimplifiedMultiLevelQuote quote) {
    _statusController.handleMarkDeclined(context, quote);
  }

  /// Handle undo status change button tap
  void _handleUndoStatusChange(SimplifiedMultiLevelQuote quote) {
    _statusController.handleUndoStatusChange(context, quote);
  }

  /// Build menu items based on quote status
  List<PopupMenuEntry<String>> _buildMenuItems(SimplifiedMultiLevelQuote quote) {
    final items = <PopupMenuEntry<String>>[];
    
    // Always show view details
    items.add(const PopupMenuItem(
      value: 'view',
      child: Row(
        children: [
          Icon(Icons.visibility, size: 18),
          SizedBox(width: 8),
          Text('View Details'),
        ],
      ),
    ));

    // Show mark actions based on quote status
    if (_shouldShowMarkButtons(quote)) {
      items.add(const PopupMenuDivider());
      
      // Accept option
      final acceptText = _getAcceptButtonText(quote);
      items.add(PopupMenuItem(
        value: 'accept',
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text(acceptText),
          ],
        ),
      ));
      
      // Decline option
      items.add(const PopupMenuItem(
        value: 'decline',
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text('Decline'),
          ],
        ),
      ));
    }

    // Show undo option for accepted/declined quotes
    if (_shouldShowUndoOption(quote)) {
      items.add(const PopupMenuDivider());
      
      final undoText = _getUndoButtonText(quote);
      items.add(PopupMenuItem(
        value: 'undo',
        child: Row(
          children: [
            Icon(Icons.undo, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Text(undoText),
          ],
        ),
      ));
    }
    
    return items;
  }

  /// Handle menu action selection
  void _handleMenuAction(String action, SimplifiedMultiLevelQuote quote, Customer customer) {
    switch (action) {
      case 'view':
        navigation.navigateToSimplifiedQuoteDetail(quote, customer);
        break;
      case 'accept':
        _handleMarkAccepted(quote);
        break;
      case 'decline':
        _handleMarkDeclined(quote);
        break;
      case 'undo':
        _handleUndoStatusChange(quote);
        break;
    }
  }
}
