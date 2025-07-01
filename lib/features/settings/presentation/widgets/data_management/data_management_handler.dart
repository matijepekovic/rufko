import 'package:flutter/material.dart';
import '../../controllers/data_management_ui_controller.dart';

/// Widget that handles UI concerns for data management operations
/// Separates UI concerns from business logic by managing dialogs, snackbars, and loading states
class DataManagementHandler extends StatefulWidget {
  final DataManagementUIController controller;
  final Widget child;

  const DataManagementHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<DataManagementHandler> createState() => _DataManagementHandlerState();
}

class _DataManagementHandlerState extends State<DataManagementHandler> {
  /// Public methods for backward compatibility and external access
  Future<void> exportData() => _exportData();
  Future<void> importData() => _importData();
  Future<void> clearAllData() => _clearAllData();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanges);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanges);
    super.dispose();
  }

  void _handleControllerChanges() {
    // Handle error messages
    if (widget.controller.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.controller.lastError!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }

    // Handle success messages
    if (widget.controller.lastSuccess != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.controller.lastSuccess!),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              action: widget.controller.lastSuccess!.contains('exported') &&
                      widget.controller.lastExportPath != null
                  ? SnackBarAction(
                      label: 'Open',
                      onPressed: () => widget.controller.openExportedFile(),
                    )
                  : null,
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }
  }

  /// Export data with user feedback
  Future<void> _exportData() async {
    await widget.controller.exportData();
  }

  /// Import data with confirmation dialog
  Future<void> _importData() async {
    // First validate the backup data
    final isValid = await widget.controller.validateBackupData();
    if (!isValid || !mounted) return;

    // Show confirmation dialog
    final confirmed = await _showImportConfirmationDialog();
    if (confirmed == true && mounted) {
      await widget.controller.importValidatedData();
    }
  }

  /// Clear all data with confirmation dialog
  Future<void> _clearAllData() async {
    final confirmed = await _showClearDataDialog();
    if (confirmed == true && mounted) {
      await widget.controller.clearAllData();
    }
  }

  /// Show import confirmation dialog
  Future<bool?> _showImportConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('This will replace ALL current data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  /// Show clear all data confirmation dialog
  Future<bool?> _showClearDataDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will permanently delete all app data.'),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.controller.dataDeletionItems
                  .map((item) => _buildDeleteItem(item))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }

  /// Build individual delete item widget
  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.close, color: Colors.red.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            if (widget.controller.isProcessing)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
}