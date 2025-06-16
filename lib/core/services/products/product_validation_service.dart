import '../../../data/models/business/product.dart';

/// Service layer for product validation operations
/// Contains pure business logic without UI dependencies
class ProductValidationService {
  /// Validate levels data
  /// Business logic copied exactly from ProductFormController.validateLevels()
  static bool validateLevels({
    required ProductPricingType pricingType,
    required Map<String, String> levelNames,
    required List<String> currentLevelKeys,
  }) {
    if (pricingType == ProductPricingType.simple) {
      return true;
    }

    for (final levelKey in currentLevelKeys) {
      final levelName = levelNames[levelKey];
      if (levelName?.trim().isEmpty ?? true) {
        return false;
      }
    }
    return true;
  }

  /// Validate complete product form data
  /// Business logic for form validation rules
  static bool validateProductData({
    required String name,
    required String basePrice,
    required ProductPricingType pricingType,
    required Map<String, String> levelNames,
    required List<String> currentLevelKeys,
  }) {
    // Basic field validation
    if (name.trim().isEmpty) {
      return false;
    }

    // Price validation
    if (double.tryParse(basePrice) == null || double.parse(basePrice) < 0) {
      return false;
    }

    // Level validation if applicable
    if (pricingType != ProductPricingType.simple) {
      return validateLevels(
        pricingType: pricingType,
        levelNames: levelNames,
        currentLevelKeys: currentLevelKeys,
      );
    }

    return true;
  }
}