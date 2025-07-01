import '../../../data/providers/state/app_state_provider.dart';

/// Service that contains customer list business operations
/// This is extracted from CustomerScreen following the same pattern as CustomerOperationsService
class CustomerListService {
  
  /// EXACT COPY of the data loading logic from the screen
  /// This is the ORIGINAL working code, just moved to a service
  static Future<void> refreshCustomerData(AppStateProvider appState) async {
    // EXACT COPY of the refresh operation that was in the screen
    await appState.loadAllData();
  }

  /// EXACT COPY of the quote count calculation logic from the screen
  /// This is the ORIGINAL working code, just moved to a service
  static int getCustomerQuoteCount({
    required AppStateProvider appState,
    required String customerId,
  }) {
    // EXACT COPY of lines 208-209 from CustomersScreen
    return appState.getSimplifiedQuotesForCustomer(customerId).length;
  }
}