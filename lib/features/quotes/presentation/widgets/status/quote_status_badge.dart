import 'package:flutter/material.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../core/services/quote/quote_service.dart';

/// Pure UI component for displaying quote status badges
class QuoteStatusBadge extends StatelessWidget {
  final SimplifiedMultiLevelQuote quote;
  final bool showExpired;

  const QuoteStatusBadge({
    super.key,
    required this.quote,
    this.showExpired = true,
  });

  @override
  Widget build(BuildContext context) {
    final service = QuoteService();
    final isExpired = showExpired && service.isQuoteExpired(quote);
    
    // Show expired status if applicable
    if (isExpired) {
      return _buildBadge(
        'EXPIRED',
        Colors.orange,
        Colors.orange.shade100,
      );
    }
    
    // Show regular status
    final status = quote.status.toUpperCase();
    final colors = _getStatusColors(quote.status);
    
    return _buildBadge(
      status,
      colors.foreground,
      colors.background,
    );
  }

  Widget _buildBadge(String text, Color foreground, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withAlpha(25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  StatusColors _getStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return StatusColors(
          foreground: Colors.grey.shade700,
          background: Colors.grey.shade100,
        );
      case 'sent':
        return StatusColors(
          foreground: Colors.blue.shade700,
          background: Colors.blue.shade50,
        );
      case 'accepted':
        return StatusColors(
          foreground: Colors.green.shade700,
          background: Colors.green.shade50,
        );
      case 'declined':
        return StatusColors(
          foreground: Colors.red.shade700,
          background: Colors.red.shade50,
        );
      default:
        return StatusColors(
          foreground: Colors.grey.shade700,
          background: Colors.grey.shade100,
        );
    }
  }
}

/// Small variant of status badge for compact spaces
class QuoteStatusBadgeSmall extends QuoteStatusBadge {
  const QuoteStatusBadgeSmall({
    super.key,
    required super.quote,
    super.showExpired,
  });

  @override
  Widget _buildBadge(String text, Color foreground, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withAlpha(25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Helper class for status colors
class StatusColors {
  final Color foreground;
  final Color background;

  StatusColors({
    required this.foreground,
    required this.background,
  });
}