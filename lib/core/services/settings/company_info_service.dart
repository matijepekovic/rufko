import '../../../data/models/settings/app_settings.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Service layer for company information operations
/// Contains pure business logic without UI dependencies
class CompanyInfoService {
  /// Save company information to settings
  static void saveCompanyInfo({
    required AppStateProvider appState,
    required AppSettings settings,
    required String name,
    required String address,
    required String phone,
    required String email,
  }) {
    // Business logic copied exactly from controller saveInfo method
    settings.updateCompanyInfo(
      name: name.isEmpty ? null : name,
      address: address.isEmpty ? null : address,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
    );
    appState.updateAppSettings(settings);
  }
}