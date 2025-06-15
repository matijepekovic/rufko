import 'package:flutter/material.dart';
import '../controllers/data_management_controller.dart';
import '../widgets/settings_tile.dart';

/// Screen providing data management actions like export/import/clear.
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _processing = false;

  late DataManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DataManagementController(
      context: context,
      onProcessingChanged: (p) => setState(() => _processing = p),
    );
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
    await _controller.exportData();
  }

  Future<void> _importData() async {
    await _controller.importData();
  }

  Future<void> _clearAllData() async {
    await _controller.clearAllData();
  }

}
