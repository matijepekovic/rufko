import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/quote_extras.dart';
import '../../services/quote_calculation_service.dart';

/// Reusable permit items section widget
/// Extracted from QuoteTotalsSection for better maintainability
class PermitItemsSection extends StatelessWidget {
  final List<PermitItem> permits;
  final NumberFormat currencyFormat;
  final bool isCompact;

  const PermitItemsSection({
    super.key,
    required this.permits,
    required this.currencyFormat,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!QuoteCalculationService.hasPermits(permits)) {
      return const SizedBox.shrink();
    }

    final permitsTotal = QuoteCalculationService.calculatePermitsTotal(permits);

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 4 : 8),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
        ),
        child: Column(
          children: [
            _buildPermitsHeader(permitsTotal),
            ..._buildPermitItems(),
          ],
        ),
      ),
    );
  }

  /// Build permits section header
  Widget _buildPermitsHeader(double permitsTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PERMITS:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade800,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
        Text(
          currencyFormat.format(permitsTotal),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade800,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
      ],
    );
  }

  /// Build individual permit items
  List<Widget> _buildPermitItems() {
    return permits.map((permit) => Padding(
      padding: EdgeInsets.only(top: isCompact ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '  ${permit.name}',
              style: TextStyle(fontSize: isCompact ? 11 : 12),
            ),
          ),
          Text(
            currencyFormat.format(permit.amount),
            style: TextStyle(fontSize: isCompact ? 11 : 12),
          ),
        ],
      ),
    )).toList();
  }
}