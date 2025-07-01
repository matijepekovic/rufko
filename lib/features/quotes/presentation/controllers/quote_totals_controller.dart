import '../../../../../data/models/business/simplified_quote.dart';

/// Controller that exposes quote totals for display widgets.
class QuoteTotalsController {
  QuoteTotalsController({
    required this.quote,
    required this.selectedLevelId,
  });

  final SimplifiedMultiLevelQuote quote;
  String selectedLevelId;

  // Use quote's authoritative calculations - don't duplicate logic
  
  double get combinedSubtotal => quote.getDiscountedSubtotalForLevel(selectedLevelId);

  double get taxRate => quote.taxRate;

  double get taxAmount => quote.getTaxAmountForLevel(selectedLevelId);

  double get finalTotal => quote.getDisplayTotalForLevel(selectedLevelId);
}
