import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/dialogs/help_dialog.dart';
import '../../../../shared/widgets/dialogs/premium_feature_dialog.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/settings/app_settings.dart';
import 'company_info_screen.dart';
import 'data_management_screen.dart';
import 'discount_settings_screen.dart';
import '../widgets/settings_section.dart';
import 'category_manager_dialog.dart';
import 'quote_levels_manager_dialog.dart';
import 'units_manager_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('Product Configuration'),
          ProductConfigurationSection(
            onCategories: () => _showCategoriesManager(context),
            onUnits: () => _showUnitsManager(context),
            onQuoteLevels: () => _showQuoteLevelsManager(context),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Company & Business'),
          CompanyAndBusinessSection(
            onCompanyInfo: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyInfoScreen()),
            ),
            onAutomaticTax: () => showAutomaticTaxInfo(context),
            onTwoWayCommunication: () => showTwoWayCommunicationInfo(context),
            onOrganizationProfiles: () => showOrganizationProfilesInfo(context),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Discount Settings'),
          DiscountSettingsSection(
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscountSettingsScreen()),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Data Management'),
          DataManagementSection(
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataManagementScreen()),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('About'),
          AboutSection(onHelp: () => showHelpDialog(context)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static void _showCategoriesManager(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();
    showDialog(
      context: context,
      builder: (context) => CategoryManagerDialog(
        categories: List.from(settings.productCategories),
        onSave: (updated) {
          settings.updateProductCategories(updated);
          appState.updateAppSettings(settings);
        },
      ),
    );
  }

  static void _showUnitsManager(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();
    showDialog(
      context: context,
      builder: (context) => UnitsManagerDialog(
        units: List.from(settings.productUnits),
        defaultUnit: settings.defaultUnit,
        onSave: (units, def) {
          settings.updateProductUnits(units);
          settings.updateDefaultUnit(def);
          appState.updateAppSettings(settings);
        },
      ),
    );
  }

  static void _showQuoteLevelsManager(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();
    showDialog(
      context: context,
      builder: (context) => QuoteLevelsManagerDialog(
        levelNames: List.from(settings.defaultQuoteLevelNames),
        onSave: (levels) {
          settings.updateDefaultQuoteLevelNames(levels);
          appState.updateAppSettings(settings);
        },
      ),
    );
  }
}
