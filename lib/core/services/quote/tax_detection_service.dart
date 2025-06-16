import '../../../data/models/business/customer.dart';
import '../../../data/providers/state/app_state_provider.dart';
import '../../../app/constants/quote_form_constants.dart';

/// Result object for tax detection operations
class TaxDetectionResult {
  final double? detectedRate;
  final String? source;
  final bool usesFallback;
  final bool requiresManualEntry;

  const TaxDetectionResult({
    this.detectedRate,
    this.source,
    this.usesFallback = false,
    this.requiresManualEntry = false,
  });
}

/// Service layer for tax detection operations
/// Contains pure business logic without UI dependencies
class TaxDetectionService {
  /// Auto-detect tax rate for customer
  /// Business logic copied exactly from QuoteFormController.autoDetectTaxRate()
  static TaxDetectionResult autoDetectTaxRate({
    required Customer customer,
    required AppStateProvider appState,
  }) {
    final c = customer;
    final detectedRate = appState.detectTaxRate(
      city: c.city,
      stateAbbreviation: c.stateAbbreviation,
      zipCode: c.zipCode,
    );

    if (detectedRate != null && detectedRate > 0) {
      String source = '';
      if (c.zipCode != null && c.zipCode!.isNotEmpty) {
        source = 'ZIP ${c.zipCode}';
      } else if (c.stateAbbreviation != null) {
        source = 'state ${c.stateAbbreviation}';
      }
      
      return TaxDetectionResult(
        detectedRate: detectedRate,
        source: source,
      );
    } else {
      final fallbackRate =
          appState.appSettings?.taxRate ?? QuoteFormConstants.defaultTaxRate;
      if (fallbackRate > 0) {
        return TaxDetectionResult(
          detectedRate: fallbackRate,
          usesFallback: true,
        );
      } else {
        return const TaxDetectionResult(
          requiresManualEntry: true,
        );
      }
    }
  }
}