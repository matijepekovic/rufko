import '../../../../../data/models/business/simplified_quote.dart';

/// Controller that exposes quote totals for display widgets.
class QuoteTotalsController {
  QuoteTotalsController({
    required this.quote,
    required this.selectedLevelId,
  });

  final SimplifiedMultiLevelQuote quote;
  String selectedLevelId;

  double get levelSubtotal {
    final level = quote.levels.firstWhere(
      (l) => l.id == selectedLevelId,
      orElse: () => QuoteLevel(id: '', name: '', levelNumber: 0, basePrice: 0),
    );
    return level.subtotal;
  }

  double get addonSubtotal =>
      quote.addons.fold(0.0, (sum, a) => sum + a.totalPrice);

  double get combinedSubtotal => levelSubtotal + addonSubtotal;

  double get totalDiscount =>
      quote.getDiscountSummary(selectedLevelId)['totalDiscount'] as double;

  double get subtotalAfterDiscount => combinedSubtotal - totalDiscount;

  double get taxRate => quote.taxRate;

  double get taxAmount => subtotalAfterDiscount * (taxRate / 100);

  double get finalTotal => subtotalAfterDiscount + taxAmount;
}
