import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/settings_data_service.dart';

/// Controller for handling data management actions like export/import/clear.
class DataManagementController {
  DataManagementController({
    required this.context,
    required this.onProcessingChanged,
  })  : appState = context.read<AppStateProvider>(),
        service = SettingsDataService(context.read<AppStateProvider>());

  final BuildContext context;
  final AppStateProvider appState;
  final SettingsDataService service;
  final void Function(bool isProcessing) onProcessingChanged;

  Future<void> exportData() async {
    onProcessingChanged(true);
    try {
      final path = await service.exportData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: ${path.split('/').last}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => service.openFile(path),
            ),
          ),
        );
      }
    } finally {
      if (context.mounted) onProcessingChanged(false);
    }
  }

  Future<void> importData() async {
    final data = await appState.pickBackupData();
    if (!context.mounted || data.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('This will replace ALL current data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onProcessingChanged(true);
      await service.importData(data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      }
      if (context.mounted) onProcessingChanged(false);
    }
  }

  Future<void> clearAllData() async {
    final confirmed = await _showClearDataDialog();
    if (confirmed != true) return;
    if (!context.mounted) return;
    onProcessingChanged(true);
    await appState.clearAllData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully')),
      );
    }
    if (context.mounted) onProcessingChanged(false);
  }

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
              children: [
                _buildDeleteItem('All customers and quotes'),
                _buildDeleteItem('All products and pricing'),
                _buildDeleteItem('All media files and photos'),
                _buildDeleteItem('All RoofScope data'),
                _buildDeleteItem('App settings and configurations'),
              ],
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
}
