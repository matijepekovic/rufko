import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import 'settings_tile.dart';
import '../../../../core/utils/settings_constants.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
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
}

class ProductConfigurationSection extends StatelessWidget {
  const ProductConfigurationSection({
    super.key,
    required this.onCategories,
    required this.onUnits,
    required this.onQuoteLevels,
    required this.onJobTypes,
  });
  final VoidCallback onCategories;
  final VoidCallback onUnits;
  final VoidCallback onQuoteLevels;
  final VoidCallback onJobTypes;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SettingsTile(
            icon: Icons.category,
            iconColor: Colors.blue.shade600,
            title: 'Product Categories',
            subtitle: 'Manage available product categories',
            onTap: onCategories,
          ),
          const SettingsDivider(),
          SettingsTile(
            icon: Icons.straighten,
            iconColor: Colors.green.shade600,
            title: 'Product Units',
            subtitle: 'Manage available measurement units',
            onTap: onUnits,
          ),
          const SettingsDivider(),
          SettingsTile(
            icon: Icons.layers,
            iconColor: Colors.purple.shade600,
            title: 'Quote Level Names',
            subtitle: 'Configure default quote level names',
            onTap: onQuoteLevels,
          ),
          const SettingsDivider(),
          SettingsTile(
            icon: Icons.work_outline,
            iconColor: Colors.orange.shade600,
            title: 'Job Types',
            subtitle: 'Manage available job types for categorization',
            onTap: onJobTypes,
          ),
        ],
      ),
    );
  }
}

class CompanyAndBusinessSection extends StatelessWidget {
  const CompanyAndBusinessSection({
    super.key,
    required this.onCompanyInfo,
    required this.onAutomaticTax,
    required this.onTwoWayCommunication,
    required this.onOrganizationProfiles,
  });
  final VoidCallback onCompanyInfo;
  final VoidCallback onAutomaticTax;
  final VoidCallback onTwoWayCommunication;
  final VoidCallback onOrganizationProfiles;
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final settings = appState.appSettings ?? AppSettings();
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.business,
                iconColor: Colors.indigo.shade600,
                title: 'Company Information',
                subtitle: settings.companyName?.isNotEmpty == true
                    ? settings.companyName!
                    : 'Set company name, logo, and contact info',
                onTap: onCompanyInfo,
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
                            errorBuilder: (c, e, s) =>
                                Icon(Icons.business, color: Colors.grey[400]),
                          ),
                        ),
                      )
                    : null,
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.auto_awesome,
                iconColor: Colors.amber.shade600,
                title: 'Automatic Tax Lookup',
                subtitle: 'Premium feature - Get accurate tax rates by location',
                onTap: onAutomaticTax,
                trailing: _proTag(Colors.amber),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.forum,
                iconColor: Colors.purple.shade600,
                title: '2-Way Communication',
                subtitle:
                    'Premium feature - Real SMS & email with automatic responses',
                onTap: onTwoWayCommunication,
                trailing: _proTag(Colors.purple),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.business_center,
                iconColor: Colors.teal.shade600,
                title: 'Organization Profiles',
                subtitle:
                    'Premium feature - Multi-tier user management & permissions',
                onTap: onOrganizationProfiles,
                trailing: _proTag(Colors.teal),
              ),
            ],
          ),
        );
      },
    );
  }
  static Widget _proTag(MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade300),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DiscountSettingsSection extends StatelessWidget {
  const DiscountSettingsSection({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final settings = appState.appSettings ?? AppSettings();
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.discount,
                iconColor: Colors.orange.shade600,
                title: 'Discount System',
                subtitle:
                    'Max discount: ${settings.defaultDiscountLimit.toStringAsFixed(1)}%',
                onTap: onOpen,
              ),
              const SettingsDivider(),
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
                      child: Icon(
                        Icons.toggle_on,
                        color: Colors.teal.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Discount Toggle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Allow products to be marked as non-discountable',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
}

class DataManagementSection extends StatelessWidget {
  const DataManagementSection({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SettingsTile(
        icon: Icons.storage,
        iconColor: Colors.blue.shade600,
        title: 'Data Management',
        subtitle: 'Export, import or clear your data',
        onTap: onOpen,
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.onHelp});
  final VoidCallback onHelp;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const SettingsTile(
            icon: Icons.info,
            iconColor: Colors.blue,
            title: 'App Version',
            subtitle: appVersionString,
            showArrow: false,
          ),
          const SettingsDivider(),
          SettingsTile(
            icon: Icons.help,
            iconColor: Colors.green,
            title: 'Help & Support',
            subtitle: 'Get help with using Rufko',
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}
