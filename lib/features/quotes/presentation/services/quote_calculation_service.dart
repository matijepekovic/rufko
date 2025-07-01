import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/quote_extras.dart';

/// Service for handling quote calculations and totals
/// Extracted from QuoteTotalsSection to separate business logic from UI
class QuoteCalculationService {
  
  /// Calculate totals for a single quote level
  static QuoteTotals calculateLevelTotals({
    required QuoteLevel level,
    required double taxRate,
    required List<PermitItem> permits,
    required List<CustomLineItem> customLineItems,
  }) {
    final levelSubtotal = level.subtotal;
    final permitsTotal = permits.fold(0.0, (sum, permit) => sum + permit.amount);
    
    final taxableCustomItems = customLineItems
        .where((item) => item.isTaxable)
        .fold(0.0, (sum, item) => sum + item.amount);
    
    final nonTaxableCustomItems = customLineItems
        .where((item) => !item.isTaxable)
        .fold(0.0, (sum, item) => sum + item.amount);

    final taxableSubtotal = levelSubtotal + permitsTotal + taxableCustomItems;
    final nonTaxableSubtotal = nonTaxableCustomItems;
    final totalSubtotal = taxableSubtotal + nonTaxableSubtotal;
    final taxAmount = taxableSubtotal * (taxRate / 100);
    final totalWithTax = totalSubtotal + taxAmount;

    return QuoteTotals(
      levelSubtotal: levelSubtotal,
      permitsTotal: permitsTotal,
      taxableCustomItems: taxableCustomItems,
      nonTaxableCustomItems: nonTaxableCustomItems,
      taxableSubtotal: taxableSubtotal,
      nonTaxableSubtotal: nonTaxableSubtotal,
      totalSubtotal: totalSubtotal,
      taxAmount: taxAmount,
      totalWithTax: totalWithTax,
    );
  }

  /// Calculate permits total
  static double calculatePermitsTotal(List<PermitItem> permits) {
    return permits.fold(0.0, (sum, permit) => sum + permit.amount);
  }

  /// Calculate custom items total
  static double calculateCustomItemsTotal(List<CustomLineItem> customLineItems) {
    return customLineItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculate taxable custom items total
  static double calculateTaxableCustomItemsTotal(List<CustomLineItem> customLineItems) {
    return customLineItems
        .where((item) => item.isTaxable)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculate non-taxable custom items total
  static double calculateNonTaxableCustomItemsTotal(List<CustomLineItem> customLineItems) {
    return customLineItems
        .where((item) => !item.isTaxable)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculate tax amount for a given taxable subtotal
  static double calculateTaxAmount(double taxableSubtotal, double taxRate) {
    return taxableSubtotal * (taxRate / 100);
  }

  /// Check if quote has permits
  static bool hasPermits(List<PermitItem> permits) {
    return permits.isNotEmpty;
  }

  /// Check if quote has custom line items
  static bool hasCustomLineItems(List<CustomLineItem> customLineItems) {
    return customLineItems.isNotEmpty;
  }

  /// Check if tax should be displayed (tax rate > 0)
  static bool shouldShowTax(double taxRate) {
    return taxRate > 0;
  }
}

/// Data class to hold calculated totals
class QuoteTotals {
  final double levelSubtotal;
  final double permitsTotal;
  final double taxableCustomItems;
  final double nonTaxableCustomItems;
  final double taxableSubtotal;
  final double nonTaxableSubtotal;
  final double totalSubtotal;
  final double taxAmount;
  final double totalWithTax;

  const QuoteTotals({
    required this.levelSubtotal,
    required this.permitsTotal,
    required this.taxableCustomItems,
    required this.nonTaxableCustomItems,
    required this.taxableSubtotal,
    required this.nonTaxableSubtotal,
    required this.totalSubtotal,
    required this.taxAmount,
    required this.totalWithTax,
  });

  @override
  String toString() {
    return 'QuoteTotals(totalWithTax: $totalWithTax, totalSubtotal: $totalSubtotal, taxAmount: $taxAmount)';
  }
}