import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/ui/pdf_form_field.dart';
import 'pdf_file_operations_ui_controller.dart';
import '../widgets/pdf_file_operations/pdf_file_operations_handler.dart';

/// Refactored PdfFileOperationsController using clean architecture
/// Now acts as a coordinator between UI and business logic
class PdfFileOperationsController {
  PdfFileOperationsController(BuildContext context)
      : _uiController = PdfFileOperationsUIController.fromContext(context);

  final PdfFileOperationsUIController _uiController;

  /// Get the UI controller for use in widgets
  PdfFileOperationsUIController get uiController => _uiController;

  /// Create a handler widget that manages UI concerns
  Widget createPdfFileOperationsHandler({
    Key? key,
    required Widget child,
  }) {
    return PdfFileOperationsHandler(
      key: key,
      controller: _uiController,
      child: child,
    );
  }

  /// Legacy methods for backward compatibility - now delegate to handler
  @Deprecated('Use PdfFileOperationsHandler.savePdf() in new architecture')
  Future<void> savePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
  }) async {
    debugPrint('savePdf() called - use PdfFileOperationsHandler.savePdf() in new architecture');
  }

  @Deprecated('Use PdfFileOperationsHandler.sharePdf() in new architecture')
  Future<void> sharePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    Future<void> Function({
      required File file,
      required String fileName,
      Customer? customer,
    })? shareFile,
  }) async {
    debugPrint('sharePdf() called - use PdfFileOperationsHandler.sharePdf() in new architecture');
  }

  /// Clean up resources
  void dispose() {
    _uiController.dispose();
  }
}
