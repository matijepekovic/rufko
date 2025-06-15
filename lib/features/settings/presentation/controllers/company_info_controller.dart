import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller handling loading and saving of company information.
class CompanyInfoController {
  CompanyInfoController({required this.context})
      : appState = context.read<AppStateProvider>(),
        settings = context.read<AppStateProvider>().appSettings ?? AppSettings();

  final BuildContext context;
  final AppStateProvider appState;
  AppSettings settings;

  /// Save updated company info and show a confirmation snackbar.
  void saveInfo({
    required String name,
    required String address,
    required String phone,
    required String email,
  }) {
    settings.updateCompanyInfo(
      name: name.isEmpty ? null : name,
      address: address.isEmpty ? null : address,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
    );
    appState.updateAppSettings(settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company information updated!')),
    );
  }
}
