import 'package:flutter/material.dart';

import '../../../../shared/widgets/dialogs/help_dialog.dart';
import '../../../../shared/widgets/dialogs/premium_feature_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/calculator_settings_section.dart';
import '../controllers/product_configuration_controller.dart';
import 'company_info_screen.dart';
import 'data_management_screen.dart';
import 'discount_settings_screen.dart';

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
            onJobTypes: () => _showJobTypesManager(context),
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
          const SectionHeader('Calculator Settings'),
          CalculatorSettingsSection(),
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
    ProductConfigurationController(context).showCategoriesManager();
  }

  static void _showUnitsManager(BuildContext context) {
    ProductConfigurationController(context).showUnitsManager();
  }

  static void _showQuoteLevelsManager(BuildContext context) {
    ProductConfigurationController(context).showQuoteLevelsManager();
  }

  static void _showJobTypesManager(BuildContext context) {
    ProductConfigurationController(context).showJobTypesManager();
  }
}
