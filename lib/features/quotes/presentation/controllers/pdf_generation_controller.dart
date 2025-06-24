import 'package:flutter/material.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import '../widgets/pdf_generation/pdf_generation_handler.dart';
import 'pdf_generation_ui_controller.dart';

/// Refactored PDFGenerationController using clean architecture
/// Now acts as a coordinator between UI and business logic
class PDFGenerationController {
  PDFGenerationController({
    required this.quote,
    required this.customer,
    this.selectedLevelId,
    @Deprecated('BuildContext dependency removed') BuildContext? context,
  }) : _uiController = PDFGenerationUIController(
          quote: quote,
          customer: customer,
          selectedLevelId: selectedLevelId,
        );

  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  String? selectedLevelId;
  final PDFGenerationUIController _uiController;

  /// Get the UI controller for use in widgets
  PDFGenerationUIController get uiController => _uiController;

  /// Create a handler widget that manages UI concerns
  Widget createPDFHandler({
    required Widget child,
  }) {
    return PDFGenerationHandler(
      controller: _uiController,
      child: child,
    );
  }

  /// Legacy methods for backward compatibility - simplified implementation
  Future<void> previewPdf() async {
    // Legacy implementation - in new architecture this would be handled by PDFGenerationHandler
    debugPrint('previewPdf() called - use PDFGenerationHandler.previewExistingPdf() in new architecture');
  }

  Future<void> generatePdf() async {
    // Legacy implementation - in new architecture this would be handled by PDFGenerationHandler
    debugPrint('generatePdf() called - use PDFGenerationHandler.generateAndPreviewPdf() in new architecture');
  }

  /// Legacy method - filename generation moved to service layer
  String generateSuggestedFileName() {
    // This is now handled by the service layer
    return 'quote_${quote.quoteNumber}_${customer.name}.pdf';
  }

  /// Clean up resources
  void dispose() {
    _uiController.dispose();
  }
}