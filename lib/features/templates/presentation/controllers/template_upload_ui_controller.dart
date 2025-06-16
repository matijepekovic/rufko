import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/template_upload/template_upload_service.dart';
import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for template upload operations
/// Handles state management and event emission without UI concerns
class TemplateUploadUIController extends ChangeNotifier {
  TemplateUploadUIController(this._appState) : _service = TemplateUploadService();

  final AppStateProvider _appState;
  final TemplateUploadService _service;

  bool _isUploading = false;
  String? _lastError;
  String? _lastSuccess;
  String? _uploadMessage;
  String? _selectedFilePath;
  PDFTemplate? _createdTemplate;

  // Getters
  bool get isUploading => _isUploading;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  String? get uploadMessage => _uploadMessage;
  String? get selectedFilePath => _selectedFilePath;
  PDFTemplate? get createdTemplate => _createdTemplate;

  /// Factory constructor for easy creation with context
  factory TemplateUploadUIController.fromContext(BuildContext context) {
    return TemplateUploadUIController(context.read<AppStateProvider>());
  }

  void _setUploading(bool uploading, {String? message}) {
    _isUploading = uploading;
    _uploadMessage = message;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _lastSuccess = null;
    _isUploading = false;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _lastSuccess = success;
    _lastError = null;
    _isUploading = false;
    notifyListeners();
  }

  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    _uploadMessage = null;
    notifyListeners();
  }

  /// Pick PDF file for upload
  Future<String?> pickPdfFile() async {
    _setUploading(true, message: 'Selecting PDF file...');
    
    try {
      final result = await _service.pickPdfFile();
      
      if (result.isSuccess) {
        _selectedFilePath = result.filePath;
        final fileName = _service.getFileNameFromPath(result.filePath!);
        _setSuccess('PDF file selected: $fileName');
        return result.filePath;
      } else {
        if (result.errorMessage != 'No file selected') {
          _setError(result.errorMessage);
        } else {
          _setUploading(false);
        }
        return null;
      }
    } catch (e) {
      _setError('Unexpected error: $e');
      return null;
    }
  }

  /// Create template from selected file
  Future<PDFTemplate?> createTemplateFromFile({
    required String filePath,
    required String templateName,
  }) async {
    _setUploading(true, message: 'Processing PDF & Detecting Fields...');
    
    try {
      final result = await _service.createTemplateFromFile(
        filePath: filePath,
        templateName: templateName,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _createdTemplate = result.template;
        _setSuccess('Template created successfully!');
        return result.template;
      } else {
        _setError(result.errorMessage);
        return null;
      }
    } catch (e) {
      _setError('Unexpected error: $e');
      return null;
    }
  }

  /// Upload file and create template in one operation
  Future<PDFTemplate?> uploadAndCreateTemplate({
    required String templateName,
  }) async {
    _setUploading(true, message: 'Selecting PDF file...');
    
    try {
      final result = await _service.uploadAndCreateTemplate(
        templateName: templateName,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _createdTemplate = result.template;
        _selectedFilePath = result.filePath;
        _setSuccess('Template created successfully!');
        return result.template;
      } else {
        if (result.errorMessage != 'No file selected') {
          _setError(result.errorMessage);
        } else {
          _setUploading(false);
        }
        return null;
      }
    } catch (e) {
      _setError('Unexpected error: $e');
      return null;
    }
  }

  /// Get suggested template name from file
  String getSuggestedTemplateName(String fileName) {
    return _service.extractSuggestedName(fileName);
  }

  /// Reset controller state
  void reset() {
    _isUploading = false;
    _lastError = null;
    _lastSuccess = null;
    _uploadMessage = null;
    _selectedFilePath = null;
    _createdTemplate = null;
    notifyListeners();
  }
}