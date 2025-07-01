import '../../../../data/providers/state/app_state_provider.dart';
import '../settings_data_service.dart';

/// Result object for data management operations
class DataManagementResult {
  final bool isSuccess;
  final String? message;
  final String? filePath;
  final dynamic data;

  const DataManagementResult._({
    required this.isSuccess,
    this.message,
    this.filePath,
    this.data,
  });

  factory DataManagementResult.success({
    String? message,
    String? filePath,
    dynamic data,
  }) {
    return DataManagementResult._(
      isSuccess: true,
      message: message,
      filePath: filePath,
      data: data,
    );
  }

  factory DataManagementResult.error(String message) {
    return DataManagementResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Service layer for data management operations (export, import, clear)
/// Contains pure business logic without UI dependencies
class DataManagementService {
  DataManagementService(this._appState)
      : _settingsService = SettingsDataService(_appState);

  final AppStateProvider _appState;
  final SettingsDataService _settingsService;

  /// Export all application data to a file
  Future<DataManagementResult> exportData() async {
    try {
      final path = await _settingsService.exportData();
      return DataManagementResult.success(
        message: 'Data exported to: ${path.split('/').last}',
        filePath: path,
      );
    } catch (e) {
      return DataManagementResult.error('Failed to export data: $e');
    }
  }

  /// Validate backup data before import
  Future<DataManagementResult> validateBackupData() async {
    try {
      final data = await _appState.pickBackupData();
      if (data.isEmpty) {
        return DataManagementResult.error('No backup file selected');
      }
      
      return DataManagementResult.success(
        message: 'Backup data validated successfully',
        data: data,
      );
    } catch (e) {
      return DataManagementResult.error('Failed to validate backup data: $e');
    }
  }

  /// Import data from validated backup
  Future<DataManagementResult> importData(dynamic validatedData) async {
    try {
      await _settingsService.importData(validatedData);
      return DataManagementResult.success(
        message: 'Data imported successfully',
      );
    } catch (e) {
      return DataManagementResult.error('Failed to import data: $e');
    }
  }

  /// Clear all application data
  Future<DataManagementResult> clearAllData() async {
    try {
      await _appState.clearAllData();
      return DataManagementResult.success(
        message: 'All data cleared successfully',
      );
    } catch (e) {
      return DataManagementResult.error('Failed to clear data: $e');
    }
  }

  /// Open file in system default application
  Future<DataManagementResult> openFile(String filePath) async {
    try {
      _settingsService.openFile(filePath);
      return DataManagementResult.success(
        message: 'File opened successfully',
      );
    } catch (e) {
      return DataManagementResult.error('Failed to open file: $e');
    }
  }

  /// Get data deletion preview information
  List<String> getDataDeletionItems() {
    return [
      'All customers and quotes',
      'All products and pricing',
      'All media files and photos',
      'All RoofScope data',
      'App settings and configurations',
    ];
  }
}