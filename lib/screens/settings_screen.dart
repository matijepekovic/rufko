// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart'; // ENSURE THIS IS IMPORTED

import '../providers/app_state_provider.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';
import '../models/product.dart';
import '../models/app_settings.dart';

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
          const SizedBox(height: 24),
          _buildSectionHeader('Excel Integration'),
          _buildExcelSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Company & PDF Settings'), // Combined
          _buildCompanyAndPdfSection(), // Combined
          const SizedBox(height: 24),
          _buildSectionHeader('App Preferences'),
          _buildAppPreferencesSection(), // Renamed for clarity
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildAboutSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined, color: Colors.blueAccent),
            title: const Text('Export All Data'),
            subtitle: const Text('Create a JSON backup of all app data'),
            onTap: _exportData,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.restore_page_outlined, color: Colors.greenAccent),
            title: const Text('Import Data from Backup'),
            subtitle: const Text('Restore data from a JSON backup file'),
            onTap: _importData,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade700),
            title: Text('Clear All Data', style: TextStyle(color: Colors.red.shade700)),
            subtitle: const Text('Permanently delete all app data'),
            onTap: _showClearDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildExcelSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload_outlined, color: Colors.green),
            title: const Text('Import Products from Excel'),
            subtitle: const Text('Load products using an .xlsx or .xls file'),
            onTap: _importProductsFromExcel,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.file_download_outlined, color: Colors.blueGrey),
            title: const Text('Export Products to Excel'),
            subtitle: const Text('Save current products to an Excel file'),
            onTap: _exportProductsToExcel,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.teal),
            title: const Text('Download Product Import Template'),
            subtitle: const Text('Get an Excel template for importing products'),
            onTap: _downloadExcelTemplate,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAndPdfSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.business_outlined, color: Colors.deepPurpleAccent),
            title: const Text('Company Information'),
            subtitle: const Text('Set name, address, logo for PDFs etc.'),
            trailing: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            onTap: _showCompanyInfoDialog,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined, color: Colors.orangeAccent),
            title: const Text('View PDF Storage Location'),
            subtitle: const Text('Path where generated PDFs are saved'),
            onTap: _showPdfLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    // Using Consumer to rebuild only this part if AppSettings changes
    return Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          final currentTaxRate = appState.appSettings?.taxRate ?? 0.0;
          final defaultQuoteLevels = appState.appSettings?.defaultQuoteLevelNames.join(', ') ?? 'Basic, Standard, Best';

          return Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.percent_outlined, color: Colors.cyan),
                  title: const Text('Default Tax Rate'),
                  subtitle: Text('Current: ${currentTaxRate.toStringAsFixed(2)}%'),
                  trailing: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                  onTap: _showTaxRateDialog,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.layers_outlined, color: Colors.lime),
                  title: const Text('Default Quote Level Names'),
                  subtitle: Text('e.g., $defaultQuoteLevels'),
                  trailing: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                  onTap: _showDefaultLevelsDialog,
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue),
            title: Text('App Version'),
            subtitle: Text('1.0.0 (Alpha Build)'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.green),
            title: const Text('Help & Support'),
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Help & Support'),
                  content: const SingleChildScrollView(
                    child: Text(
                        'Rufko helps streamline roofing estimates and customer management.\n\n'
                            'For assistance, please refer to the user guide or contact support via the developer.'),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    final appState = context.read<AppStateProvider>();
    appState.setLoading(true, 'Exporting data...');
    try {
      final data = await DatabaseService.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rufko_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);
      if (mounted) {
        appState.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data exported to: Documents/Rufko/$fileName (approx path)'), // More user-friendly path
          duration: const Duration(seconds: 7),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ));
      }
    } catch (e) {
      if (mounted) {
        appState.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting data: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _importData() async {
    final appState = context.read<AppStateProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString) as Map<String, dynamic>;

        appState.setLoading(true, 'Importing data...');
        await DatabaseService.instance.importAllData(data);
        await appState.loadAllData();
        if (mounted) {
          appState.setLoading(false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data imported successfully!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) {
        appState.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing data: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('⚠️ Clear All Data?'),
        content: const Text('This action is IRREVERSIBLE and will permanently delete ALL customers, products, quotes, and other app data. It is highly recommended to export data first.\n\nAre you absolutely sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final appState = context.read<AppStateProvider>();
              appState.setLoading(true, 'Clearing all data...');
              try {
                await DatabaseService.instance.importAllData({
                  'customers': [], 'products': [], 'simplified_quotes': [],
                  'roofScopeData': [], 'projectMedia': [],
                  'appSettings': AppSettings(id: appState.appSettings?.id ?? 'singleton_app_settings').toMap(), // Reset settings but keep ID
                });
                await appState.loadAllData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All app data has been cleared.'), backgroundColor: Colors.orange));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing data: $e'), backgroundColor: Colors.red));
                }
              } finally {
                if (mounted) appState.setLoading(false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }

  void _importProductsFromExcel() async {
    // ... (This method was corrected in the previous step and should be fine)
    final appState = context.read<AppStateProvider>();
    final excelService = ExcelService();
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result != null && result.files.single.path != null) { /* ... */ }
    } catch (e) { /* ... */ }
  }

  void _exportProductsToExcel() async {
    // ... (This method was corrected in the previous step and should be fine)
  }

  void _downloadExcelTemplate() async {
    // ... (This method was corrected in the previous step and should be fine)
  }

  void _showPdfLocation() async {
    // ... (This method was corrected in the previous step and should be fine)
  }

  void _showTaxRateDialog() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings(id: 'singleton_app_settings'); // Ensure settings object exists
    final controller = TextEditingController(text: settings.taxRate.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Default Tax Rate'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tax Rate (%)', suffixText: '%', border: OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text) ?? settings.taxRate;
              settings.updateTaxRate(newRate); // This calls save() internally if AppSettings is HiveObject
              appState.updateAppSettings(settings); // Notifies provider listeners and saves again (can be optimized)
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default tax rate updated.'), backgroundColor: Colors.green));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCompanyInfoDialog() {
    final appState = context.read<AppStateProvider>();
    // Ensure we have an AppSettings instance. If not, create a new one.
    // The AppStateProvider's _loadAppSettings should create one if DB is empty.
    final settings = appState.appSettings ?? AppSettings(id: 'singleton_app_settings'); // Use fixed ID

    final nameController = TextEditingController(text: settings.companyName ?? '');
    final addressController = TextEditingController(text: settings.companyAddress ?? '');
    final phoneController = TextEditingController(text: settings.companyPhone ?? '');
    final emailController = TextEditingController(text: settings.companyEmail ?? '');
    // final logoPathController = TextEditingController(text: settings.companyLogoPath ?? ''); // For logo

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Company Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Company Address', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 16),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Company Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Company Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              // SizedBox(height: 16),
              // TextField(controller: logoPathController, decoration: InputDecoration(labelText: 'Company Logo Path (Optional)')),
              // TextButton(onPressed: () async { /* TODO: Implement logo picker */ }, child: Text("Pick Logo")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              settings.updateCompanyInfo( // Use the method in AppSettings
                name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                // logoPath: logoPathController.text.trim().isEmpty ? null : logoPathController.text.trim(),
              );
              // AppSettings.save() is called within updateCompanyInfo.
              // AppStateProvider.updateAppSettings saves again and notifies.
              appState.updateAppSettings(settings);

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company information updated.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDefaultLevelsDialog() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings(id: 'singleton_app_settings');
    // For simplicity, handle up to 3-4 levels. A more dynamic UI would be needed for more.
    List<TextEditingController> levelNameControllers = List.generate(
        settings.defaultQuoteLevelNames.length > 0 ? settings.defaultQuoteLevelNames.length : 3, // Min 3 fields
            (index) => TextEditingController(
            text: index < settings.defaultQuoteLevelNames.length ? settings.defaultQuoteLevelNames[index] : ''
        )
    );
    // Ensure we have at least 3 controllers for the UI if settings has less
    while(levelNameControllers.length < 3) {
      levelNameControllers.add(TextEditingController());
    }


    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Default Quote Level Names'),
        content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(levelNameControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: levelNameControllers[index],
                    decoration: InputDecoration(labelText: 'Level ${index + 1} Name', border: const OutlineInputBorder()),
                  ),
                );
              })
            // You could add "+" and "-" buttons here to dynamically add/remove level name fields
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newLevelNames = levelNameControllers
                  .map((controller) => controller.text.trim())
                  .where((name) => name.isNotEmpty) // Filter out empty names
                  .toList();

              if (newLevelNames.isNotEmpty) {
                settings.updateDefaultQuoteLevelNames(newLevelNames);
                appState.updateAppSettings(settings);
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default quote level names updated.'), backgroundColor: Colors.green));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}