import '../../../data/models/business/customer.dart';
import '../../../data/models/business/product.dart';
import '../../../data/models/business/roof_scope_data.dart';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/business/quote.dart';
import '../../../data/models/business/quote_extras.dart';
import '../../../data/providers/state/app_state_provider.dart';
import '../../../app/constants/quote_form_constants.dart';

/// Result object for quote form operations
class QuoteFormOperationResult {
  final bool isSuccess;
  final String? message;
  final SimplifiedMultiLevelQuote? quote;
  final double? detectedTaxRate;
  final String? taxRateSource;

  const QuoteFormOperationResult._({
    required this.isSuccess,
    this.message,
    this.quote,
    this.detectedTaxRate,
    this.taxRateSource,
  });

  factory QuoteFormOperationResult.success({
    String? message,
    SimplifiedMultiLevelQuote? quote,
    double? detectedTaxRate,
    String? taxRateSource,
  }) {
    return QuoteFormOperationResult._(
      isSuccess: true,
      message: message,
      quote: quote,
      detectedTaxRate: detectedTaxRate,
      taxRateSource: taxRateSource,
    );
  }

  factory QuoteFormOperationResult.error(String message) {
    return QuoteFormOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Service layer for quote form operations
/// Contains pure business logic without UI dependencies
class QuoteFormService {
  /// Detect tax rate for customer location
  QuoteFormOperationResult detectTaxRate({
    required Customer customer,
    required AppStateProvider appState,
  }) {
    try {
      final detectedRate = appState.detectTaxRate(
        city: customer.city,
        stateAbbreviation: customer.stateAbbreviation,
        zipCode: customer.zipCode,
      );

      if (detectedRate != null && detectedRate > 0) {
        String source = '';
        if (customer.zipCode != null && customer.zipCode!.isNotEmpty) {
          source = 'ZIP ${customer.zipCode}';
        } else if (customer.stateAbbreviation != null) {
          source = 'state ${customer.stateAbbreviation}';
        }

        return QuoteFormOperationResult.success(
          message: 'Tax rate set to ${detectedRate.toStringAsFixed(2)}% from $source',
          detectedTaxRate: detectedRate,
          taxRateSource: source,
        );
      }

      // Try fallback rate
      final fallbackRate = appState.appSettings?.taxRate ?? QuoteFormConstants.defaultTaxRate;
      if (fallbackRate > 0) {
        return QuoteFormOperationResult.success(
          message: 'Using default tax rate: ${fallbackRate.toStringAsFixed(2)}%',
          detectedTaxRate: fallbackRate,
          taxRateSource: 'default',
        );
      }

      return QuoteFormOperationResult.error('Manual tax rate entry required');
    } catch (e) {
      return QuoteFormOperationResult.error('Failed to detect tax rate: $e');
    }
  }

  /// Create quote levels based on product and quote type
  List<QuoteLevel> createQuoteLevels({
    required Product mainProduct,
    required double mainQuantity,
    required String quoteType,
    required List<QuoteItem> addedProducts,
  }) {
    final quoteLevels = <QuoteLevel>[];

    if (quoteType == 'multi-level') {
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
      final quoteLevel = QuoteLevel(
        id: 'single-tier-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Quote',
        levelNumber: 1,
        basePrice: mainProduct.unitPrice,
        baseQuantity: mainQuantity,
        includedItems: List.from(addedProducts),
      );
      quoteLevel.calculateSubtotal();
      quoteLevels.add(quoteLevel);
    }

    return quoteLevels;
  }

  /// Create new quote
  Future<QuoteFormOperationResult> createQuote({
    required Customer customer,
    required Product mainProduct,
    required double mainQuantity,
    required List<QuoteLevel> quoteLevels,
    required double taxRate,
    required List<PermitItem> permits,
    required bool noPermitsRequired,
    required List<CustomLineItem> customLineItems,
    required String quoteType,
    RoofScopeData? roofScopeData,
    required AppStateProvider appState,
  }) async {
    try {
      // Calculate final levels
      final finalLevels = quoteLevels.map((level) {
        level.calculateSubtotal();
        return level;
      }).toList();

      final newQuote = SimplifiedMultiLevelQuote(
        customerId: customer.id,
        roofScopeDataId: roofScopeData?.id,
        levels: finalLevels,
        addons: [],
        taxRate: taxRate,
        baseProductId: mainProduct.id,
        baseProductName: mainProduct.name,
        baseProductUnit: mainProduct.unit,
        permits: List.from(permits),
        noPermitsRequired: noPermitsRequired,
        customLineItems: List.from(customLineItems),
      );

      await appState.addSimplifiedQuote(newQuote);

      return QuoteFormOperationResult.success(
        message: '${quoteType == 'single-tier' ? 'Single' : 'Tiered'} quote ${newQuote.quoteNumber} generated with ${taxRate.toStringAsFixed(2)}% tax!',
        quote: newQuote,
      );
    } catch (e) {
      return QuoteFormOperationResult.error('Error generating ${quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e');
    }
  }

  /// Update existing quote
  Future<QuoteFormOperationResult> updateQuote({
    required SimplifiedMultiLevelQuote existingQuote,
    required Product mainProduct,
    required List<QuoteLevel> quoteLevels,
    required double taxRate,
    required List<PermitItem> permits,
    required bool noPermitsRequired,
    required List<CustomLineItem> customLineItems,
    required String quoteType,
    RoofScopeData? roofScopeData,
    required AppStateProvider appState,
  }) async {
    try {
      // Calculate final levels
      final finalLevels = quoteLevels.map((level) {
        level.calculateSubtotal();
        return level;
      }).toList();

      // Update existing quote
      existingQuote.levels = finalLevels;
      existingQuote.taxRate = taxRate;
      existingQuote.baseProductId = mainProduct.id;
      existingQuote.baseProductName = mainProduct.name;
      existingQuote.baseProductUnit = mainProduct.unit;
      existingQuote.roofScopeDataId = roofScopeData?.id;
      existingQuote.permits = List.from(permits);
      existingQuote.noPermitsRequired = noPermitsRequired;
      existingQuote.customLineItems = List.from(customLineItems);
      existingQuote.updatedAt = DateTime.now();

      await appState.updateSimplifiedQuote(existingQuote);

      return QuoteFormOperationResult.success(
        message: '${quoteType == 'single-tier' ? 'Single' : 'Tiered'} quote ${existingQuote.quoteNumber} updated with ${taxRate.toStringAsFixed(2)}% tax!',
        quote: existingQuote,
      );
    } catch (e) {
      return QuoteFormOperationResult.error('Error updating ${quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e');
    }
  }

  /// Validate quote form data
  QuoteFormOperationResult validateQuoteForm({
    required Product? mainProduct,
    required List<QuoteLevel> quoteLevels,
    required bool isPermitsRequirementSatisfied,
  }) {
    if (mainProduct == null) {
      return QuoteFormOperationResult.error('Please select a main product first');
    }

    if (quoteLevels.isEmpty) {
      return QuoteFormOperationResult.error('No quote levels generated');
    }

    if (!isPermitsRequirementSatisfied) {
      return QuoteFormOperationResult.error('Please specify permit requirements');
    }

    return QuoteFormOperationResult.success(message: 'Quote form is valid');
  }

  /// Load existing quote data into form structure
  Map<String, dynamic> loadExistingQuoteData({
    required SimplifiedMultiLevelQuote existingQuote,
    required List<Product> availableProducts,
  }) {
    try {
      final quoteType = existingQuote.levels.length == 1 && existingQuote.levels.first.name == 'Quote'
          ? 'single-tier'
          : 'multi-level';

      Product? mainProduct;
      if (existingQuote.baseProductId != null) {
        try {
          mainProduct = availableProducts.firstWhere(
            (p) => p.id == existingQuote.baseProductId,
          );
        } catch (e) {
          // Product not found, will be null
        }
      }

      double mainQuantity = 1.0;
      List<QuoteItem> addedProducts = [];
      
      if (existingQuote.levels.isNotEmpty) {
        mainQuantity = existingQuote.levels.first.baseQuantity;
        addedProducts = List.from(existingQuote.levels.first.includedItems);
      }

      return {
        'taxRate': existingQuote.taxRate,
        'quoteType': quoteType,
        'mainProduct': mainProduct,
        'mainQuantity': mainQuantity,
        'quoteLevels': List.from(existingQuote.levels),
        'addedProducts': addedProducts,
        'permits': List.from(existingQuote.permits),
        'noPermitsRequired': existingQuote.noPermitsRequired,
        'customLineItems': List.from(existingQuote.customLineItems),
      };
    } catch (e) {
      throw Exception('Failed to load existing quote data: $e');
    }
  }
}