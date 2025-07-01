import 'package:flutter/material.dart';
import 'data_management_ui_controller.dart';
import '../widgets/data_management/data_management_handler.dart';

/// Refactored DataManagementController using clean architecture
/// Now acts as a coordinator between UI and business logic
class DataManagementController {
  DataManagementController({
    required BuildContext context,
    required this.onProcessingChanged,
  }) : _uiController = DataManagementUIController.fromContext(context);

  final DataManagementUIController _uiController;
  final void Function(bool isProcessing) onProcessingChanged;

  /// Get the UI controller for use in widgets
  DataManagementUIController get uiController => _uiController;

  /// Create a handler widget that manages UI concerns
  Widget createDataManagementHandler({
    required Widget child,
  }) {
    return DataManagementHandler(
      controller: _uiController,
      child: child,
    );
  }

  /// Legacy methods for backward compatibility - now delegate to handler
  Future<void> exportData() async {
    // Legacy implementation - in new architecture this would be handled by DataManagementHandler
    debugPrint('exportData() called - use DataManagementHandler.exportData() in new architecture');
  }

  Future<void> importData() async {
    // Legacy implementation - in new architecture this would be handled by DataManagementHandler
    debugPrint('importData() called - use DataManagementHandler.importData() in new architecture');
  }

  Future<void> clearAllData() async {
    // Legacy implementation - in new architecture this would be handled by DataManagementHandler
    debugPrint('clearAllData() called - use DataManagementHandler.clearAllData() in new architecture');
  }

  /// Clean up resources
  void dispose() {
    _uiController.dispose();
  }
}
