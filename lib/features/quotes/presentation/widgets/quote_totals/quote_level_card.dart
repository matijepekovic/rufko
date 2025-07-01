import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/product.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/quote_extras.dart';
import '../../services/quote_calculation_service.dart';
import 'permit_items_section.dart';
import 'custom_line_items_section.dart';
import '../../../../../core/utils/helpers/common_utils.dart';

/// Reusable quote level card widget for multi-level quotes
/// Extracted from QuoteTotalsSection for better maintainability
/// Now supports discount calculations when SimplifiedMultiLevelQuote is provided
class QuoteLevelCard extends StatelessWidget {
  final QuoteLevel level;
  final Product? mainProduct;
  final double mainQuantity;
  final double taxRate;
  final List<PermitItem> permits;
  final List<CustomLineItem> customLineItems;
  final NumberFormat currencyFormat;
  final SimplifiedMultiLevelQuote? quote; // NEW: Optional quote for discount calculations

  const QuoteLevelCard({
    super.key,
    required this.level,
    this.mainProduct,
    required this.mainQuantity,
    required this.taxRate,
    required this.permits,
    required this.customLineItems,
    required this.currencyFormat,
    this.quote, // NEW: Optional quote parameter
  });

  @override
  Widget build(BuildContext context) {
    // Use quote's authoritative calculations if available (with discounts)
    // Otherwise fall back to QuoteCalculationService (for creation/editing)
    final QuoteTotals totals;
    
    if (quote != null && quote!.discounts.isNotEmpty) {
      // Use quote's discount-aware calculations
      final discountedSubtotal = quote!.getDiscountedSubtotalForLevel(level.id);
      final taxAmount = quote!.getTaxAmountForLevel(level.id);
      final totalWithTax = quote!.getDisplayTotalForLevel(level.id);
      
      totals = QuoteTotals(
        levelSubtotal: level.subtotal,
        permitsTotal: QuoteCalculationService.calculatePermitsTotal(permits),
        taxableCustomItems: QuoteCalculationService.calculateTaxableCustomItemsTotal(customLineItems),
        nonTaxableCustomItems: QuoteCalculationService.calculateNonTaxableCustomItemsTotal(customLineItems),
        taxableSubtotal: discountedSubtotal,
        nonTaxableSubtotal: 0.0,
        totalSubtotal: discountedSubtotal, // This is the discounted subtotal
        taxAmount: taxAmount,
        totalWithTax: totalWithTax,
      );
    } else {
      // Use original calculation service (no discounts)
      totals = QuoteCalculationService.calculateLevelTotals(
        level: level,
        taxRate: taxRate,
        permits: permits,
        customLineItems: customLineItems,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelHeader(),
          const SizedBox(height: 8),
          _buildMainProduct(),
          ..._buildIncludedProducts(),
          if (QuoteCalculationService.hasPermits(permits))
            PermitItemsSection(
              permits: permits,
              currencyFormat: currencyFormat,
              isCompact: true,
            ),
          if (QuoteCalculationService.hasCustomLineItems(customLineItems))
            CustomLineItemsSection(
              customLineItems: customLineItems,
              currencyFormat: currencyFormat,
              isCompact: true,
            ),
          const Divider(),
          _buildSubtotal(totals),
          if (QuoteCalculationService.shouldShowTax(taxRate))
            _buildTaxLine(totals),
          const SizedBox(height: 8),
          _buildTotal(totals),
        ],
      ),
    );
  }

  /// Build level header with name
  Widget _buildLevelHeader() {
    return Text(
      level.name,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.blue.shade800,
      ),
    );
  }

  /// Build main product line
  Widget _buildMainProduct() {
    if (mainProduct == null) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '${mainProduct!.name} (${formatQuantity(mainQuantity)} ${mainProduct!.unit})',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          currencyFormat.format(level.baseProductTotal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Build included products lines
  List<Widget> _buildIncludedProducts() {
    return level.includedItems.map((product) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${product.productName} (${formatQuantity(product.quantity)} ${product.unit})',
            ),
          ),
          Text(currencyFormat.format(product.totalPrice)),
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
            color: Colors.blue.shade800,
          ),
        ),
        Text(
          currencyFormat.format(totals.totalSubtotal),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  /// Build tax line
  Widget _buildTaxLine(QuoteTotals totals) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TAX (${taxRate.toStringAsFixed(2)}%):',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            currencyFormat.format(totals.taxAmount),
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build total section
  Widget _buildTotal(QuoteTotals totals) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade800,
            ),
          ),
          Text(
            currencyFormat.format(totals.totalWithTax),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}