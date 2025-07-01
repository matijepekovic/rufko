import '../../../../data/providers/state/app_state_provider.dart';

/// Provides product category helpers.
class ProductCategoryManager {
  ProductCategoryManager(this.appState);

  final AppStateProvider appState;

  List<String> getCategoryTabs() {
    if (appState.appSettings != null &&
        appState.appSettings!.productCategories.isNotEmpty) {
      return ['All', ...appState.appSettings!.productCategories];
    }

    return [
      'All',
      'Materials',
      'Roofing',
      'Gutters',
      'Labor',
      'Other',
    ];
  }
}
