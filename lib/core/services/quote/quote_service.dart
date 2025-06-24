import '../../../data/models/business/simplified_quote.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Result object for quote operations
class QuoteOperationResult {
  final bool isSuccess;
  final String? message;
  final SimplifiedMultiLevelQuote? quote;

  const QuoteOperationResult._({
    required this.isSuccess,
    this.message,
    this.quote,
  });

  factory QuoteOperationResult.success({
    String? message,
    SimplifiedMultiLevelQuote? quote,
  }) {
    return QuoteOperationResult._(
      isSuccess: true,
      message: message,
      quote: quote,
    );
  }

  factory QuoteOperationResult.error(String message) {
    return QuoteOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Service layer for quote operations
/// Contains pure business logic without UI dependencies
class QuoteService {
  /// Update quote status
  Future<QuoteOperationResult> updateQuoteStatus({
    required SimplifiedMultiLevelQuote quote,
    required String newStatus,
    required AppStateProvider appState,
  }) async {
    try {
      final validStatuses = ['draft', 'sent', 'accepted', 'declined'];
      
      if (!validStatuses.contains(newStatus.toLowerCase())) {
        return QuoteOperationResult.error('Invalid status: $newStatus');
      }

      quote.status = newStatus.toLowerCase();
      quote.updatedAt = DateTime.now();
      
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Quote status updated to ${newStatus.toUpperCase()}',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to update quote status: $e');
    }
  }

  /// Delete quote
  Future<QuoteOperationResult> deleteQuote({
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      await appState.deleteSimplifiedQuote(quote.id);
      
      return QuoteOperationResult.success(
        message: 'Quote ${quote.quoteNumber} deleted successfully',
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to delete quote: $e');
    }
  }

  /// Add discount to quote
  Future<QuoteOperationResult> addDiscount({
    required SimplifiedMultiLevelQuote quote,
    required dynamic discount, // QuoteDiscount type
    required AppStateProvider appState,
  }) async {
    try {
      quote.addDiscount(discount);
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Discount added successfully',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to add discount: $e');
    }
  }

  /// Remove discount from quote
  Future<QuoteOperationResult> removeDiscount({
    required SimplifiedMultiLevelQuote quote,
    required String discountId,
    required AppStateProvider appState,
  }) async {
    try {
      quote.removeDiscount(discountId);
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Discount removed successfully',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to remove discount: $e');
    }
  }

  /// Get available quote statuses
  List<String> getAvailableStatuses() {
    return ['draft', 'sent', 'accepted', 'declined'];
  }

  /// Get status display name
  String getStatusDisplayName(String status) {
    return status.toUpperCase();
  }

  /// Get next logical status
  String? getNextLogicalStatus(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'draft':
        return 'sent';
      case 'sent':
        return 'accepted';
      case 'accepted':
        return 'completed';
      default:
        return null;
    }
  }

  /// Validate quote for status update
  QuoteOperationResult validateQuoteForStatusUpdate(SimplifiedMultiLevelQuote quote) {
    if (quote.levels.isEmpty) {
      return QuoteOperationResult.error('Quote must have at least one level');
    }

    if (quote.quoteNumber.isEmpty) {
      return QuoteOperationResult.error('Quote must have a quote number');
    }

    return QuoteOperationResult.success(message: 'Quote is valid for status update');
  }
}