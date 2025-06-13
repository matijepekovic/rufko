import '../../../../data/models/business/product.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Handles filtering, searching and sorting of [Product] records.
class ProductFilterController {
  ProductFilterController(this.appState);

  final AppStateProvider appState;

  List<Product> getFilteredProducts({
    required String category,
    required String searchQuery,
    required String sortBy,
    required bool sortAscending,
  }) {
    List<Product> products = searchQuery.isEmpty
        ? appState.products
        : _getSearchResults(searchQuery);

    if (category != 'All') {
      products = products
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    products.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'category':
          comparison =
              a.category.toLowerCase().compareTo(b.category.toLowerCase());
          break;
        case 'price':
          comparison = a.unitPrice.compareTo(b.unitPrice);
          break;
        default:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return sortAscending ? comparison : -comparison;
    });

    return products;
  }

  List<Product> _getSearchResults(String query) {
    final lowerQuery = query.toLowerCase();
    return appState.products
        .where((product) =>
            product.name.toLowerCase().contains(lowerQuery) ||
            (product.description?.toLowerCase().contains(lowerQuery) ??
                false) ||
            product.category.toLowerCase().contains(lowerQuery) ||
            (product.sku?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }
}
