import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class CustomerFilterController {
  CustomerFilterController(this.appState);

  final AppStateProvider appState;

  List<Customer> getFilteredCustomers({
    required String filter,
    required String searchQuery,
    required String sortBy,
    required bool sortAscending,
  }) {
    List<Customer> customers = searchQuery.isEmpty
        ? appState.customers
        : appState.searchCustomers(searchQuery);

    switch (filter) {
      case 'Recent':
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        customers =
            customers.where((c) => c.createdAt.isAfter(thirtyDaysAgo)).toList();
        break;
      case 'Active':
        customers = customers.where((c) {
          final hasRecentQuotes = appState.simplifiedQuotes.any((q) =>
              q.customerId == c.id &&
              q.createdAt
                  .isAfter(DateTime.now().subtract(const Duration(days: 90))));
          final hasRecentCommunication = c.communicationHistory.isNotEmpty &&
              c.updatedAt
                  .isAfter(DateTime.now().subtract(const Duration(days: 30)));
          return hasRecentQuotes || hasRecentCommunication;
        }).toList();
        break;
      case 'Inactive':
        customers = customers.where((c) {
          final hasRecentQuotes = appState.simplifiedQuotes.any((q) =>
              q.customerId == c.id &&
              q.createdAt
                  .isAfter(DateTime.now().subtract(const Duration(days: 90))));
          final hasRecentCommunication = c.updatedAt
              .isAfter(DateTime.now().subtract(const Duration(days: 30)));
          return !hasRecentQuotes && !hasRecentCommunication;
        }).toList();
        break;
    }

    customers.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'activity':
          DateTime aActivity = a.updatedAt;
          var quotesA = appState.getSimplifiedQuotesForCustomer(a.id);
          if (quotesA.isNotEmpty) {
            quotesA.sort((q1, q2) => q2.createdAt.compareTo(q1.createdAt));
            if (quotesA.first.createdAt.isAfter(aActivity)) {
              aActivity = quotesA.first.createdAt;
            }
          }
          DateTime bActivity = b.updatedAt;
          var quotesB = appState.getSimplifiedQuotesForCustomer(b.id);
          if (quotesB.isNotEmpty) {
            quotesB.sort((q1, q2) => q2.createdAt.compareTo(q1.createdAt));
            if (quotesB.first.createdAt.isAfter(bActivity)) {
              bActivity = quotesB.first.createdAt;
            }
          }
          comparison = aActivity.compareTo(bActivity);
          break;
        default:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return sortAscending ? comparison : -comparison;
    });

    return customers;
  }
}
