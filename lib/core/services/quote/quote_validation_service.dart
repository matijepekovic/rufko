import '../../../data/models/business/product.dart';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/business/quote.dart';

/// Result object for quote validation operations
class QuoteValidationResult {
  final bool isValid;
  final String? errorMessage;

  const QuoteValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory QuoteValidationResult.success() {
    return const QuoteValidationResult(isValid: true);
  }

  factory QuoteValidationResult.error(String message) {
    return QuoteValidationResult(isValid: false, errorMessage: message);
  }
}

/// Service layer for quote validation operations
/// Contains pure business logic without UI dependencies
class QuoteValidationService {
  /// Validate quote data before generation
  /// Business logic copied exactly from QuoteFormController.generateQuote() validation section
  static QuoteValidationResult validateQuoteData({
    required String quoteType,
    Product? mainProduct,
    required List<QuoteLevel> quoteLevels,
    required List<QuoteItem> addedProducts,
    required bool isEditMode,
  }) {
    // Validation based on quote type
    if (quoteType == 'multi-level') {
      if (mainProduct == null || quoteLevels.isEmpty) {
        return QuoteValidationResult.error('Please select a main product for multi-level quotes');
      }
    } else {
      // Single-tier: just need at least one product in added products
      if (addedProducts.isEmpty) {
        return QuoteValidationResult.error('Please add at least one product to the quote');
      }
    }

    return QuoteValidationResult.success();
  }
}