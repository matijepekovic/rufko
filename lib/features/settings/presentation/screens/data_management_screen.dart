import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/settings_data_service.dart';
import '../widgets/settings_tile.dart';

/// Screen providing data management actions like export/import/clear.
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _processing = false;

  late SettingsDataService _service;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    _service = SettingsDataService(appState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: _processing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SettingsTile(
                  icon: Icons.backup,
                  iconColor: Colors.blue.shade600,
                  title: 'Export All Data',
                  subtitle: 'Create a JSON backup of all app data',
                  onTap: _exportData,
                ),
                const SettingsDivider(),
                SettingsTile(
                  icon: Icons.restore,
                  iconColor: Colors.green.shade600,
                  title: 'Import Data from Backup',
                  subtitle: 'Restore data from a JSON backup file',
                  onTap: _importData,
                ),
                const SettingsDivider(),
                SettingsTile(
                  icon: Icons.delete_sweep,
                  iconColor: Colors.red.shade600,
                  title: 'Clear All Data',
                  subtitle: 'Permanently delete all app data',
                  onTap: _clearAllData,
                  isDestructive: true,
                ),
              ],
            ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _processing = true);
    try {
      final path = await _service.exportData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to: ${path.split('/').last}'),
          action: SnackBarAction(
              label: 'Open', onPressed: () => _service.openFile(path)),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _importData() async {
    final appState = context.read<AppStateProvider>();
    final data = await appState.pickBackupData();
    if (!mounted || data.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('This will replace ALL current data. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _processing = true);
      await _service.importData(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully')));
      }
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await _showClearDataDialog();
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _processing = true);
    final appState = context.read<AppStateProvider>();
    await appState.clearAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully')),
      );
    }
    if (mounted) setState(() => _processing = false);
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
