import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/data_management/data_management_service.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for data management operations
/// Handles state management and event emission without UI concerns
class DataManagementUIController extends ChangeNotifier {
  DataManagementUIController(AppStateProvider appState)
      : _service = DataManagementService(appState);

  final DataManagementService _service;

  bool _isProcessing = false;
  String? _lastError;
  String? _lastSuccess;
  String? _lastExportPath;
  dynamic _validatedBackupData;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  String? get lastExportPath => _lastExportPath;
  List<String> get dataDeletionItems => _service.getDataDeletionItems();

  /// Factory constructor for easy creation with context
  factory DataManagementUIController.fromContext(BuildContext context) {
    return DataManagementUIController(context.read<AppStateProvider>());
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

  /// Export application data
  Future<void> exportData() async {
    _setProcessing(true);
    
    try {
      final result = await _service.exportData();
      
      if (result.isSuccess) {
        _lastExportPath = result.filePath;
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Validate backup data for import
  Future<bool> validateBackupData() async {
    _setProcessing(true);
    
    try {
      final result = await _service.validateBackupData();
      
      if (result.isSuccess) {
        _validatedBackupData = result.data;
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Import validated backup data
  Future<void> importValidatedData() async {
    if (_validatedBackupData == null) {
      _setError('No validated backup data available');
      return;
    }

    _setProcessing(true);
    
    try {
      final result = await _service.importData(_validatedBackupData);
      
      if (result.isSuccess) {
        _validatedBackupData = null; // Clear after successful import
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Clear all application data
  Future<void> clearAllData() async {
    _setProcessing(true);
    
    try {
      final result = await _service.clearAllData();
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Open exported file
  Future<void> openExportedFile() async {
    if (_lastExportPath == null) {
      _setError('No exported file available to open');
      return;
    }

    final result = await _service.openFile(_lastExportPath!);
    
    if (!result.isSuccess) {
      _setError(result.errorMessage);
    }
  }
}