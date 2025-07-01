import '../../../data/models/business/customer.dart';
import '../../../data/models/business/product.dart';
import '../../../data/models/business/roof_scope_data.dart';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/business/quote_extras.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Result object for quote generation operations
class QuoteGenerationResult {
  final bool isSuccess;
  final SimplifiedMultiLevelQuote? quote;
  final String? errorMessage;

  const QuoteGenerationResult({
    required this.isSuccess,
    this.quote,
    this.errorMessage,
  });

  factory QuoteGenerationResult.success(SimplifiedMultiLevelQuote quote) {
    return QuoteGenerationResult(isSuccess: true, quote: quote);
  }

  factory QuoteGenerationResult.error(String message) {
    return QuoteGenerationResult(isSuccess: false, errorMessage: message);
  }
}

/// Service layer for quote generation and persistence operations
/// Contains pure business logic without UI dependencies
class QuoteGenerationService {
  /// Generate new quote
  /// Business logic copied exactly from QuoteFormController.generateQuote() new quote section
  static Future<QuoteGenerationResult> generateNewQuote({
    required AppStateProvider appState,
    required Customer customer,
    RoofScopeData? roofScopeData,
    required List<QuoteLevel> quoteLevels,
    required double taxRate,
    required String quoteType,
    Product? mainProduct,
    required List<PermitItem> permits,
    required bool noPermitsRequired,
    required List<CustomLineItem> customLineItems,
    List<QuoteDiscount>? discounts,
  }) async {
    try {
      final newQuote = SimplifiedMultiLevelQuote(
        customerId: customer.id,
        roofScopeDataId: roofScopeData?.id,
        customer: customer, // Pass customer for quote number generation
        levels: quoteLevels.map((level) {
          level.calculateSubtotal();
          return level;
        }).toList(),
        addons: [],
        taxRate: taxRate,
        // Only set main product for multi-level quotes
        baseProductId: quoteType == 'multi-level' ? mainProduct?.id : null,
        baseProductName: quoteType == 'multi-level' ? mainProduct?.name : null,
        baseProductUnit: quoteType == 'multi-level' ? mainProduct?.unit : null,
        permits: List.from(permits),
        noPermitsRequired: noPermitsRequired,
        customLineItems: List.from(customLineItems),
        discounts: discounts != null ? List.from(discounts) : [],
      );

      await appState.addSimplifiedQuote(newQuote);
      return QuoteGenerationResult.success(newQuote);
    } catch (e) {
      return QuoteGenerationResult.error('Error generating ${quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e');
    }
  }

  /// Update existing quote
  /// Business logic copied exactly from QuoteFormController.generateQuote() edit mode section
  static Future<QuoteGenerationResult> updateExistingQuote({
    required AppStateProvider appState,
    required SimplifiedMultiLevelQuote existingQuote,
    RoofScopeData? roofScopeData,
    required List<QuoteLevel> quoteLevels,
    required double taxRate,
    required String quoteType,
    Product? mainProduct,
    required List<PermitItem> permits,
    required bool noPermitsRequired,
    required List<CustomLineItem> customLineItems,
    List<QuoteDiscount>? discounts,
  }) async {
    try {
      final updatedQuote = existingQuote;
      
      // Check if PDF needs to be invalidated (create snapshot first)
      final originalSnapshot = SimplifiedMultiLevelQuote(
        customerId: existingQuote.customerId,
        levels: List.from(existingQuote.levels),
        taxRate: existingQuote.taxRate,
        discount: existingQuote.discount,
        permits: List.from(existingQuote.permits),
        customLineItems: List.from(existingQuote.customLineItems),
        discounts: List.from(existingQuote.discounts),
      );
      
      // Update the quote fields
      updatedQuote.levels = quoteLevels.map((level) {
        level.calculateSubtotal();
        return level;
      }).toList();
      updatedQuote.taxRate = taxRate;
      updatedQuote.permits = List.from(permits);
      updatedQuote.noPermitsRequired = noPermitsRequired;
      updatedQuote.customLineItems = List.from(customLineItems);
      updatedQuote.discounts = discounts != null ? List.from(discounts) : [];
      
      final hasChanges = _hasSignificantChanges(originalSnapshot, updatedQuote);
      if (hasChanges && updatedQuote.pdfPath != null) {
        // Clear PDF state when quote is edited
        updatedQuote.pdfPath = null;
        updatedQuote.pdfTemplateId = null;
        updatedQuote.pdfGeneratedAt = null;
        
        // Set status back to draft if it was sent or beyond
        if (updatedQuote.status != 'draft' && updatedQuote.status != 'pdf_generated') {
          updatedQuote.previousStatus = updatedQuote.status;
          updatedQuote.status = 'draft';
        }
      }
      // Only set main product for multi-level quotes
      if (quoteType == 'multi-level' && mainProduct != null) {
        updatedQuote.baseProductId = mainProduct.id;
        updatedQuote.baseProductName = mainProduct.name;
        updatedQuote.baseProductUnit = mainProduct.unit;
      } else {
        updatedQuote.baseProductId = null;
        updatedQuote.baseProductName = null;
        updatedQuote.baseProductUnit = null;
      }
      updatedQuote.roofScopeDataId = roofScopeData?.id;
      updatedQuote.permits = List.from(permits);
      updatedQuote.noPermitsRequired = noPermitsRequired;
      updatedQuote.customLineItems = List.from(customLineItems);
      updatedQuote.discounts = discounts != null ? List.from(discounts) : [];
      updatedQuote.updatedAt = DateTime.now();

      await appState.updateSimplifiedQuote(updatedQuote);
      return QuoteGenerationResult.success(updatedQuote);
    } catch (e) {
      return QuoteGenerationResult.error('Error updating ${quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e');
    }
  }

  /// Check if there are significant changes that would require PDF regeneration
  static bool _hasSignificantChanges(SimplifiedMultiLevelQuote original, SimplifiedMultiLevelQuote updated) {
    // Check basic fields that affect PDF content
    if (original.taxRate != updated.taxRate) return true;
    if (original.discount != updated.discount) return true;
    if (original.levels.length != updated.levels.length) return true;
    if (original.permits.length != updated.permits.length) return true;
    if (original.customLineItems.length != updated.customLineItems.length) return true;
    if (original.discounts.length != updated.discounts.length) return true;
    
    // Check level details
    for (int i = 0; i < original.levels.length; i++) {
      if (i >= updated.levels.length) return true;
      final origLevel = original.levels[i];
      final updLevel = updated.levels[i];
      if (origLevel.basePrice != updLevel.basePrice ||
          origLevel.baseQuantity != updLevel.baseQuantity ||
          origLevel.name != updLevel.name) {
        return true;
      }
    }
    
    return false;
  }
}