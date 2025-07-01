import 'package:flutter/foundation.dart';
import '../../../core/services/storage/file_service.dart';
import '../app_configuration_provider.dart';

class AppConfigurationManager extends ChangeNotifier {
  final AppConfigurationProvider configState;

  bool _isLoading = false;
  String _loadingMessage = '';

  AppConfigurationManager({AppConfigurationProvider? configProvider})
      : configState = configProvider ?? AppConfigurationProvider() {
    configState.addListener(notifyListeners);
  }

  // Getters
  dynamic get appSettings => configState.appSettings;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  void setLoading(bool loading, [String message = '']) {
    if (_isLoading == loading && _loadingMessage == message) return;
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  // Configuration Operations
  Future<void> loadAppSettings() async {
    await configState.loadAppSettings();
  }

  Future<void> updateAppSettings(dynamic settings) async {
    await configState.updateAppSettings(settings);
  }

  Future<String?> pickAndSaveCompanyLogo(dynamic settings) async {
    return configState.pickAndSaveCompanyLogo(settings);
  }

  Future<void> removeCompanyLogo(dynamic settings) async {
    await configState.removeCompanyLogo(settings);
  }

  // Tax Operations
  double? detectTaxRate({String? city, String? stateAbbreviation, String? zipCode}) {
    return configState.detectTaxRate(
      city: city,
      stateAbbreviation: stateAbbreviation,
      zipCode: zipCode,
    );
  }

  Future<void> saveZipCodeTaxRate(String zipCode, double rate) async {
    await configState.saveZipCodeTaxRate(zipCode, rate);
  }

  Future<void> saveStateTaxRate(String stateAbbreviation, double rate) async {
    await configState.saveStateTaxRate(stateAbbreviation, rate);
  }

  bool get isTaxDatabaseAvailable => configState.isTaxDatabaseAvailable;
  String get taxDatabaseStatus => configState.taxDatabaseStatus;

  // Data Management Operations
  Future<String> exportAllDataToFile(Map<String, dynamic> Function() getExportData) async {
    setLoading(true, 'Exporting data...');
    try {
      final data = getExportData();
      final filePath = await FileService.instance.saveExportedData(data);
      return filePath;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> pickBackupData() async {
    return await FileService.instance.pickAndReadBackupFile();
  }

  Future<void> importAllDataFromFile(Map<String, dynamic> data, Function loadAllData) async {
    setLoading(true, 'Importing data...');
    try {
      // Import logic would be handled by the main provider
      await loadAllData();
    } finally {
      setLoading(false);
    }
  }

  Future<void> clearAllData(Function loadAllData) async {
    await importAllDataFromFile({}, loadAllData);
  }
}