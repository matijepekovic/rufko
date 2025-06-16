import '../../../data/providers/state/app_state_provider.dart';

/// Service that contains product list business operations
/// This is extracted from ProductsScreen following the same pattern as CustomerListService
class ProductListService {
  
  /// EXACT COPY of the data loading logic from the screen
  /// This is the ORIGINAL working code, just moved to a service
  static Future<void> refreshProductData(AppStateProvider appState) async {
    // EXACT COPY of the refresh operation that was in the screen (line 100, 191)
    await appState.loadAllData();
  }
}