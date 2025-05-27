// lib/screens/settings_screen.dart - COMPLETE IMPLEMENTATION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

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
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing...'),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Product Configuration'),
          _buildProductConfigurationSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Data Management'),
          _buildDataManagementSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Excel Integration'),
          _buildExcelSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Company & PDF Settings'),
          _buildCompanyAndPdfSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Discount Settings'),
          _buildDiscountSettingsSection(),
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

  Widget _buildProductConfigurationSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.category, color: Colors.blue.shade700),
            ),
            title: const Text('Product Categories'),
            subtitle: const Text('Manage available product categories'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showCategoriesManager,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.straighten, color: Colors.green.shade700),
            ),
            title: const Text('Product Units'),
            subtitle: const Text('Manage available measurement units'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showUnitsManager,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.layers, color: Colors.purple.shade700),
            ),
            title: const Text('Quote Level Names'),
            subtitle: const Text('Configure default quote level names'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showQuoteLevelsManager,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSettingsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final settings = appState.appSettings ?? AppSettings();

        return Card(
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.discount, color: Colors.orange.shade700),
                ),
                title: const Text('Discount System'),
                subtitle: Text('Max discount: ${settings.defaultDiscountLimit.toStringAsFixed(1)}%'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showDiscountSettingsDialog,
              ),
              SwitchListTile(
                title: const Text('Product Discount Toggle'),
                subtitle: const Text('Allow products to be marked as non-discountable'),
                value: settings.allowProductDiscountToggle,
                onChanged: (value) {
                  settings.updateDiscountSettings(allowToggle: value);
                  appState.updateAppSettings(settings);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.toggle_on, color: Colors.indigo.shade700),
                ),
              ),
            ],
          ),
        );
      },
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
            title: const Text('Download Product Template'),
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
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              final settings = appState.appSettings ?? AppSettings();
              return ListTile(
                leading: const Icon(Icons.percent_outlined, color: Colors.cyan),
                title: const Text('Default Tax Rate'),
                subtitle: Text('Current: ${settings.taxRate.toStringAsFixed(2)}%'),
                trailing: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                onTap: _showTaxRateDialog,
              );
            },
          ),
        ],
      ),
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
            subtitle: Text('1.0.0 (Enhanced Build)'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.green),
            title: const Text('Help & Support'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help & Support'),
                  content: const SingleChildScrollView(
                    child: Text(
                        'Rufko helps streamline roofing estimates with enhanced product management, '
                            'flexible discounting, and comprehensive quote generation.\n\n'
                            'New Features:\n'
                            '• Dynamic product categories and units\n'
                            '• Advanced discount system\n'
                            '• Enhanced level pricing\n'
                            '• Flexible quote configuration\n\n'
                            'For assistance, please contact support.'
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // IMPLEMENTATION METHODS

  // Data Management Methods
  Future<void> _exportData() async {
    try {
      setState(() => _isProcessing = true);

      final appState = context.read<AppStateProvider>();
      final databaseService = DatabaseService.instance;

      // Export all data
      final allData = await databaseService.exportAllData();

      // Get downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rufko_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');

      // Write JSON data
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(allData),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Data'),
            content: const Text(
                'This will replace ALL current data with the backup data. '
                    'Are you sure you want to continue?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          setState(() => _isProcessing = true);

          final jsonString = await file.readAsString();
          final data = jsonDecode(jsonString) as Map<String, dynamic>;

          final databaseService = DatabaseService.instance;
          await databaseService.importAllData(data);

          // Reload app state
          final appState = context.read<AppStateProvider>();
          await appState.loadAllData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data imported successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'This will permanently delete ALL data including:\n'
                  '• All customers and quotes\n'
                  '• All products\n'
                  '• All media files\n'
                  '• All RoofScope data\n'
                  '• App settings\n\n'
                  'This action cannot be undone!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                setState(() => _isProcessing = true);

                final appState = context.read<AppStateProvider>();
                final databaseService = DatabaseService.instance;

                // Clear all data
                await databaseService.importAllData({});
                await appState.loadAllData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: const Text('DELETE ALL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Excel Methods
  Future<void> _importProductsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isProcessing = true);

        final filePath = result.files.single.path!;
        final excelService = ExcelService();

        // Load products from Excel
        final products = await excelService.loadProductsFromExcel(filePath);

        if (products.isNotEmpty) {
          final appState = context.read<AppStateProvider>();
          await appState.importProducts(products);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported ${products.length} products successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No products found in Excel file'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportProductsToExcel() async {
    try {
      setState(() => _isProcessing = true);

      final appState = context.read<AppStateProvider>();
      final products = appState.products;

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final excelService = ExcelService();
      final filePath = await excelService.saveProductsToExcel(products);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${products.length} products to Excel'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadExcelTemplate() async {
    try {
      setState(() => _isProcessing = true);

      final excelService = ExcelService();
      final templatePath = await excelService.createProductTemplate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product template created'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(templatePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template creation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Company & PDF Methods
  void _showCompanyInfoDialog() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();

    final nameController = TextEditingController(text: settings.companyName ?? '');
    final addressController = TextEditingController(text: settings.companyAddress ?? '');
    final phoneController = TextEditingController(text: settings.companyPhone ?? '');
    final emailController = TextEditingController(text: settings.companyEmail ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
              settings.updateCompanyInfo(
                name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
              );
              appState.updateAppSettings(settings);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Company information updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTaxRateDialog() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();
    final controller = TextEditingController(text: settings.taxRate.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Tax Rate'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tax Rate (%)',
            border: OutlineInputBorder(),
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
              final rate = double.tryParse(controller.text) ?? 0.0;
              if (rate >= 0 && rate <= 100) {
                settings.updateTaxRate(rate);
                appState.updateAppSettings(settings);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tax rate updated to ${rate.toStringAsFixed(2)}%'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid tax rate (0-100%)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Product Configuration Methods
  void _showCategoriesManager() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();

    showDialog(
      context: context,
      builder: (context) => _CategoryManagerDialog(
        categories: List.from(settings.productCategories),
        onSave: (updatedCategories) {
          settings.updateProductCategories(updatedCategories);
          appState.updateAppSettings(settings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categories updated successfully!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _showUnitsManager() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();

    showDialog(
      context: context,
      builder: (context) => _UnitsManagerDialog(
        units: List.from(settings.productUnits),
        defaultUnit: settings.defaultUnit,
        onSave: (updatedUnits, newDefaultUnit) {
          settings.updateProductUnits(updatedUnits);
          settings.updateDefaultUnit(newDefaultUnit);
          appState.updateAppSettings(settings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Units updated successfully!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _showQuoteLevelsManager() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();

    showDialog(
      context: context,
      builder: (context) => _QuoteLevelsManagerDialog(
        levelNames: List.from(settings.defaultQuoteLevelNames),
        onSave: (updatedLevels) {
          settings.updateDefaultQuoteLevelNames(updatedLevels);
          appState.updateAppSettings(settings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote levels updated successfully!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _showDiscountSettingsDialog() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();

    showDialog(
      context: context,
      builder: (context) => _DiscountSettingsDialog(
        discountTypes: List.from(settings.discountTypes),
        defaultDiscountLimit: settings.defaultDiscountLimit,
        onSave: (types, limit) {
          settings.updateDiscountSettings(types: types, discountLimit: limit);
          appState.updateAppSettings(settings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discount settings updated!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }
}

// Dialog classes remain the same as in your original code...
// (I'll include them for completeness but they're unchanged)

// Category Manager Dialog
class _CategoryManagerDialog extends StatefulWidget {
  final List<String> categories;
  final Function(List<String>) onSave;

  const _CategoryManagerDialog({
    required this.categories,
    required this.onSave,
  });

  @override
  State<_CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<_CategoryManagerDialog> {
  late List<String> _categories;
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Product Categories'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: const InputDecoration(
                      labelText: 'New Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    child: ListTile(
                      title: Text(category),
                      trailing: _categories.length > 1
                          ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeCategory(index),
                      )
                          : null,
                    ),
                  );
                },
              ),
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
            widget.onSave(_categories);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addCategory() {
    final newCategory = _addController.text.trim();
    if (newCategory.isNotEmpty && !_categories.contains(newCategory)) {
      setState(() {
        _categories.add(newCategory);
        _addController.clear();
      });
    }
  }

  void _removeCategory(int index) {
    if (_categories.length > 1) {
      setState(() {
        _categories.removeAt(index);
      });
    }
  }
}

// Units Manager Dialog
class _UnitsManagerDialog extends StatefulWidget {
  final List<String> units;
  final String defaultUnit;
  final Function(List<String>, String) onSave;

  const _UnitsManagerDialog({
    required this.units,
    required this.defaultUnit,
    required this.onSave,
  });

  @override
  State<_UnitsManagerDialog> createState() => _UnitsManagerDialogState();
}

class _UnitsManagerDialogState extends State<_UnitsManagerDialog> {
  late List<String> _units;
  late String _defaultUnit;
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _units = List.from(widget.units);
    _defaultUnit = widget.defaultUnit;
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Product Units'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: const InputDecoration(
                      labelText: 'New Unit',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addUnit(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addUnit,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _defaultUnit,
              decoration: const InputDecoration(
                labelText: 'Default Unit',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _units.map((unit) => DropdownMenuItem(
                value: unit,
                child: Text(unit),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _defaultUnit = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _units.length,
                itemBuilder: (context, index) {
                  final unit = _units[index];
                  final isDefault = unit == _defaultUnit;
                  return Card(
                    color: isDefault ? Colors.blue.shade50 : null,
                    child: ListTile(
                      title: Text(unit),
                      leading: isDefault
                          ? Icon(Icons.star, color: Colors.blue.shade700)
                          : const Icon(Icons.straighten),
                      trailing: _units.length > 1 && !isDefault
                          ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeUnit(index),
                      )
                          : null,
                    ),
                  );
                },
              ),
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
            widget.onSave(_units, _defaultUnit);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addUnit() {
    final newUnit = _addController.text.trim();
    if (newUnit.isNotEmpty && !_units.contains(newUnit)) {
      setState(() {
        _units.add(newUnit);
        _addController.clear();
      });
    }
  }

  void _removeUnit(int index) {
    if (_units.length > 1 && _units[index] != _defaultUnit) {
      setState(() {
        _units.removeAt(index);
      });
    }
  }
}

// Quote Levels Manager Dialog
class _QuoteLevelsManagerDialog extends StatefulWidget {
  final List<String> levelNames;
  final Function(List<String>) onSave;

  const _QuoteLevelsManagerDialog({
    required this.levelNames,
    required this.onSave,
  });

  @override
  State<_QuoteLevelsManagerDialog> createState() => _QuoteLevelsManagerDialogState();
}

class _QuoteLevelsManagerDialogState extends State<_QuoteLevelsManagerDialog> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.levelNames.map((name) => TextEditingController(text: name)).toList();
    while (_controllers.length < 3) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure Quote Levels'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            const Text('Set names for default quote levels:'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controllers[index],
                            decoration: InputDecoration(
                              labelText: 'Level ${index + 1} Name',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_controllers.length > 3)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeLevel(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addLevel,
              icon: const Icon(Icons.add),
              label: const Text('Add Level'),
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
            final levelNames = _controllers
                .map((c) => c.text.trim())
                .where((name) => name.isNotEmpty)
                .toList();
            widget.onSave(levelNames);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addLevel() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeLevel(int index) {
    if (_controllers.length > 3) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
      });
    }
  }
}

// Discount Settings Dialog
class _DiscountSettingsDialog extends StatefulWidget {
  final List<String> discountTypes;
  final double defaultDiscountLimit;
  final Function(List<String>, double) onSave;

  const _DiscountSettingsDialog({
    required this.discountTypes,
    required this.defaultDiscountLimit,
    required this.onSave,
  });

  @override
  State<_DiscountSettingsDialog> createState() => _DiscountSettingsDialogState();
}

class _DiscountSettingsDialogState extends State<_DiscountSettingsDialog> {
  late List<String> _discountTypes;
  late double _discountLimit;
  final TextEditingController _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _discountTypes = List.from(widget.discountTypes);
    _discountLimit = widget.defaultDiscountLimit;
    _limitController.text = _discountLimit.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Discount Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _limitController,
            decoration: const InputDecoration(
              labelText: 'Maximum Discount Percentage',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              _discountLimit = double.tryParse(value) ?? _discountLimit;
            },
          ),
          const SizedBox(height: 16),
          const Text('Available Discount Types:'),
          const SizedBox(height: 8),
          ...['percentage', 'fixed_amount', 'voucher'].map((type) {
            return CheckboxListTile(
              title: Text(type.replaceAll('_', ' ').toUpperCase()),
              value: _discountTypes.contains(type),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (!_discountTypes.contains(type)) {
                      _discountTypes.add(type);
                    }
                  } else {
                    _discountTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_discountTypes, _discountLimit);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}