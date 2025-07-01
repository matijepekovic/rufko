import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/settings/discount_settings_service.dart';
import '../screens/discount_settings_dialog.dart';

/// Controller for showing and saving discount settings.
class DiscountSettingsController {
  DiscountSettingsController(this.context)
      : appState = context.read<AppStateProvider>();

  final BuildContext context;
  final AppStateProvider appState;

  AppSettings get currentSettings => appState.appSettings ?? AppSettings();

  void showDiscountDialog() {
    final settings = currentSettings;
    showDialog(
      context: context,
      builder: (c) => DiscountSettingsDialog(
        discountTypes: List.from(settings.discountTypes),
        defaultDiscountLimit: settings.defaultDiscountLimit,
        onSave: (types, limit) {
          // Business logic extracted to service
          DiscountSettingsService.updateDiscountSettings(
            appState: appState,
            settings: settings,
            types: types,
            discountLimit: limit,
          );
          Navigator.pop(c);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discount settings updated!')),
          );
        },
      ),
    );
  }
}