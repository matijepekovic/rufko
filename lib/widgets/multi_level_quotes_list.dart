import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/multi_level_quote.dart';
import '../models/customer.dart';
import '../screens/create_multi_level_quote_screen.dart';

class MultiLevelQuotesList extends StatelessWidget {
  final String? customerId;
  final List<MultiLevelQuote>? quotes;
  final Function(MultiLevelQuote)? onTap;

  const MultiLevelQuotesList({
    Key? key,
    this.customerId,
    this.quotes,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        List<MultiLevelQuote> displayQuotes;

        if (quotes != null) {
          displayQuotes = quotes!;
        } else if (customerId != null) {
          displayQuotes = appState.getMultiLevelQuotesForCustomer(customerId!);
        } else {
          displayQuotes = appState.multiLevelQuotes;
        }

        displayQuotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (displayQuotes.isEmpty) {
          return Card(
            child: Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No multi-level quotes yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first multi-level quote to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: displayQuotes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final quote = displayQuotes[index];
            final customer = appState.customers.firstWhere(
              (c) => c.id == quote.customerId,
              orElse: () => Customer(name: 'Unknown'),
            );

            return _MultiLevelQuoteCard(
              quote: quote,
              customer: customer,
              onTap: () {
                if (onTap != null) {
                  onTap!(quote);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiLevelQuoteDetailScreen(
                        quote: quote,
                        customer: customer,
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _MultiLevelQuoteCard extends StatelessWidget {
  final MultiLevelQuote quote;
  final Customer customer;
  final VoidCallback onTap;

  const _MultiLevelQuoteCard({
    required this.quote,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    // Get levels sorted by number
    final sortedLevels = quote.levels.values.toList()
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

    // Get the highest level's total for display
    double highestTotal = 0;
    String? highestLevelName;

    if (sortedLevels.isNotEmpty) {
      final highestLevel = sortedLevels.last;
      highestTotal = quote.getLevelTotal(highestLevel.levelId);
      highestLevelName = highestLevel.levelName;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quote ${quote.quoteNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusBadge(quote.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(customer.name),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dateFormat.format(quote.createdAt)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    quote.isExpired ? 'Expired' : 'Valid until ${dateFormat.format(quote.validUntil)}',
                    style: TextStyle(
                      color: quote.isExpired ? Colors.red : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Levels: ${quote.levels.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: sortedLevels.map((level) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getLevelColor(level.levelNumber).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              level.levelName,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getLevelColor(level.levelNumber),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (highestLevelName != null)
                        Text(
                          highestLevelName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        currencyFormat.format(highestTotal),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'sent':
        color = Colors.blue;
        break;
      case 'accepted':
        color = Colors.green;
        break;
      case 'declined':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getLevelColor(int levelNumber) {
    switch (levelNumber % 3) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green.shade700;
      case 2:
        return Colors.orange.shade800;
      default:
        return Colors.purple;
    }
  }
}
