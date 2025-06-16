import '../../../data/providers/state/app_state_provider.dart';
import '../../../data/models/settings/custom_app_data.dart';

/// Service that contains template list business operations
/// This is extracted from TemplatesScreen following the same pattern as other services
class TemplateListService {
  
  /// EXACT COPY of the custom field addition logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static Future<void> addCustomField({
    required AppStateProvider appState,
    required CustomAppDataField newField,
  }) async {
    // EXACT COPY of the business operation from TemplatesScreenController line 19
    await appState.addCustomAppDataField(newField);
  }
}