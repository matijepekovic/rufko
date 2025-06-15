import 'package:flutter/foundation.dart';

import '../models/settings/app_settings.dart';
import '../../core/services/database/database_service.dart';
import '../../core/services/storage/file_service.dart';
import '../../core/services/external/tax_service.dart';

/// Provider responsible for application-wide configuration such as
/// [AppSettings], tax rates and company branding.
class AppConfigurationProvider extends ChangeNotifier {
  final DatabaseService _db;
  AppSettings? _appSettings;

  AppConfigurationProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  AppSettings? get appSettings => _appSettings;

  /// Loads persisted [AppSettings] from the database.
  Future<void> loadAppSettings() async {
    try {
      _appSettings = await _db.getAppSettings();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading app settings: $e');
    }
  }

  /// Persists updated [settings] and notifies listeners.
  Future<void> updateAppSettings(AppSettings settings) async {
    try {
      await _db.saveAppSettings(settings);
      _appSettings = settings;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating app settings: $e');
    }
  }

  /// Prompts the user to pick a company logo and saves it.
  Future<String?> pickAndSaveCompanyLogo(AppSettings settings) async {
    final newPath = await FileService.instance.pickAndSaveCompanyLogo();
    if (newPath != null) {
      settings.updateCompanyLogo(newPath);
      await updateAppSettings(settings);
    }
    return newPath;
  }

  /// Removes the current company logo if present.
  Future<void> removeCompanyLogo(AppSettings settings) async {
    settings.updateCompanyLogo(null);
    await updateAppSettings(settings);
  }

  /// Detects a tax rate based on the provided address information.
  double? detectTaxRate({
    String? city,
    String? stateAbbreviation,
    String? zipCode,
  }) {
    return TaxService.getTaxRateByAddress(
      city: city,
      stateAbbreviation: stateAbbreviation,
      zipCode: zipCode,
    );
  }

  /// Saves a sales tax [rate] for the specified [zipCode].
  Future<void> saveZipCodeTaxRate(String zipCode, double rate) async {
    await TaxService.setZipCodeRate(zipCode, rate);
  }

  /// Saves a state sales tax [rate] for the given [stateAbbreviation].
  Future<void> saveStateTaxRate(String stateAbbreviation, double rate) async {
    await TaxService.setStateRate(stateAbbreviation, rate);
  }

  /// Whether the tax database is available on this platform.
  bool get isTaxDatabaseAvailable => TaxService.isDatabaseAvailable;

  /// Human readable status of the tax database.
  String get taxDatabaseStatus => TaxService.getDatabaseStatus();
}
