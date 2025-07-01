import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/quote/quote_service.dart';

/// Provides filtering helpers for [SimplifiedMultiLevelQuote] records.
class QuoteFilterController {
  QuoteFilterController(this.appState) : _service = QuoteService();

  final AppStateProvider appState;
  final QuoteService _service;

  // Search state management (business logic)
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Search logic methods
  void updateSearch(String query) {
    _searchQuery = query;
  }

  void clearSearch() {
    _searchQuery = '';
  }

  // Filter selection state management (business logic)
  String _selectedStatus = 'All';
  String get selectedStatus => _selectedStatus;

  // Filter selection method
  void selectStatus(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
    }
  }

  // Get available status options
  List<String> getStatusOptions() {
    return ['All', 'Draft', 'Sent', 'Accepted', 'Declined', 'Expired'];
  }

  // Reset status filter to default
  void resetStatus() {
    _selectedStatus = 'All';
  }

  // Sorting state management (business logic)
  String _sortBy = 'date_desc';
  bool _sortAscending = false;
  
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  
  // Sorting methods
  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
  }
  
  List<String> getSortOptions() {
    return ['date', 'amount', 'customer', 'status'];
  }

  List<SimplifiedMultiLevelQuote> getFilteredQuotes() {
    List<SimplifiedMultiLevelQuote> quotes = appState.simplifiedQuotes;

    // Apply search filter using internal _searchQuery
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      quotes = quotes.where((quote) {
        final customer = appState.customers.firstWhere(
          (c) => c.id == quote.customerId,
          orElse: () => Customer(name: ''),
        );
        return quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
            customer.name.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply status filter using internal _selectedStatus
    if (_selectedStatus != 'All') {
      if (_selectedStatus == 'Expired') {
        quotes = quotes.where((q) => _service.isQuoteExpired(q)).toList();
      } else {
        quotes = quotes
            .where((q) => q.status.toLowerCase() == _selectedStatus.toLowerCase())
            .toList();
      }
    }

    // Apply sorting
    quotes = _applySorting(quotes);

    return quotes;
  }

  List<SimplifiedMultiLevelQuote> _applySorting(List<SimplifiedMultiLevelQuote> quotes) {
    switch (_sortBy) {
      case 'date':
        quotes.sort((a, b) {
          final comparison = a.createdAt.compareTo(b.createdAt);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'amount':
        quotes.sort((a, b) {
          final aTotal = a.levels.isNotEmpty ? a.getDisplayTotalForLevel(a.levels.first.id) : 0.0;
          final bTotal = b.levels.isNotEmpty ? b.getDisplayTotalForLevel(b.levels.first.id) : 0.0;
          final comparison = aTotal.compareTo(bTotal);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'customer':
        quotes.sort((a, b) {
          final aCustomer = appState.customers.firstWhere(
            (c) => c.id == a.customerId,
            orElse: () => Customer(name: ''),
          );
          final bCustomer = appState.customers.firstWhere(
            (c) => c.id == b.customerId,
            orElse: () => Customer(name: ''),
          );
          final comparison = aCustomer.name.toLowerCase().compareTo(bCustomer.name.toLowerCase());
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'status':
        quotes.sort((a, b) {
          final comparison = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          return _sortAscending ? comparison : -comparison;
        });
        break;
      default:
        // Default to date descending
        quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return quotes;
  }
}
