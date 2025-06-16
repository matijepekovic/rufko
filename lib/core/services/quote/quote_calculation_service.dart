import '../../../data/models/business/product.dart';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/business/quote.dart';

/// Service layer for quote calculation operations
/// Contains pure business logic without UI dependencies
class QuoteCalculationService {
  /// Create quote levels based on quote type and main product
  /// Business logic copied exactly from QuoteFormController.createQuoteLevels()
  static List<QuoteLevel> createQuoteLevels({
    required String quoteType,
    Product? mainProduct,
    required double mainQuantity,
    required List<QuoteItem> addedProducts,
  }) {
    final List<QuoteLevel> quoteLevels = [];

    if (quoteType == 'multi-level') {
      // Multi-level requires a main product
      if (mainProduct == null) return quoteLevels;
      
      final mainLevels = mainProduct.availableMainLevels;
      for (var i = 0; i < mainLevels.length; i++) {
        final mainLevel = mainLevels[i];
        final quoteLevel = QuoteLevel(
          id: mainLevel.levelId,
          name: mainLevel.levelName,
          levelNumber: i + 1,
          basePrice: mainLevel.price,
          baseQuantity: mainQuantity,
          includedItems: List.from(addedProducts),
        );
        quoteLevel.calculateSubtotal();
        quoteLevels.add(quoteLevel);
      }
    } else {
      // Single-tier: create one level based on added products only
      final quoteLevel = QuoteLevel(
        id: 'single-tier-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Quote',
        levelNumber: 1,
        basePrice: 0.0, // No base price for single-tier
        baseQuantity: 1.0, // Always 1 for single-tier
        includedItems: List.from(addedProducts),
      );
      quoteLevel.calculateSubtotal();
      quoteLevels.add(quoteLevel);
    }
    
    return quoteLevels;
  }

  /// Update quote levels quantity and recalculate subtotals
  /// Business logic copied exactly from QuoteFormController.updateQuoteLevelsQuantity()
  static void updateQuoteLevelsQuantity({
    required List<QuoteLevel> quoteLevels,
    required double mainQuantity,
  }) {
    for (final level in quoteLevels) {
      level.baseQuantity = mainQuantity;
      level.calculateSubtotal();
    }
  }

  /// Add product to quote levels and recalculate
  /// Business logic copied exactly from QuoteFormController.addProduct()
  static List<QuoteLevel> addProductToLevels({
    required List<QuoteLevel> quoteLevels,
    required QuoteItem item,
    required String quoteType,
    Product? mainProduct,
    required double mainQuantity,
    required List<QuoteItem> addedProducts,
  }) {
    final updatedLevels = List<QuoteLevel>.from(quoteLevels);
    
    // For single-tier quotes, create the quote level if it doesn't exist
    if (quoteType == 'single-tier' && updatedLevels.isEmpty) {
      return createQuoteLevels(
        quoteType: quoteType,
        mainProduct: mainProduct,
        mainQuantity: mainQuantity,
        addedProducts: addedProducts,
      );
    } else {
      // Add to existing levels and recalculate
      for (final level in updatedLevels) {
        level.includedItems.add(item);
        level.calculateSubtotal();
      }
    }
    
    return updatedLevels;
  }

  /// Remove product from quote levels and recalculate
  /// Business logic copied exactly from QuoteFormController.removeProduct()
  static void removeProductFromLevels({
    required List<QuoteLevel> quoteLevels,
    required QuoteItem product,
  }) {
    for (final level in quoteLevels) {
      level.includedItems.remove(product);
      level.calculateSubtotal();
    }
  }
}