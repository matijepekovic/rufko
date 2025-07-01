import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/template_mapping/template_mapping_service.dart';
import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for template field mapping operations
/// Handles state management and event emission without UI concerns
class TemplateFieldMappingUIController extends ChangeNotifier {
  TemplateFieldMappingUIController(this._appState)
      : _service = TemplateMappingService();

  final AppStateProvider _appState;
  final TemplateMappingService _service;

  PDFTemplate? _currentTemplate;
  bool _isProcessing = false;
  String? _lastError;
  String? _lastSuccess;
  Map<String, dynamic>? _selectedPdfField;

  // Getters
  PDFTemplate? get currentTemplate => _currentTemplate;
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  Map<String, dynamic>? get selectedPdfField => _selectedPdfField;
  List<dynamic> get products => _appState.products;
  List<dynamic> get customFields => _appState.customAppDataFields;

  /// Factory constructor for easy creation with context
  factory TemplateFieldMappingUIController.fromContext(BuildContext context) {
    return TemplateFieldMappingUIController(context.read<AppStateProvider>());
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
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
    notifyListeners();
  }

  /// Initialize with template
  void initializeWithTemplate(PDFTemplate? template) {
    _currentTemplate = template;
    notifyListeners();
  }

  /// Update current template
  void updateTemplate(PDFTemplate template) {
    _currentTemplate = template;
    notifyListeners();
  }

  /// Set selected PDF field for mapping
  void selectPdfField(Map<String, dynamic> pdfFieldInfo) {
    _selectedPdfField = pdfFieldInfo;
    notifyListeners();
  }

  /// Get existing mapping for PDF field
  dynamic getExistingMapping(String pdfFieldName) {
    if (_currentTemplate == null) return null;
    return _service.getExistingMapping(
      template: _currentTemplate!,
      pdfFieldName: pdfFieldName,
    );
  }

  /// Check if app data field is already mapped
  bool isAppDataFieldMapped(String appDataType) {
    if (_currentTemplate == null) return false;
    return _service.isAppDataFieldMapped(
      template: _currentTemplate!,
      appDataType: appDataType,
    );
  }

  /// Get available app data fields
  List<String> getAvailableAppDataFields() {
    return _service.getAvailableAppDataFields(
      products: products,
      customFields: customFields,
    );
  }

  /// Create field mapping
  Future<void> createFieldMapping({
    required String appDataType,
    required Map<String, dynamic> pdfFieldInfo,
    bool replaceExisting = false,
  }) async {
    if (_currentTemplate == null) {
      _setError('No template selected');
      return;
    }

    _setProcessing(true);

    try {
      // Validate mapping first
      final validation = _service.validateMapping(
        template: _currentTemplate!,
        appDataType: appDataType,
        pdfFieldInfo: pdfFieldInfo,
      );

      if (!validation.isSuccess) {
        _setError(validation.errorMessage);
        return;
      }

      // Create the mapping
      final result = _service.createFieldMapping(
        template: _currentTemplate!,
        appDataType: appDataType,
        pdfFieldInfo: pdfFieldInfo,
        replaceExisting: replaceExisting,
      );

      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        notifyListeners(); // Notify for template changes
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Remove field mapping
  Future<void> removeFieldMapping(dynamic mapping) async {
    if (_currentTemplate == null) {
      _setError('No template selected');
      return;
    }

    _setProcessing(true);

    try {
      final result = _service.removeFieldMapping(
        template: _currentTemplate!,
        mapping: mapping,
      );

      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        notifyListeners(); // Notify for template changes
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Get display name for field
  String getFieldDisplayName(String fieldName) {
    return PDFTemplate.getFieldDisplayName(fieldName);
  }

  /// Check if mapping needs replacement confirmation
  bool needsReplacementConfirmation(String appDataType) {
    return isAppDataFieldMapped(appDataType);
  }
}