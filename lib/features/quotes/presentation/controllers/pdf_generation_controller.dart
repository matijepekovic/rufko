import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/pdf_preview_screen.dart';
import '../widgets/dialogs/template_selection_dialog.dart';

class PDFGenerationController {
  PDFGenerationController({
    required this.context,
    required this.quote,
    required this.customer,
    this.selectedLevelId,
  });

  final BuildContext context;
  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  String? selectedLevelId;

  Future<void> previewPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final appState = context.read<AppStateProvider>();
      final existingPdf = appState.projectMedia
          .where((media) =>
              media.customerId == customer.id &&
              media.quoteId == quote.id &&
              media.isPdf &&
              media.tags.contains('quote'))
          .toList();
      if (existingPdf.isEmpty) {
        messenger.showSnackBar(const SnackBar(
          content: Text('No saved PDF found. Use "Generate PDF" to create one first.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }
      final latestPdf = existingPdf.last;
      final file = File(latestPdf.filePath);
      if (!await file.exists()) {
        messenger.showSnackBar(SnackBar(
          content: Text('PDF file not found: ${latestPdf.fileName}'),
          backgroundColor: Colors.red,
        ));
        return;
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: latestPdf.filePath,
            suggestedFileName: latestPdf.fileName,
            quote: quote,
            customer: customer,
            title: 'Saved PDF Preview',
            isPreview: true,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error opening PDF: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> generatePdf() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final appState = context.read<AppStateProvider>();
      final availableTemplates =
          appState.activePDFTemplates.where((t) => t.templateType == 'quote').toList();
      final selectedOption = await showTemplateSelectionDialog(availableTemplates);
      if (selectedOption == 'cancelled') return;
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );
      String pdfPath;
      String? templateId;
      Map<String, String>? customData;
      if (selectedOption != null && selectedOption != 'standard') {
        templateId = selectedOption;
        customData = {
          'generated_from': 'template',
          'template_id': selectedOption,
          'generation_date': DateTime.now().toIso8601String(),
        };
        pdfPath = await appState.generatePDFFromTemplate(
          templateId: selectedOption,
          quote: quote,
          customer: customer,
          selectedLevelId: selectedLevelId,
          customData: customData,
        );
      } else {
        customData = {
          'generated_from': 'standard',
          'generation_date': DateTime.now().toIso8601String(),
        };
        pdfPath = await appState.generateSimplifiedQuotePdf(
          quote,
          customer,
          selectedLevelId: selectedLevelId,
        );
      }
      navigator.pop();
      await navigator.push<bool>(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: pdfPath,
            suggestedFileName: generateSuggestedFileName(),
            quote: quote,
            customer: customer,
            templateId: templateId,
            selectedLevelId: selectedLevelId,
            originalCustomData: customData,
          ),
        ),
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Error generating PDF: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  String generateSuggestedFileName() {
    final quoteNumber = quote.quoteNumber.replaceAll(RegExp(r'[^\w\s-]'), '');
    final customerName = customer.name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'Quote_${quoteNumber}_${customerName}_$dateStr.pdf';
  }

  Future<String?> showTemplateSelectionDialog(List<PDFTemplate> templates) async {
    return showDialog<String>(
      context: context,
      builder: (_) => TemplateSelectionDialog(
        templates: templates,
        onPreviewTemplate: previewTemplateInDialog,
      ),
    );
  }

  void previewTemplateInDialog(PDFTemplate template) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      navigator.pop();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating preview...'),
            ],
          ),
        ),
      );
      final previewPath = await context.read<AppStateProvider>().generatePDFFromTemplate(
            templateId: template.id,
            quote: quote,
            customer: customer,
            selectedLevelId: selectedLevelId,
            customData: {'preview': 'true', 'watermark': 'PREVIEW'},
          );
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Preview generated: ${previewPath.split('/').last}'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => OpenFilex.open(previewPath),
        ),
      ));
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        final templates = context.read<AppStateProvider>().activePDFTemplates
            .where((t) => t.templateType == 'quote')
            .toList();
        showTemplateSelectionDialog(templates);
      }
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Error generating preview: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
