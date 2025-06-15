import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/quote_extras.dart';
import '../../services/quote_calculation_service.dart';

/// Reusable custom line items section widget
/// Extracted from QuoteTotalsSection for better maintainability
class CustomLineItemsSection extends StatelessWidget {
  final List<CustomLineItem> customLineItems;
  final NumberFormat currencyFormat;
  final bool isCompact;

  const CustomLineItemsSection({
    super.key,
    required this.customLineItems,
    required this.currencyFormat,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!QuoteCalculationService.hasCustomLineItems(customLineItems)) {
      return const SizedBox.shrink();
    }

    final customItemsTotal = QuoteCalculationService.calculateCustomItemsTotal(customLineItems);

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 4 : 8),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
        ),
        child: Column(
          children: [
            _buildCustomItemsHeader(customItemsTotal),
            ..._buildCustomLineItems(),
          ],
        ),
      ),
    );
  }

  /// Build custom items section header
  Widget _buildCustomItemsHeader(double customItemsTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'CUSTOM ITEMS:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.purple.shade800,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
        Text(
          currencyFormat.format(customItemsTotal),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.purple.shade800,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
      ],
    );
  }

  /// Build individual custom line items
  List<Widget> _buildCustomLineItems() {
    return customLineItems.map((item) => Padding(
      padding: EdgeInsets.only(top: isCompact ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '  ${item.name}${item.isTaxable ? '' : ' (non-taxable)'}',
              style: TextStyle(fontSize: isCompact ? 11 : 12),
            ),
          ),
          Text(
            currencyFormat.format(item.amount),
            style: TextStyle(fontSize: isCompact ? 11 : 12),
          ),
        ],
      ),
    )).toList();
  }
}