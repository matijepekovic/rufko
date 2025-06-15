import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/product.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/quote_extras.dart';
import '../../services/quote_calculation_service.dart';
import 'permit_items_section.dart';
import 'custom_line_items_section.dart';

/// Reusable single-tier quote card widget
/// Extracted from QuoteTotalsSection for better maintainability
class SingleTierQuoteCard extends StatelessWidget {
  final QuoteLevel level;
  final Product mainProduct;
  final double mainQuantity;
  final double taxRate;
  final List<PermitItem> permits;
  final List<CustomLineItem> customLineItems;
  final NumberFormat currencyFormat;

  const SingleTierQuoteCard({
    super.key,
    required this.level,
    required this.mainProduct,
    required this.mainQuantity,
    required this.taxRate,
    required this.permits,
    required this.customLineItems,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final totals = QuoteCalculationService.calculateLevelTotals(
      level: level,
      taxRate: taxRate,
      permits: permits,
      customLineItems: customLineItems,
    );

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
          _buildMainProduct(),
          ..._buildIncludedProducts(),
          if (QuoteCalculationService.hasPermits(permits))
            PermitItemsSection(
              permits: permits,
              currencyFormat: currencyFormat,
              isCompact: false,
            ),
          if (QuoteCalculationService.hasCustomLineItems(customLineItems))
            CustomLineItemsSection(
              customLineItems: customLineItems,
              currencyFormat: currencyFormat,
              isCompact: false,
            ),
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          _buildSubtotal(totals),
          if (QuoteCalculationService.shouldShowTax(taxRate))
            _buildTaxLine(totals),
          const SizedBox(height: 12),
          _buildTotal(totals),
        ],
      ),
    );
  }

  /// Build main product line
  Widget _buildMainProduct() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '${mainProduct.name} (${mainQuantity.toStringAsFixed(1)} ${mainProduct.unit})',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ),
        Text(
          currencyFormat.format(level.baseProductTotal),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  /// Build included products lines
  List<Widget> _buildIncludedProducts() {
    return level.includedItems.map((product) => Padding(
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
    )).toList();
  }

  /// Build subtotal line
  Widget _buildSubtotal(QuoteTotals totals) {
    return Row(
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
          currencyFormat.format(totals.totalSubtotal),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.green.shade800,
          ),
        ),
      ],
    );
  }

  /// Build tax line
  Widget _buildTaxLine(QuoteTotals totals) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
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
            currencyFormat.format(totals.taxAmount),
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build total section
  Widget _buildTotal(QuoteTotals totals) {
    return Container(
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
            currencyFormat.format(totals.totalWithTax),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}