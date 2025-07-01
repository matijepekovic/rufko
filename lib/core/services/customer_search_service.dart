import '../../data/models/business/customer.dart';

class CustomerSearchService {
  // Basic search algorithm
  static List<Customer> searchCustomers(
    List<Customer> customers, 
    String query,
  ) {
    if (query.isEmpty) return customers;

    final normalizedQuery = query.toLowerCase().trim();
    
    return customers.where((customer) {
      return _matchesSearchCriteria(customer, normalizedQuery);
    }).toList();
  }

  // Advanced search with multiple terms
  static List<Customer> advancedSearch(
    List<Customer> customers,
    String query,
  ) {
    if (query.isEmpty) return customers;

    final searchTerms = query.toLowerCase().trim().split(' ')
        .where((term) => term.isNotEmpty)
        .toList();

    if (searchTerms.isEmpty) return customers;

    return customers.where((customer) {
      // All terms must match somewhere in the customer data
      return searchTerms.every((term) => _matchesSearchCriteria(customer, term));
    }).toList();
  }

  // Fuzzy search implementation (simple Levenshtein-based)
  static List<Customer> fuzzySearch(
    List<Customer> customers,
    String query, {
    int maxDistance = 2,
  }) {
    if (query.isEmpty) return customers;

    final normalizedQuery = query.toLowerCase().trim();
    final results = <Customer>[];

    for (final customer in customers) {
      if (_fuzzyMatchesCustomer(customer, normalizedQuery, maxDistance)) {
        results.add(customer);
      }
    }

    return results;
  }

  // Check if customer matches search criteria
  static bool _matchesSearchCriteria(Customer customer, String term) {
    // Name
    if (customer.name.toLowerCase().contains(term)) return true;
    
    // Phone (remove formatting for better matching)
    if (customer.phone != null) {
      final cleanPhone = customer.phone!.replaceAll(RegExp(r'[^\d]'), '');
      final cleanTerm = term.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.contains(cleanTerm)) return true;
    }
    
    // Email
    if (customer.email?.toLowerCase().contains(term) == true) return true;
    
    // Address components
    if (customer.streetAddress?.toLowerCase().contains(term) == true) return true;
    if (customer.city?.toLowerCase().contains(term) == true) return true;
    if (customer.stateAbbreviation?.toLowerCase().contains(term) == true) return true;
    if (customer.zipCode?.contains(term) == true) return true;
    
    return false;
  }

  // Fuzzy matching for customer
  static bool _fuzzyMatchesCustomer(Customer customer, String query, int maxDistance) {
    // Check name with fuzzy matching
    if (_levenshteinDistance(customer.name.toLowerCase(), query) <= maxDistance) {
      return true;
    }

    // Check email domain fuzzy matching
    if (customer.email != null) {
      final emailParts = customer.email!.toLowerCase().split('@');
      if (emailParts.isNotEmpty && 
          _levenshteinDistance(emailParts[0], query) <= maxDistance) {
        return true;
      }
    }

    // Check city fuzzy matching
    if (customer.city != null && 
        _levenshteinDistance(customer.city!.toLowerCase(), query) <= maxDistance) {
      return true;
    }

    return false;
  }

  // Simple Levenshtein distance calculation
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    // Fill the matrix
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // Search with scoring for relevance ranking
  static List<CustomerSearchResult> searchWithRelevance(
    List<Customer> customers,
    String query,
  ) {
    if (query.isEmpty) {
      return customers.map((c) => CustomerSearchResult(customer: c, score: 0)).toList();
    }

    final normalizedQuery = query.toLowerCase().trim();
    final results = <CustomerSearchResult>[];

    for (final customer in customers) {
      final score = _calculateRelevanceScore(customer, normalizedQuery);
      if (score > 0) {
        results.add(CustomerSearchResult(customer: customer, score: score));
      }
    }

    // Sort by score (higher is better)
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  // Calculate relevance score for a customer
  static int _calculateRelevanceScore(Customer customer, String query) {
    int score = 0;

    // Exact name match gets highest score
    if (customer.name.toLowerCase() == query) {
      score += 100;
    } else if (customer.name.toLowerCase().startsWith(query)) {
      score += 50;
    } else if (customer.name.toLowerCase().contains(query)) {
      score += 25;
    }

    // Phone number matching
    if (customer.phone != null) {
      final cleanPhone = customer.phone!.replaceAll(RegExp(r'[^\d]'), '');
      final cleanQuery = query.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.contains(cleanQuery) && cleanQuery.length >= 3) {
        score += 30;
      }
    }

    // Email matching
    if (customer.email?.toLowerCase().contains(query) == true) {
      score += 20;
    }

    // Address matching
    if (customer.city?.toLowerCase().contains(query) == true) {
      score += 15;
    }

    if (customer.streetAddress?.toLowerCase().contains(query) == true) {
      score += 10;
    }

    return score;
  }
}

// Search result with relevance score
class CustomerSearchResult {
  final Customer customer;
  final int score;

  CustomerSearchResult({
    required this.customer,
    required this.score,
  });
}