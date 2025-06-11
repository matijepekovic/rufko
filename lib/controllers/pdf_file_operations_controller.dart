import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/project_media.dart';
import '../models/simplified_quote.dart';
import '../providers/app_state_provider.dart';
import '../models/pdf_form_field.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to prepare PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
