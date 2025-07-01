import 'dart:io';

import '../../../data/models/templates/pdf_template.dart';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/business/customer.dart';
import '../../../data/models/media/project_media.dart';
import '../../../data/providers/state/app_state_provider.dart';
import '../naming/naming_service.dart';

/// Service class for PDF generation operations
/// Separated from UI concerns for better testability and maintainability
class PDFGenerationService {
  const PDFGenerationService();

  /// Check for existing PDF files for a quote
  Future<PDFExistenceResult> checkExistingPdf({
    required Customer customer,
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      final existingPdf = appState.projectMedia
          .where((media) =>
              media.customerId == customer.id &&
              media.quoteId == quote.id &&
              media.isPdf &&
              media.tags.contains('quote'))
          .toList();

      if (existingPdf.isEmpty) {
        return const PDFExistenceResult.notFound();
      }

      final latestPdf = existingPdf.last;
      final file = File(latestPdf.filePath);
      final exists = await file.exists();

      if (!exists) {
        return PDFExistenceResult.fileNotFound(latestPdf.fileName);
      }

      return PDFExistenceResult.found(latestPdf);
    } catch (e) {
      return PDFExistenceResult.error('Error checking existing PDF: $e');
    }
  }

  /// Generate PDF from template or standard format
  Future<PDFGenerationResult> generatePdf({
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    required AppStateProvider appState,
    String? selectedTemplateId,
    String? selectedLevelId,
  }) async {
    try {
      String pdfPath;
      String? templateId;
      Map<String, String>? customData;

      if (selectedTemplateId != null && selectedTemplateId != 'standard') {
        templateId = selectedTemplateId;
        customData = {
          'generated_from': 'template',
          'template_id': selectedTemplateId,
          'generation_date': DateTime.now().toIso8601String(),
        };
        pdfPath = await appState.generatePDFFromTemplate(
          templateId: selectedTemplateId,
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

      final suggestedFileName = generateSuggestedFileName(quote, customer);

      return PDFGenerationResult.success(
        pdfPath: pdfPath,
        templateId: templateId,
        customData: customData,
        suggestedFileName: suggestedFileName,
      );
    } catch (e) {
      return PDFGenerationResult.error('Error generating PDF: $e');
    }
  }

  /// Generate PDF preview from template
  Future<PDFGenerationResult> generatePreview({
    required PDFTemplate template,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    required AppStateProvider appState,
    String? selectedLevelId,
  }) async {
    try {
      final previewPath = await appState.generatePDFFromTemplate(
        templateId: template.id,
        quote: quote,
        customer: customer,
        selectedLevelId: selectedLevelId,
        customData: {'preview': 'true', 'watermark': 'PREVIEW'},
      );

      return PDFGenerationResult.success(
        pdfPath: previewPath,
        templateId: template.id,
        suggestedFileName: previewPath.split('/').last,
        isPreview: true,
      );
    } catch (e) {
      return PDFGenerationResult.error('Error generating preview: $e');
    }
  }

  /// Get available PDF templates for quotes
  List<PDFTemplate> getAvailableTemplates(AppStateProvider appState) {
    return appState.activePDFTemplates
        .where((t) => t.templateType == 'quote')
        .toList();
  }

  /// Generate suggested filename for PDF using shared naming service
  String generateSuggestedFileName(
    SimplifiedMultiLevelQuote quote,
    Customer customer,
  ) {
    return NamingService.generatePdfFileName(customer);
  }
}

/// Result class for PDF existence check
class PDFExistenceResult {
  const PDFExistenceResult.found(this.projectMedia) 
    : status = PDFExistenceStatus.found,
      errorMessage = null;
  
  const PDFExistenceResult.notFound() 
    : status = PDFExistenceStatus.notFound,
      projectMedia = null,
      errorMessage = null;
  
  const PDFExistenceResult.fileNotFound(String fileName) 
    : status = PDFExistenceStatus.fileNotFound,
      projectMedia = null,
      errorMessage = 'PDF file not found: $fileName';
  
  const PDFExistenceResult.error(this.errorMessage) 
    : status = PDFExistenceStatus.error,
      projectMedia = null;

  final PDFExistenceStatus status;
  final ProjectMedia? projectMedia;
  final String? errorMessage;

  bool get isFound => status == PDFExistenceStatus.found;
  bool get isNotFound => status == PDFExistenceStatus.notFound;
  bool get isFileNotFound => status == PDFExistenceStatus.fileNotFound;
  bool get isError => status == PDFExistenceStatus.error;
}

enum PDFExistenceStatus { found, notFound, fileNotFound, error }

/// Result class for PDF generation operations
class PDFGenerationResult {
  const PDFGenerationResult.success({
    required this.pdfPath,
    required this.suggestedFileName,
    this.templateId,
    this.customData,
    this.isPreview = false,
  }) : isSuccess = true,
       errorMessage = null;
  
  const PDFGenerationResult.error(this.errorMessage) 
    : isSuccess = false,
      pdfPath = null,
      templateId = null,
      customData = null,
      suggestedFileName = null,
      isPreview = false;

  final bool isSuccess;
  final String? pdfPath;
  final String? templateId;
  final Map<String, String>? customData;
  final String? suggestedFileName;
  final String? errorMessage;
  final bool isPreview;

  bool get isError => !isSuccess;
}