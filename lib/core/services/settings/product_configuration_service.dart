import '../../../data/models/settings/app_settings.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Service that contains product configuration business operations
/// This is extracted from ProductConfigurationController following the same pattern
class ProductConfigurationService {
  
  /// EXACT COPY of the categories update logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static Future<void> updateProductCategories({
    required AppStateProvider appState,
    required AppSettings settings,
    required List<String> updatedCategories,
  }) async {
    // EXACT COPY of lines 25-26 from ProductConfigurationController.showCategoriesManager()
    settings.updateProductCategories(updatedCategories);
    await appState.updateAppSettings(settings);
  }

  /// EXACT COPY of the units update logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static Future<void> updateProductUnits({
    required AppStateProvider appState,
    required AppSettings settings,
    required List<String> units,
    required String defaultUnit,
  }) async {
    // EXACT COPY of lines 39-41 from ProductConfigurationController.showUnitsManager()
    settings.updateProductUnits(units);
    settings.updateDefaultUnit(defaultUnit);
    await appState.updateAppSettings(settings);
  }

  /// EXACT COPY of the quote levels update logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static Future<void> updateQuoteLevels({
    required AppStateProvider appState,
    required AppSettings settings,
    required List<String> levels,
  }) async {
    // EXACT COPY of lines 53-54 from ProductConfigurationController.showQuoteLevelsManager()
    settings.updateDefaultQuoteLevelNames(levels);
    await appState.updateAppSettings(settings);
  }

  /// Update job types in app settings
  static Future<void> updateJobTypes({
    required AppStateProvider appState,
    required AppSettings settings,
    required List<String> jobTypes,
  }) async {
    settings.updateJobTypes(jobTypes);
    await appState.updateAppSettings(settings);
  }
}