// lib/screens/settings_screen.dart - MODERN UI VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/app_state_provider.dart';
import '../services/database_service.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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

          _buildSectionHeader('Company & Business'),
          _buildCompanyAndBusinessSection(),
          const SizedBox(height: 24),

          _buildSectionHeader('Discount Settings'),
          _buildDiscountSettingsSection(),
          const SizedBox(height: 24),

          _buildSectionHeader('Data Management'),
          _buildDataManagementSection(),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildProductConfigurationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.category,
            iconColor: Colors.blue.shade600,
            title: 'Product Categories',
            subtitle: 'Manage available product categories',
            onTap: _showCategoriesManager,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.straighten,
            iconColor: Colors.green.shade600,
            title: 'Product Units',
            subtitle: 'Manage available measurement units',
            onTap: _showUnitsManager,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.layers,
            iconColor: Colors.purple.shade600,
            title: 'Quote Level Names',
            subtitle: 'Configure default quote level names',
            onTap: _showQuoteLevelsManager,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAndBusinessSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final settings = appState.appSettings ?? AppSettings();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.business,
                iconColor: Colors.indigo.shade600,
                title: 'Company Information',
                subtitle: settings.companyName?.isNotEmpty == true
                    ? settings.companyName!
                    : 'Set company name, logo, and contact info',
                onTap: _showCompanyInfoDialog,
                trailing: settings.companyLogoPath != null
                    ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(settings.companyLogoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.business, color: Colors.grey[400]),
                    ),
                  ),
                )
                    : null,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.percent,
                iconColor: Colors.cyan.shade600,
                title: 'Default Tax Rate',
                subtitle: 'Current: ${settings.taxRate.toStringAsFixed(2)}%',
                onTap: _showTaxRateDialog,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountSettingsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final settings = appState.appSettings ?? AppSettings();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.discount,
                iconColor: Colors.orange.shade600,
                title: 'Discount System',
                subtitle: 'Max discount: ${settings.defaultDiscountLimit.toStringAsFixed(1)}%',
                onTap: _showDiscountSettingsDialog,
              ),
              _buildDivider(),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.toggle_on, color: Colors.teal.shade600, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Discount Toggle',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Allow products to be marked as non-discountable',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.allowProductDiscountToggle,
                      onChanged: (value) {
                        settings.updateDiscountSettings(allowToggle: value);
                        appState.updateAppSettings(settings);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.backup,
            iconColor: Colors.blue.shade600,
            title: 'Export All Data',
            subtitle: 'Create a JSON backup of all app data',
            onTap: _exportData,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.restore,
            iconColor: Colors.green.shade600,
            title: 'Import Data from Backup',
            subtitle: 'Restore data from a JSON backup file',
            onTap: _importData,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.delete_sweep,
            iconColor: Colors.red.shade600,
            title: 'Clear All Data',
            subtitle: 'Permanently delete all app data',
            onTap: _showClearDataDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info,
            iconColor: Colors.blue.shade600,
            title: 'App Version',
            subtitle: '1.0.0 (Modern Build)',
            showArrow: false,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.help,
            iconColor: Colors.green.shade600,
            title: 'Help & Support',
            subtitle: 'Get help with using Rufko',
            onTap: _showHelpDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = true,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.shade100 : iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red.shade600 : iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ] else if (showArrow && onTap != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.grey[200],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.help, color: Colors.green.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Help & Support'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rufko helps streamline roofing estimates with enhanced product management, flexible discounting, and comprehensive quote generation.\n',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Key Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Dynamic product categories and units'),
              Text('• Advanced 3-tier pricing system'),
              Text('• Professional quote generation'),
              Text('• Customer relationship management'),
              Text('• Photo documentation'),
              Text('• RoofScope PDF data extraction'),
              Text('• Flexible discount system'),
              SizedBox(height: 16),
              Text(
                'For technical support or feature requests, please contact our development team.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                const Text('Import Data'),
              ],
            ),
            content: const Text(
              'This will replace ALL current data with the backup data. '
                  'Are you sure you want to continue?\n\n'
                  'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Import'),
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
              SnackBar(
                content: const Text('Data imported successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('Clear All Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red.shade600, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'This will permanently delete ALL data including:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This action cannot be undone!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                    SnackBar(
                      content: const Text('All data cleared successfully'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing data: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
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

  // Company & Business Methods
  void _showCompanyInfoDialog() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();

    final nameController = TextEditingController(text: settings.companyName ?? '');
    final addressController = TextEditingController(text: settings.companyAddress ?? '');
    final phoneController = TextEditingController(text: settings.companyPhone ?? '');
    final emailController = TextEditingController(text: settings.companyEmail ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.business, color: Colors.indigo.shade600),
              ),
              const SizedBox(width: 12),
              const Text('Company Information'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Company Logo Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Company Logo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (settings.companyLogoPath != null) ...[
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(settings.companyLogoPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.business, color: Colors.grey[400], size: 48),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _selectCompanyLogo(setDialogState, settings, appState),
                                icon: const Icon(Icons.edit),
                                label: const Text('Change'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  settings.updateCompanyLogo(null);
                                  appState.updateAppSettings(settings);
                                  setDialogState(() {});
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('Remove'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _selectCompanyLogo(setDialogState, settings, appState),
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Add Logo'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Company Information Fields
                  _buildCompanyTextField(
                    controller: nameController,
                    label: 'Company Name',
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 16),
                  _buildCompanyTextField(
                    controller: addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildCompanyTextField(
                    controller: phoneController,
                    label: 'Phone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildCompanyTextField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
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
                  SnackBar(
                    content: const Text('Company information updated!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Future<void> _selectCompanyLogo(StateSetter setDialogState, AppSettings settings, AppStateProvider appState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Get the app documents directory
        final directory = await getApplicationDocumentsDirectory();
        final logoDir = Directory('${directory.path}/company_logos');

        // Create directory if it doesn't exist
        if (!await logoDir.exists()) {
          await logoDir.create(recursive: true);
        }

        // Copy image to app directory with unique name
        final fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}';
        final newPath = '${logoDir.path}/$fileName';

        await File(image.path).copy(newPath);

        // Update settings
        settings.updateCompanyLogo(newPath);
        appState.updateAppSettings(settings);

        setDialogState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Company logo updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting logo: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showTaxRateDialog() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();
    final controller = TextEditingController(text: settings.taxRate.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.percent, color: Colors.cyan.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Default Tax Rate'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Tax Rate (%)',
            prefixIcon: Icon(Icons.percent, color: Theme.of(context).primaryColor.withOpacity(0.7)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
            ),
            suffixText: '%',
            filled: true,
            fillColor: Colors.white,
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
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid tax rate (0-100%)'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            SnackBar(
              content: const Text('Categories updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            SnackBar(
              content: const Text('Units updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            SnackBar(
              content: const Text('Quote levels updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            SnackBar(
              content: const Text('Discount settings updated!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }
}

// Dialog classes (keeping the existing implementations but with modern styling)
// Replace the _CategoryManagerDialog class in your settings_screen.dart with this enhanced version

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.category, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Manage Product Categories'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450, // Increased height to accommodate edit functionality
        child: Column(
          children: [
            // Add new category section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      decoration: InputDecoration(
                        labelText: 'New Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.add, color: Colors.blue.shade600),
                      ),
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addCategory,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Categories list header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Current Categories (${_categories.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  if (_categories.length > 1)
                    Text(
                      'Tap to edit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Categories list
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 20,
                          child: Icon(
                            Icons.category,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600),
                              onPressed: () => _editCategory(index, category),
                              tooltip: 'Edit category',
                            ),
                            // Delete button (only show if more than 1 category)
                            if (_categories.length > 1)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                                onPressed: () => _removeCategory(index),
                                tooltip: 'Delete category',
                              ),
                          ],
                        ),
                        onTap: () => _editCategory(index, category),
                      ),
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
          child: const Text('Save Changes'),
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
    } else if (_categories.contains(newCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Category already exists'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _removeCategory(int index) {
    if (_categories.length > 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Text('Delete Category'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${_categories[index]}"?\n\nProducts in this category will need to be reassigned.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _categories.removeAt(index);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _editCategory(int index, String currentName) {
    final TextEditingController editController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Edit Category'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                prefixIcon: Icon(Icons.category, color: Colors.blue.shade600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _updateCategory(index, value.trim(), editController);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Existing products with this category will be updated automatically.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              editController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                _updateCategory(index, newName, editController);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateCategory(int index, String newName, TextEditingController controller) {
    if (newName == _categories[index]) {
      // No change
      controller.dispose();
      Navigator.pop(context);
      return;
    }

    if (_categories.contains(newName)) {
      // Category name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Category name already exists'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _categories[index] = newName;
    });

    controller.dispose();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category updated to "$newName"'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.straighten, color: Colors.green.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Manage Product Units'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: InputDecoration(
                            labelText: 'New Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) => _addUnit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addUnit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _defaultUnit,
                    decoration: InputDecoration(
                      labelText: 'Default Unit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _units.length,
                itemBuilder: (context, index) {
                  final unit = _units[index];
                  final isDefault = unit == _defaultUnit;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      color: isDefault ? Colors.green.shade50 : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Icon(
                          isDefault ? Icons.star : Icons.straighten,
                          color: isDefault ? Colors.green.shade700 : Colors.grey[600],
                        ),
                        title: Text(
                          unit,
                          style: TextStyle(
                            fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: isDefault ? const Text('Default unit') : null,
                        trailing: _units.length > 1 && !isDefault
                            ? IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                          onPressed: () => _removeUnit(index),
                        )
                            : null,
                      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.layers, color: Colors.purple.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Configure Quote Levels'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Set names for default quote levels used in product pricing.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controllers[index],
                            decoration: InputDecoration(
                              labelText: 'Level ${index + 1} Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_controllers.length > 3) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade600),
                            onPressed: () => _removeLevel(index),
                          ),
                        ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.discount, color: Colors.orange.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Discount Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _limitController,
            decoration: InputDecoration(
              labelText: 'Maximum Discount Percentage',
              prefixIcon: Icon(Icons.percent, color: Colors.orange.shade600),
              suffixText: '%',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              _discountLimit = double.tryParse(value) ?? _discountLimit;
            },
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Discount Types:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                ...['percentage', 'fixed_amount', 'voucher'].map((type) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: CheckboxListTile(
                      title: Text(
                        type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      ),
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
                      activeColor: Colors.orange.shade600,
                      dense: true,
                    ),
                  );
                }),
              ],
            ),
          ),
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