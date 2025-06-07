// lib/screens/settings_screen.dart - MODERN UI VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../services/file_service.dart';
import '../providers/app_state_provider.dart';
import '../services/database_service.dart';
import '../models/app_settings.dart';

import 'settings/category_manager_dialog.dart';
import 'settings/units_manager_dialog.dart';
import 'settings/quote_levels_manager_dialog.dart';
import 'settings/discount_settings_dialog.dart';
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
// 🚀 AUTOMATIC TAX LOOKUP
              _buildSettingsTile(
                icon: Icons.auto_awesome,
                iconColor: Colors.amber.shade600,
                title: 'Automatic Tax Lookup',
                subtitle: 'Premium feature - Get accurate tax rates by location',
                onTap: _showAutomaticTaxInfo,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildDivider(),
// 🚀 2-WAY COMMUNICATION
              _buildSettingsTile(
                icon: Icons.forum,
                iconColor: Colors.purple.shade600,
                title: '2-Way Communication',
                subtitle: 'Premium feature - Real SMS & email with automatic responses',
                onTap: _showTwoWayCommunicationInfo,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildDivider(),
// 🚀 ORGANIZATION PROFILES
              _buildSettingsTile(
                icon: Icons.business_center,
                iconColor: Colors.teal.shade600,
                title: 'Organization Profiles',
                subtitle: 'Premium feature - Multi-tier user management & permissions',
                onTap: _showOrganizationProfilesInfo,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAutomaticTaxInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.amber.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Automatic Tax Lookup'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.amber.shade600, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Premium Feature - Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Automatic Tax Features:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureItem('🗺️', 'Complete Washington State database'),
              _buildFeatureItem('📍', 'ZIP code specific tax rates'),
              _buildFeatureItem('🏢', 'City and county tax lookup'),
              _buildFeatureItem('🔄', 'Regular database updates'),
              _buildFeatureItem('⚡', 'Instant rate detection'),
              _buildFeatureItem('📊', 'Tax rate analytics and reporting'),

              const SizedBox(height: 20),

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
                    Expanded(
                      child: Text(
                        'Tax rates will need to be entered manually in quotes until this feature is activated.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tax lookup feature coming soon! For now, use manual tax rates.'),
                  backgroundColor: Colors.amber,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            icon: const Icon(Icons.schedule),
            label: const Text('Coming Soon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTwoWayCommunicationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.forum, color: Colors.purple.shade600),
            ),
            const SizedBox(width: 12),
            const Text('2-Way Communication'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.sync_alt, color: Colors.purple.shade600, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Premium Feature - Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Real 2-Way Communication Features:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureItem('💬', 'Send & receive SMS directly in app'),
              _buildFeatureItem('📧', 'Full email integration with responses'),
              _buildFeatureItem('🔄', 'Automatic response capture & logging'),
              _buildFeatureItem('👁️', 'Read receipts and delivery confirmations'),
              _buildFeatureItem('🤖', 'Automated follow-up sequences'),
              _buildFeatureItem('💼', 'Professional business phone numbers'),
              _buildFeatureItem('📊', 'Communication analytics and tracking'),

              const SizedBox(height: 20),

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
                    Expanded(
                      child: Text(
                        'Currently limited to opening native apps. These communication services are not free for us to provide either, so they require a premium subscription.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Communication feature coming soon! For now, templates open native apps.'),
                  backgroundColor: Colors.purple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            icon: const Icon(Icons.schedule),
            label: const Text('Coming Soon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrganizationProfilesInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.business_center, color: Colors.teal.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Organization Profiles'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.groups, color: Colors.teal.shade600, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Premium Feature - Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Multi-Tier Organization Features:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureItem('👥', 'Multiple user profiles & roles'),
              _buildFeatureItem('🔐', 'Permission-based access control'),
              _buildFeatureItem('📊', 'Team performance analytics'),
              _buildFeatureItem('🏢', 'Department & branch management'),
              _buildFeatureItem('📝', 'Approval workflows'),
              _buildFeatureItem('💼', 'Manager oversight & reporting'),
              _buildFeatureItem('🔄', 'Data sharing between team members'),

              const SizedBox(height: 20),

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
                    Expanded(
                      child: Text(
                        'Perfect for roofing companies with multiple sales teams, estimators, and project managers who need organized collaboration.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Organization profiles coming soon! Currently single-user only.'),
                  backgroundColor: Colors.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            icon: const Icon(Icons.schedule),
            label: const Text('Coming Soon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
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
                color: isDestructive ? Colors.red.shade100 : iconColor.withValues(alpha: 0.1),
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

      final databaseService = DatabaseService.instance;
      final allData = await databaseService.exportAllData();

      final filePath =
          await FileService.instance.saveExportedData(allData);

      if (mounted) {
        final fileName = filePath.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: $fileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importData() async {
    try {
      final data = await FileService.instance.pickAndReadBackupFile();
      if (!mounted) return;

      if (data.isNotEmpty) {
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
        if (!mounted) return;

        if (confirmed == true) {
          setState(() => _isProcessing = true);

          final databaseService = DatabaseService.instance;
          await databaseService.importAllData(data);
          if (!mounted) return;

          final appState = context.read<AppStateProvider>();
          await appState.loadAllData();
          if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                navigator.pop();
                setState(() => _isProcessing = true);

                final appState = context.read<AppStateProvider>();
                final databaseService = DatabaseService.instance;

                // Clear all data
                await databaseService.importAllData({});
                await appState.loadAllData();

                if (mounted) {
                  messenger.showSnackBar(
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
                  messenger.showSnackBar(
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
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.7)),
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
      final newPath = await FileService.instance.pickAndSaveCompanyLogo();

      if (newPath != null) {
        settings.updateCompanyLogo(newPath);
        appState.updateAppSettings(settings);

        setDialogState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Company logo updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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


  // Product Configuration Methods
  void _showCategoriesManager() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();

    showDialog(
      context: context,
      builder: (context) => CategoryManagerDialog(
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
      builder: (context) => UnitsManagerDialog(
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
      builder: (context) => QuoteLevelsManagerDialog(
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
      builder: (context) => DiscountSettingsDialog(
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
