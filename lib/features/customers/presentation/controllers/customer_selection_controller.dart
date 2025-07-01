import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class CustomerSelectionController {
  CustomerSelectionController(this.appState);

  final AppStateProvider appState;

  // Search state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Selection state
  Customer? _selectedCustomer;
  Customer? get selectedCustomer => _selectedCustomer;

  // Update search query and filter customers
  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
  }

  // Select a customer
  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
  }

  // Clear selection
  void clearSelection() {
    _selectedCustomer = null;
  }

  // Get filtered customers based on search query
  List<Customer> getFilteredCustomers() {
    if (_searchQuery.isEmpty) {
      return appState.customers;
    }

    final query = _searchQuery.toLowerCase();
    return appState.customers.where((customer) {
      // Search in name
      if (customer.name.toLowerCase().contains(query)) return true;
      
      // Search in phone
      if (customer.phone?.toLowerCase().contains(query) == true) return true;
      
      // Search in email
      if (customer.email?.toLowerCase().contains(query) == true) return true;
      
      // Search in city
      if (customer.city?.toLowerCase().contains(query) == true) return true;
      
      return false;
    }).toList();
  }

  // Get customers grouped by first letter
  Map<String, List<Customer>> getGroupedCustomers() {
    final filtered = getFilteredCustomers();
    final grouped = <String, List<Customer>>{};

    for (final customer in filtered) {
      final firstLetter = customer.name.isNotEmpty 
          ? customer.name[0].toUpperCase() 
          : '#';
      
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(customer);
    }

    // Sort customers within each group
    for (final group in grouped.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }

  // Get sorted group keys (letters)
  List<String> getGroupKeys() {
    final keys = getGroupedCustomers().keys.toList();
    keys.sort((a, b) {
      // Put '#' at the end
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
    return keys;
  }

  // Check if there are any customers
  bool get hasCustomers => appState.customers.isNotEmpty;

  // Get total customer count
  int get totalCustomerCount => appState.customers.length;

  // Get filtered customer count
  int get filteredCustomerCount => getFilteredCustomers().length;

  // Clear search
  void clearSearch() {
    _searchQuery = '';
  }
}