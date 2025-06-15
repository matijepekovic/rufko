import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'discount_settings_dialog.dart';
import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../widgets/settings_tile.dart';

/// Screen wrapper around [DiscountSettingsDialog].
class DiscountSettingsScreen extends StatelessWidget {
  const DiscountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings ?? AppSettings();
    return Scaffold(
      appBar: AppBar(title: const Text('Discount Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsTile(
            icon: Icons.discount,
            iconColor: Colors.orange.shade600,
            title: 'Discount System',
            subtitle:
                'Max discount: ${settings.defaultDiscountLimit.toStringAsFixed(1)}%',
            onTap: () => _showDialog(context, settings, appState),
          ),
        ],
      ),
    );
  }

  void _showDialog(
      BuildContext context, AppSettings settings, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (c) => DiscountSettingsDialog(
        discountTypes: List.from(settings.discountTypes),
        defaultDiscountLimit: settings.defaultDiscountLimit,
        onSave: (types, limit) {
          settings.updateDiscountSettings(types: types, discountLimit: limit);
          appState.updateAppSettings(settings);
          Navigator.pop(c);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Discount settings updated!')));
        },
      ),
    );
  }
}
