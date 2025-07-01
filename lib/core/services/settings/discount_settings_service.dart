import '../../../data/providers/state/app_state_provider.dart';
import '../../../data/models/settings/app_settings.dart';

/// Service layer for discount settings business operations
/// Contains pure business logic without UI dependencies
class DiscountSettingsService {
  /// Update discount settings with types and limit
  static void updateDiscountSettings({
    required AppStateProvider appState,
    required AppSettings settings,
    required List<String> types,
    required double discountLimit,
  }) {
    // Business logic copied exactly from controller onSave callback
    settings.updateDiscountSettings(types: types, discountLimit: discountLimit);
    appState.updateAppSettings(settings);
  }
}