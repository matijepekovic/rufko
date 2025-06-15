import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Provides filtering helpers for [SimplifiedMultiLevelQuote] records.
class QuoteFilterController {
  QuoteFilterController(this.appState);

  final AppStateProvider appState;

  List<SimplifiedMultiLevelQuote> getFilteredQuotes({
    required String status,
    required String searchQuery,
  }) {
    List<SimplifiedMultiLevelQuote> quotes = appState.simplifiedQuotes;

    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      quotes = quotes.where((quote) {
        final customer = appState.customers.firstWhere(
          (c) => c.id == quote.customerId,
          orElse: () => Customer(name: ''),
        );
        return quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
            customer.name.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (status != 'All') {
      if (status == 'Expired') {
        quotes = quotes.where((q) => q.isExpired).toList();
      } else {
        quotes = quotes
            .where((q) => q.status.toLowerCase() == status.toLowerCase())
            .toList();
      }
    }

    // TODO: implement sorting when requirements are defined

    return quotes;
  }
}
