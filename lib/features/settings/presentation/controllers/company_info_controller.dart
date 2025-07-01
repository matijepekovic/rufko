import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/settings/company_info_service.dart';

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
    // Business logic extracted to service
    CompanyInfoService.saveCompanyInfo(
      appState: appState,
      settings: settings,
      name: name,
      address: address,
      phone: phone,
      email: email,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company information updated!')),
    );
  }
}
