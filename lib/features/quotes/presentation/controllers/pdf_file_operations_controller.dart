import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/media/project_media.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/ui/pdf_form_field.dart';
import 'pdf_document_controller.dart';

class PdfFileOperationsController {
  PdfFileOperationsController(this.context);

  final BuildContext context;

  Future<void> savePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
  }) async {
    debugPrint('💾 Starting PDF save with ${editedValues.length} edits');
    final docController = PdfDocumentController(currentPdfPath);
    File pdfToSave;
    if (editedValues.isNotEmpty && formFields.isNotEmpty) {
      debugPrint(
          '🔧 Applying edits using template-style field mapping approach...');
      pdfToSave =
          await docController.applyEditsUsingTemplateApproach(editedValues);
    } else {
      debugPrint('📄 Using original file (no edits to apply)');
      pdfToSave = File(currentPdfPath);
    }

    if (!await pdfToSave.exists()) {
      throw Exception('PDF file not found: ${pdfToSave.path}');
    }

    final saveDir = await getApplicationDocumentsDirectory();
    String finalFileName = suggestedFileName;
    if (editedValues.isNotEmpty) {
      final baseName = finalFileName.replaceAll('.pdf', '');
      finalFileName = '${baseName}_edited.pdf';
    }
    int counter = 1;
    File targetFile = File('${saveDir.path}/$finalFileName');
    while (await targetFile.exists()) {
      final baseName = finalFileName.replaceAll('.pdf', '');
      finalFileName = '${baseName}_$counter.pdf';
      targetFile = File('${saveDir.path}/$finalFileName');
      counter++;
    }

    await pdfToSave.copy(targetFile.path);

    if (customer != null) {
      try {
        if (!context.mounted) return;
        final appState = context.read<AppStateProvider>();
        final fileSize = await targetFile.length();
        final projectMedia = ProjectMedia(
          customerId: customer.id,
          quoteId: quote?.id,
          filePath: targetFile.path,
          fileName: finalFileName,
          fileType: 'pdf',
          description: quote != null
              ? 'Quote PDF: ${quote.quoteNumber}${editedValues.isNotEmpty ? ' (edited)' : ''}'
              : 'Generated PDF${editedValues.isNotEmpty ? ' (edited)' : ''}',
          tags: [
            'quote',
            'pdf',
            if (editedValues.isNotEmpty) 'edited',
            if (templateId != null) 'template',
          ],
          category: 'document',
          fileSizeBytes: fileSize,
        );
        await appState.addProjectMedia(projectMedia);
        debugPrint('✅ PDF added to customer media: ${customer.name}');
      } catch (e) {
        debugPrint('⚠️ Failed to add PDF to customer media: $e');
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ PDF saved${customer != null ? ' and added to customer media' : ''}!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () => OpenFilex.open(targetFile.path),
        ),
      ),
    );
    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> sharePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    Future<void> Function(
            {required File file, required String fileName, Customer? customer})?
        shareFile,
  }) async {
    try {
      File fileToShare;
      final docController = PdfDocumentController(currentPdfPath);
      if (editedValues.isNotEmpty && formFields.isNotEmpty) {
        fileToShare = await docController.applyFormFieldEdits(editedValues);
      } else {
        fileToShare = File(currentPdfPath);
      }
      if (!await fileToShare.exists()) {
        throw Exception('PDF file not found');
      }
      if (shareFile != null) {
        await shareFile(
            file: fileToShare, fileName: suggestedFileName, customer: customer);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error preparing PDF for sharing: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to prepare PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
