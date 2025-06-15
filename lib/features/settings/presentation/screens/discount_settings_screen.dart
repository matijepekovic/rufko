import 'package:flutter/material.dart';
import '../controllers/discount_settings_controller.dart';
import '../widgets/settings_tile.dart';

/// Screen wrapper around [DiscountSettingsDialog].
class DiscountSettingsScreen extends StatelessWidget {
  const DiscountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DiscountSettingsController(context);
    final settings = controller.currentSettings;
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
            onTap: controller.showDiscountDialog,
          ),
        ],
      ),
    );
  }

  // Deprecated private handler removed in favor of controller
}
