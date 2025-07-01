import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../data/models/business/customer.dart';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/media/project_media.dart';
import '../../../data/models/ui/pdf_form_field.dart';
import '../../../data/providers/state/app_state_provider.dart';
import '../../../features/quotes/presentation/controllers/pdf_document_controller.dart';

/// Result object for PDF file operations
class PdfFileOperationResult {
  final bool isSuccess;
  final String? message;
  final File? file;
  final String? filePath;

  const PdfFileOperationResult._({
    required this.isSuccess,
    this.message,
    this.file,
    this.filePath,
  });

  factory PdfFileOperationResult.success({
    String? message,
    File? file,
    String? filePath,
  }) {
    return PdfFileOperationResult._(
      isSuccess: true,
      message: message,
      file: file,
      filePath: filePath,
    );
  }

  factory PdfFileOperationResult.error(String message) {
    return PdfFileOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Service layer for PDF file operations
/// Contains pure business logic without UI dependencies
class PdfFileService {
  /// Save PDF with optional edits
  Future<PdfFileOperationResult> savePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
    required AppStateProvider appState,
  }) async {
    try {
      // Apply edits if any
      final docController = PdfDocumentController(currentPdfPath);
      File pdfToSave;
      
      if (editedValues.isNotEmpty && formFields.isNotEmpty) {
        pdfToSave = await docController.applyEditsUsingTemplateApproach(editedValues);
      } else {
        pdfToSave = File(currentPdfPath);
      }

      if (!await pdfToSave.exists()) {
        return PdfFileOperationResult.error('PDF file not found: ${pdfToSave.path}');
      }

      // Generate unique filename
      final saveDir = await getApplicationDocumentsDirectory();
      String finalFileName = suggestedFileName;
      
      if (editedValues.isNotEmpty) {
        final baseName = finalFileName.replaceAll('.pdf', '');
        finalFileName = '${baseName}_edited.pdf';
      }

      final targetFile = await _generateUniqueFilePath(saveDir, finalFileName);
      await pdfToSave.copy(targetFile.path);

      // Add to customer media if customer provided
      if (customer != null) {
        final addMediaResult = await _addToCustomerMedia(
          targetFile: targetFile,
          finalFileName: path.basename(targetFile.path),
          customer: customer,
          quote: quote,
          templateId: templateId,
          editedValues: editedValues,
          appState: appState,
        );

        if (!addMediaResult.isSuccess) {
          // Log but don't fail the save operation
          debugPrint('Warning: Failed to add PDF to customer media: ${addMediaResult.errorMessage}');
        }
      }

      final successMessage = customer != null 
          ? 'PDF saved and added to customer media!'
          : 'PDF saved successfully!';

      return PdfFileOperationResult.success(
        message: successMessage,
        file: targetFile,
        filePath: targetFile.path,
      );
    } catch (e) {
      return PdfFileOperationResult.error('Failed to save PDF: $e');
    }
  }

  /// Prepare PDF for sharing
  Future<PdfFileOperationResult> preparePdfForSharing({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
  }) async {
    try {
      final docController = PdfDocumentController(currentPdfPath);
      File fileToShare;
      
      if (editedValues.isNotEmpty && formFields.isNotEmpty) {
        fileToShare = await docController.applyFormFieldEdits(editedValues);
      } else {
        fileToShare = File(currentPdfPath);
      }

      if (!await fileToShare.exists()) {
        return PdfFileOperationResult.error('PDF file not found');
      }

      return PdfFileOperationResult.success(
        message: 'PDF prepared for sharing',
        file: fileToShare,
        filePath: fileToShare.path,
      );
    } catch (e) {
      return PdfFileOperationResult.error('Failed to prepare PDF for sharing: $e');
    }
  }

  /// Generate unique file path to avoid conflicts
  Future<File> _generateUniqueFilePath(Directory saveDir, String fileName) async {
    int counter = 1;
    File targetFile = File('${saveDir.path}/$fileName');
    
    while (await targetFile.exists()) {
      final baseName = fileName.replaceAll('.pdf', '');
      final newFileName = '${baseName}_$counter.pdf';
      targetFile = File('${saveDir.path}/$newFileName');
      counter++;
    }
    
    return targetFile;
  }

  /// Add PDF to customer media
  Future<PdfFileOperationResult> _addToCustomerMedia({
    required File targetFile,
    required String finalFileName,
    required Customer customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
    required Map<String, String> editedValues,
    required AppStateProvider appState,
  }) async {
    try {
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
      
      return PdfFileOperationResult.success(
        message: 'PDF added to customer media: ${customer.name}',
      );
    } catch (e) {
      return PdfFileOperationResult.error('Failed to add PDF to customer media: $e');
    }
  }

  /// Open file with system default application
  Future<PdfFileOperationResult> openFile(String filePath) async {
    try {
      // This would use OpenFilex.open(filePath) in the UI layer
      return PdfFileOperationResult.success(
        message: 'File opening initiated',
        filePath: filePath,
      );
    } catch (e) {
      return PdfFileOperationResult.error('Failed to open file: $e');
    }
  }
}