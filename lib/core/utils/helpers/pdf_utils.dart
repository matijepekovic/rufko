// lib/utils/pdf_utils.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/quotes/presentation/screens/pdf_preview_screen.dart';
import '../../../data/models/business/customer.dart';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/providers/state/app_state_provider.dart';

class PDFUtils {
  /// Open any PDF using the enhanced PDF preview screen
  static Future<void> openPDF(
      BuildContext context, {
        required String pdfPath,
        required String fileName,
        Customer? customer,
        SimplifiedMultiLevelQuote? quote,
        String? templateId,
        String? selectedLevelId,
        Map<String, String>? originalCustomData,
        String? title,
        bool isPreview = true,
      }) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: pdfPath,
            suggestedFileName: fileName,
            customer: customer,
            quote: quote,
            templateId: templateId,
            selectedLevelId: selectedLevelId,
            originalCustomData: originalCustomData,
            title: title ?? fileName,
            isPreview: isPreview,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Quick open PDF with minimal parameters
  static Future<void> quickOpenPDF(
      BuildContext context, {
        required String pdfPath,
        required String fileName,
        String? title,
      }) async {
    await openPDF(
      context,
      pdfPath: pdfPath,
      fileName: fileName,
      title: title,
      isPreview: true,
    );
  }

  /// Open PDF with customer context
  static Future<void> openCustomerPDF(
      BuildContext context, {
        required String pdfPath,
        required String fileName,
        required Customer customer,
        String? quoteId,
        String? title,
      }) async {
    SimplifiedMultiLevelQuote? quote;

    if (quoteId != null) {
      final appState = context.read<AppStateProvider>();
      final quotes = appState.getSimplifiedQuotesForCustomer(customer.id);
      quote = quotes.firstWhere(
            (q) => q.id == quoteId,
        orElse: () => null as dynamic,
      );
    }

    await openPDF(
      context,
      pdfPath: pdfPath,
      fileName: fileName,
      customer: customer,
      quote: quote,
      title: title,
      isPreview: true,
    );
  }
}