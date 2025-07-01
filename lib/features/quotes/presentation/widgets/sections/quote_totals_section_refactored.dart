import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/product.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/quote_extras.dart';
import '../quote_totals/quote_level_card.dart';
import '../quote_totals/single_tier_quote_card.dart';

/// Refactored QuoteTotalsSection with extracted components and calculation service
/// Original 559-line monolithic widget broken down into manageable components
/// All original functionality preserved with improved maintainability
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
            _buildHeader(context),
            const SizedBox(height: 16),
            if (quoteType == 'multi-level')
              _buildMultiLevelQuotes(currencyFormat)
            else
              _buildSingleTierQuote(currencyFormat),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildHeader(BuildContext context) {
    return Row(
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
    );
  }

  /// Build multi-level quotes layout
  Widget _buildMultiLevelQuotes(NumberFormat currencyFormat) {
    return Column(
      children: quoteLevels.map((level) {
        return QuoteLevelCard(
          level: level,
          mainProduct: mainProduct!,
          mainQuantity: mainQuantity,
          taxRate: taxRate,
          permits: permits,
          customLineItems: customLineItems,
          currencyFormat: currencyFormat,
        );
      }).toList(),
    );
  }

  /// Build single-tier quote layout
  Widget _buildSingleTierQuote(NumberFormat currencyFormat) {
    final level = quoteLevels.first;
    
    return SingleTierQuoteCard(
      level: level,
      mainProduct: mainProduct!,
      mainQuantity: mainQuantity,
      taxRate: taxRate,
      permits: permits,
      customLineItems: customLineItems,
      currencyFormat: currencyFormat,
    );
  }
}