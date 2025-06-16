import 'package:flutter/material.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import 'quote_detail_ui_controller.dart';
import '../widgets/quote_detail/quote_detail_handler.dart';
import 'pdf_generation_controller.dart';

/// Refactored QuoteDetailController using clean architecture
/// Now acts as a coordinator between UI and business logic
class QuoteDetailController extends ChangeNotifier {
  QuoteDetailController({
    required this.quote,
    required this.customer,
    required BuildContext context,
  }) : _uiController = QuoteDetailUIController.fromContext(
          context: context,
          quote: quote,
          customer: customer,
        );

  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  final QuoteDetailUIController _uiController;

  /// Get the UI controller for use in widgets
  QuoteDetailUIController get uiController => _uiController;

  /// Create a handler widget that manages UI concerns
  Widget createQuoteDetailHandler({
    required Widget child,
  }) {
    return QuoteDetailHandler(
      controller: _uiController,
      child: child,
    );
  }

  // Legacy getters for backward compatibility
  String? get selectedLevelId => _uiController.selectedLevelId;
  Color getStatusColor() => _uiController.getStatusColor();
  String getStatusButtonText() => _uiController.getStatusButtonText();

  /// Legacy methods for backward compatibility - now delegate to handler
  void selectLevel(String levelId) {
    _uiController.selectLevel(levelId);
  }

  @Deprecated('Use QuoteDetailUIController.addDiscount() in new architecture')
  void addDiscount(BuildContext context, dynamic discount) {
    _uiController.addDiscount(discount);
  }

  @Deprecated('Use QuoteDetailUIController.removeDiscount() in new architecture')
  void removeDiscount(BuildContext context, String discountId) {
    _uiController.removeDiscount(discountId);
  }

  @Deprecated('Use QuoteDetailHandler.updateQuoteStatus() in new architecture')
  void updateQuoteStatus(BuildContext context) {
    print('updateQuoteStatus() called - use QuoteDetailHandler.updateQuoteStatus() in new architecture');
  }

  @Deprecated('Use QuoteDetailHandler.deleteQuote() in new architecture')
  void deleteQuote(BuildContext context) {
    print('deleteQuote() called - use QuoteDetailHandler.deleteQuote() in new architecture');
  }

  @Deprecated('Use QuoteDetailHandler.handleMenuAction() in new architecture')
  void handleMenuAction(BuildContext context, String action, PDFGenerationController pdfController) {
    print('handleMenuAction() called - use QuoteDetailHandler.handleMenuAction() in new architecture');
  }

  /// Clean up resources
  @override
  void dispose() {
    _uiController.dispose();
    super.dispose();
  }
}
