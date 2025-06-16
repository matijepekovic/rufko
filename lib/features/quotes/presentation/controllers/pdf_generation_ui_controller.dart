import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/pdf/pdf_generation_service.dart';
import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for PDF generation that follows clean architecture
/// Separates business logic from UI concerns using service layer and event emission
class PDFGenerationUIController extends ChangeNotifier {
  PDFGenerationUIController({
    required this.quote,
    required this.customer,
    this.selectedLevelId,
  }) : _pdfService = const PDFGenerationService();

  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  String? selectedLevelId;
  final PDFGenerationService _pdfService;

  // UI state
  bool _isGenerating = false;
  bool _isLoadingPreview = false;
  String? _lastError;
  String? _lastSuccess;
  List<PDFTemplate>? _availableTemplates;

  bool get isGenerating => _isGenerating;
  bool get isLoadingPreview => _isLoadingPreview;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  List<PDFTemplate>? get availableTemplates => _availableTemplates;

  /// Clear messages
  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();
  }

  /// Load available templates
  void loadAvailableTemplates(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    _availableTemplates = _pdfService.getAvailableTemplates(appState);
    notifyListeners();
  }

  /// Check for existing PDF and return path if found
  Future<String?> checkExistingPdf(BuildContext context) async {
    clearMessages();
    
    try {
      final appState = context.read<AppStateProvider>();
      final result = await _pdfService.checkExistingPdf(
        customer: customer,
        quote: quote,
        appState: appState,
      );

      if (result.isFound) {
        return result.projectMedia!.filePath;
      } else if (result.isNotFound) {
        _setError('No saved PDF found. Use "Generate PDF" to create one first.');
      } else if (result.isFileNotFound) {
        _setError(result.errorMessage!);
      } else if (result.isError) {
        _setError(result.errorMessage!);
      }
      
      return null;
    } catch (e) {
      _setError('Error checking existing PDF: $e');
      return null;
    }
  }

  /// Generate PDF with optional template selection
  Future<PDFGenerationData?> generatePdf({
    required BuildContext context,
    String? selectedTemplateId,
  }) async {
    _setGenerating(true);
    clearMessages();

    try {
      final appState = context.read<AppStateProvider>();
      final result = await _pdfService.generatePdf(
        quote: quote,
        customer: customer,
        appState: appState,
        selectedTemplateId: selectedTemplateId,
        selectedLevelId: selectedLevelId,
      );

      if (result.isSuccess) {
        _setSuccess('PDF generated successfully');
        return PDFGenerationData(
          pdfPath: result.pdfPath!,
          suggestedFileName: result.suggestedFileName!,
          templateId: result.templateId,
          customData: result.customData,
        );
      } else {
        _setError(result.errorMessage!);
        return null;
      }
    } catch (e) {
      _setError('Failed to generate PDF: $e');
      return null;
    } finally {
      _setGenerating(false);
    }
  }

  /// Generate template preview
  Future<PDFGenerationData?> generatePreview({
    required BuildContext context,
    required PDFTemplate template,
  }) async {
    _setLoadingPreview(true);
    clearMessages();

    try {
      final appState = context.read<AppStateProvider>();
      final result = await _pdfService.generatePreview(
        template: template,
        quote: quote,
        customer: customer,
        appState: appState,
        selectedLevelId: selectedLevelId,
      );

      if (result.isSuccess) {
        _setSuccess('Preview generated: ${result.suggestedFileName}');
        return PDFGenerationData(
          pdfPath: result.pdfPath!,
          suggestedFileName: result.suggestedFileName!,
          templateId: result.templateId,
          isPreview: true,
        );
      } else {
        _setError(result.errorMessage!);
        return null;
      }
    } catch (e) {
      _setError('Failed to generate preview: $e');
      return null;
    } finally {
      _setLoadingPreview(false);
    }
  }

  void _setGenerating(bool generating) {
    _isGenerating = generating;
    notifyListeners();
  }

  void _setLoadingPreview(bool loading) {
    _isLoadingPreview = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _lastSuccess = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _lastSuccess = success;
    _lastError = null;
    notifyListeners();
  }
}

/// Data class for PDF generation results
class PDFGenerationData {
  const PDFGenerationData({
    required this.pdfPath,
    required this.suggestedFileName,
    this.templateId,
    this.customData,
    this.isPreview = false,
  });

  final String pdfPath;
  final String suggestedFileName;
  final String? templateId;
  final Map<String, String>? customData;
  final bool isPreview;
}