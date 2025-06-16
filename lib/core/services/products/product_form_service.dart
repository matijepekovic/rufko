import '../../../data/models/business/product.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Service layer for product form operations
/// Contains pure business logic without UI dependencies
class ProductFormService {
  /// Initialize main differentiator levels from app settings
  /// Business logic copied exactly from ProductFormController._initializeMainDifferentiatorLevels()
  static List<String> initializeMainDifferentiatorLevels(AppStateProvider appState) {
    final defaultLevels = appState.appSettings?.defaultQuoteLevelNames ?? 
                         ['Builder', 'Standard', 'Premium'];
    return defaultLevels;
  }

  /// Initialize sub-leveled levels with defaults
  /// Business logic copied exactly from ProductFormController._initializeSubLeveledLevels()
  static List<String> initializeSubLeveledLevels() {
    const defaultSubLevels = ['Basic', 'Premium'];
    return defaultSubLevels;
  }

  /// Check if level can be removed
  /// Business logic copied exactly from ProductFormController.canRemoveLevel()
  static bool canRemoveLevel(ProductPricingType pricingType, int currentLevelsCount) {
    switch (pricingType) {
      case ProductPricingType.mainDifferentiator:
        return currentLevelsCount > 2;
      case ProductPricingType.subLeveled:
        return currentLevelsCount > 2;
      case ProductPricingType.simple:
        return false;
    }
  }

  /// Check if level can be added
  /// Business logic copied exactly from ProductFormController.canAddLevel()
  static bool canAddLevel(ProductPricingType pricingType, int currentLevelsCount) {
    switch (pricingType) {
      case ProductPricingType.mainDifferentiator:
        return currentLevelsCount < 6;
      case ProductPricingType.subLeveled:
        return currentLevelsCount < 4;
      case ProductPricingType.simple:
        return false;
    }
  }

  /// Get pricing type description
  /// Business logic copied exactly from ProductFormController.getPricingTypeDescription()
  static String getPricingTypeDescription(ProductPricingType pricingType) {
    switch (pricingType) {
      case ProductPricingType.mainDifferentiator:
        return 'Sets quote column headers (Builder/Standard/Premium)';
      case ProductPricingType.subLeveled:
        return 'Independent customer choices (Basic vs Mesh Gutters)';
      case ProductPricingType.simple:
        return 'Same price everywhere';
    }
  }
}