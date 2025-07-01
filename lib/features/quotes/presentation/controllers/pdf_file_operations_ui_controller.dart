import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/pdf_file/pdf_file_service.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/ui/pdf_form_field.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for PDF file operations
/// Handles state management and event emission without UI concerns
class PdfFileOperationsUIController extends ChangeNotifier {
  PdfFileOperationsUIController(this._appState) : _service = PdfFileService();

  final AppStateProvider _appState;
  final PdfFileService _service;

  bool _isSaving = false;
  bool _isSharing = false;
  String? _lastError;
  String? _lastSuccess;
  String? _lastSavedFilePath;
  String? _lastOperationType; // Track operation type for navigation

  // Getters
  bool get isSaving => _isSaving;
  bool get isSharing => _isSharing;
  bool get isProcessing => _isSaving || _isSharing;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  String? get lastSavedFilePath => _lastSavedFilePath;
  String? get lastOperationType => _lastOperationType;

  /// Factory constructor for easy creation with context
  factory PdfFileOperationsUIController.fromContext(BuildContext context) {
    return PdfFileOperationsUIController(context.read<AppStateProvider>());
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setSharing(bool sharing) {
    _isSharing = sharing;
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

  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    _lastOperationType = null;
    notifyListeners();
  }

  /// Save PDF with optional edits
  Future<bool> savePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
  }) async {
    _setSaving(true);
    _lastOperationType = 'save'; // Track this as a save operation

    try {
      final result = await _service.savePdf(
        currentPdfPath: currentPdfPath,
        editedValues: editedValues,
        formFields: formFields,
        suggestedFileName: suggestedFileName,
        customer: customer,
        quote: quote,
        templateId: templateId,
        appState: _appState,
      );

      if (result.isSuccess) {
        _lastSavedFilePath = result.filePath;
        _setSuccess(result.successMessage);
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } finally {
      _setSaving(false);
    }
  }

  /// Prepare PDF for sharing
  Future<String?> preparePdfForSharing({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
  }) async {
    _setSharing(true);
    _lastOperationType = 'share'; // Track this as a share operation

    try {
      final result = await _service.preparePdfForSharing(
        currentPdfPath: currentPdfPath,
        editedValues: editedValues,
        formFields: formFields,
        suggestedFileName: suggestedFileName,
      );

      if (result.isSuccess) {
        _setSuccess('PDF prepared for sharing');
        return result.filePath;
      } else {
        _setError(result.errorMessage);
        return null;
      }
    } finally {
      _setSharing(false);
    }
  }

  /// Open file with system default application
  Future<void> openFile(String filePath) async {
    final result = await _service.openFile(filePath);
    
    if (result.isSuccess) {
      _setSuccess('Opening file...');
    } else {
      _setError(result.errorMessage);
    }
  }

  /// Share PDF with callback
  Future<void> sharePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    required Future<void> Function({
      required String filePath,
      required String fileName,
      Customer? customer,
    }) shareFileCallback,
  }) async {
    final filePath = await preparePdfForSharing(
      currentPdfPath: currentPdfPath,
      editedValues: editedValues,
      formFields: formFields,
      suggestedFileName: suggestedFileName,
    );

    if (filePath != null) {
      try {
        await shareFileCallback(
          filePath: filePath,
          fileName: suggestedFileName,
          customer: customer,
        );
        _setSuccess('PDF shared successfully');
      } catch (e) {
        _setError('Failed to share PDF: $e');
      }
    }
  }

  /// Legacy method compatibility - save PDF
  Future<void> savePdfLegacy({
    required String currentPdfPath,
    required String suggestedFileName,
    Map<String, String>? edits,
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
  }) async {
    await savePdf(
      currentPdfPath: currentPdfPath,
      editedValues: edits ?? {},
      formFields: [], // Legacy calls don't have form fields
      suggestedFileName: suggestedFileName,
      customer: customer,
      quote: quote,
      templateId: templateId,
    );
  }
}