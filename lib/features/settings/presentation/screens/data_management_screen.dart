import 'package:flutter/material.dart';
import '../controllers/data_management_controller.dart';
import '../widgets/settings_tile.dart';
import '../../../../core/services/migration/migration_test_service.dart';

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
                const SettingsDivider(),
                SettingsTile(
                  icon: Icons.science,
                  iconColor: Colors.purple.shade600,
                  title: 'Test Migration System',
                  subtitle: 'Run comprehensive tests on the SQLite migration',
                  onTap: _testMigrationSystem,
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

  Future<void> _testMigrationSystem() async {
    if (_processing) return;
    
    setState(() => _processing = true);
    
    try {
      final testService = MigrationTestService();
      
      // Show progress dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Running migration tests...\nThis may take a few moments.'),
            ],
          ),
        ),
      );
      
      // Run tests
      final results = await testService.runMigrationTests();
      
      // Close progress dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show results
      if (mounted) _showTestResults(results);
      
    } catch (e) {
      // Close progress dialog if still showing
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showTestResults(Map<String, dynamic> results) {
    final summary = results['summary'] as Map<String, dynamic>?;
    if (summary == null) return;
    
    final totalTests = summary['total_tests'] ?? 0;
    final passedTests = summary['passed_tests'] ?? 0;
    final failedTests = summary['failed_tests'] ?? 0;
    final successRate = summary['success_rate'] ?? '0.0';
    final status = summary['status'] ?? 'UNKNOWN';
    final issues = (summary['issues'] as List<dynamic>?) ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status == 'ALL_PASSED' ? Icons.check_circle : Icons.warning,
              color: status == 'ALL_PASSED' ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Migration Test Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow('Total Tests', totalTests.toString()),
              _buildResultRow('Passed', passedTests.toString(), Colors.green),
              _buildResultRow('Failed', failedTests.toString(), 
                  failedTests > 0 ? Colors.red : null),
              _buildResultRow('Success Rate', '$successRate%'),
              _buildResultRow('Status', status, 
                  status == 'ALL_PASSED' ? Colors.green : Colors.orange),
              
              if (issues.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $issue', style: const TextStyle(fontSize: 12)),
                )),
              ],
              
              const SizedBox(height: 16),
              const Text(
                'This test verifies the SQLite migration system is working correctly.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

}
