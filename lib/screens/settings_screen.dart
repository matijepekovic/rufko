import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import '../providers/app_state_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Data Management'),
          _buildDataManagementSection(),
          const SizedBox(height: 32),

          _buildSectionHeader('Excel Integration'),
          _buildExcelSection(),
          const SizedBox(height: 32),

          _buildSectionHeader('PDF Templates'),
          _buildPdfSection(),
          const SizedBox(height: 32),

          _buildSectionHeader('App Settings'),
          _buildAppSettingsSection(),
          const SizedBox(height: 32),

          _buildSectionHeader('About'),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Export Data'),
            subtitle: const Text('Backup all your data to a file'),
            onTap: _exportData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Import Data'),
            subtitle: const Text('Restore data from a backup file'),
            onTap: _importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently delete all data'),
            onTap: _showClearDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildExcelSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Products from Excel'),
            subtitle: const Text('Load product pricing from Excel file'),
            onTap: _importProductsFromExcel,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Products to Excel'),
            subtitle: const Text('Save current products to Excel file'),
            onTap: _exportProductsToExcel,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Download Excel Template'),
            subtitle: const Text('Get a template for importing products'),
            onTap: _downloadExcelTemplate,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('PDF Quote Template'),
            subtitle: const Text('Customize quote PDF appearance'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF template customization coming soon')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('PDF Storage Location'),
            subtitle: const Text('View where PDFs are saved'),
            onTap: _showPdfLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.percent),
            title: const Text('Default Tax Rate'),
            subtitle: const Text('Set default tax rate for new quotes'),
            trailing: const Text('8.5%'),
            onTap: _showTaxRateDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Company Information'),
            subtitle: const Text('Update your company details'),
            onTap: _showCompanyInfoDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Configure app notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help using Rufko'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help & Support'),
                  content: const Text(
                    'Rufko is a professional roofing estimation and customer management app.\n\n'
                        'Features:\n'
                        '• Customer management\n'
                        '• Quote generation\n'
                        '• PDF creation\n'
                        '• Excel integration\n'
                        '• RoofScope data extraction\n'
                        '• Photo management\n\n'
                        'For support, contact your system administrator.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('Made with ❤️ for Roofing Professionals'),
            subtitle: const Text('Rufko - Professional Roofing Solutions'),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    try {
      final appState = context.read<AppStateProvider>();
      appState.setLoading(true, 'Exporting data...');

      final data = await DatabaseService.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rufko_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      appState.setLoading(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to $fileName'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ),
      );
    } catch (e) {
      context.read<AppStateProvider>().setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString) as Map<String, dynamic>;

        final appState = context.read<AppStateProvider>();
        appState.setLoading(true, 'Importing data...');

        await DatabaseService.instance.importAllData(data);
        await appState.loadAllData();

        appState.setLoading(false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      }
    } catch (e) {
      context.read<AppStateProvider>().setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all customers, quotes, products, and media. '
              'This action cannot be undone.\n\n'
              'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final appState = context.read<AppStateProvider>();
                appState.setLoading(true, 'Clearing all data...');

                // Clear all data
                await DatabaseService.instance.importAllData({
                  'customers': [],
                  'products': [],
                  'quotes': [],
                  'roofScopeData': [],
                  'projectMedia': [],
                });

                await appState.loadAllData();
                appState.setLoading(false);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              } catch (e) {
                context.read<AppStateProvider>().setLoading(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error clearing data: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  void _importProductsFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await context.read<AppStateProvider>().loadProductsFromExcel(filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Products imported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportProductsToExcel() async {
    try {
      final appState = context.read<AppStateProvider>();
      appState.setLoading(true, 'Exporting products...');

      // TODO: Implement export products to Excel
      await Future.delayed(const Duration(seconds: 2)); // Placeholder

      appState.setLoading(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Products exported to Excel')),
      );
    } catch (e) {
      context.read<AppStateProvider>().setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _downloadExcelTemplate() async {
    try {
      final appState = context.read<AppStateProvider>();
      appState.setLoading(true, 'Creating template...');

      // TODO: Implement create Excel template
      await Future.delayed(const Duration(seconds: 1)); // Placeholder

      appState.setLoading(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel template created')),
      );
    } catch (e) {
      context.read<AppStateProvider>().setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating template: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPdfLocation() async {
    final directory = await getApplicationDocumentsDirectory();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Storage Location'),
        content: Text(
          'PDFs are saved to:\n\n${directory.path}\n\n'
              'You can access these files using your device\'s file manager.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTaxRateDialog() {
    final controller = TextEditingController(text: '8.5');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Tax Rate'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tax Rate (%)',
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save tax rate setting
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tax rate updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCompanyInfoDialog() {
    final nameController = TextEditingController(text: 'Rufko Roofing');
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company Information'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save company info
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company information updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}