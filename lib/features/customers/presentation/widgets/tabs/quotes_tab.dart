import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../../../../core/services/quote/quote_service.dart';
import '../../../../quotes/presentation/controllers/quote_status_ui_controller.dart';
import '../../../../quotes/presentation/widgets/status/quote_status_badge.dart';

class QuotesTab extends StatefulWidget {
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
  State<QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  late final QuoteService _service;
  late final QuoteStatusUIController _statusController;

  @override
  void initState() {
    super.initState();
    _service = QuoteService();
    _statusController = QuoteStatusUIController.fromContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final quotes = appState.getSimplifiedQuotesForCustomer(widget.customer.id);
        quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No quotes for ${widget.customer.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: widget.onCreateQuote,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Quote'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quotes.length,
                itemBuilder: (context, index) {
                  final quote = quotes[index];
                  return _buildQuoteCard(quote);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: RufkoPrimaryButton(
                onPressed: widget.onCreateQuote,
                icon: Icons.add,
                isFullWidth: true,
                child: const Text('Create New Quote'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuoteCard(SimplifiedMultiLevelQuote quote) {
    double representativeTotal = 0;
    String levelSummary = '${quote.levels.length} level${quote.levels.length == 1 ? '' : 's'}';

    if (quote.levels.isNotEmpty) {
      representativeTotal = quote.getDisplayTotalForLevel(quote.levels.first.id);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onOpenQuote(quote),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                    child: Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          '$levelSummary • Created: ${DateFormat('MMM dd, yyyy').format(quote.createdAt)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) => _handleMenuAction(value, quote),
                    itemBuilder: (context) => _buildMenuItems(quote),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      NumberFormat.currency(symbol: '\$').format(representativeTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ),
                  QuoteStatusBadgeSmall(quote: quote),
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
  void _handleMenuAction(String action, SimplifiedMultiLevelQuote quote) {
    switch (action) {
      case 'view':
        widget.onOpenQuote(quote);
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
