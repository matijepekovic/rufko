import '../../../data/models/business/product.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Result object for product persistence operations
class ProductPersistenceResult {
  final bool isSuccess;
  final String? errorMessage;

  const ProductPersistenceResult({
    required this.isSuccess,
    this.errorMessage,
  });

  factory ProductPersistenceResult.success() {
    return const ProductPersistenceResult(isSuccess: true);
  }

  factory ProductPersistenceResult.error(String message) {
    return ProductPersistenceResult(isSuccess: false, errorMessage: message);
  }
}

/// Service layer for product persistence operations
/// Contains pure business logic without UI dependencies
class ProductPersistenceService {
  /// Update existing product
  /// Business logic copied exactly from ProductFormController._updateExistingProduct()
  static Future<ProductPersistenceResult> updateExistingProduct({
    required Product existingProduct,
    required AppStateProvider appState,
    required String name,
    required String description,
    required double unitPrice,
    required String category,
    required String unit,
    required bool isActive,
    required bool isDiscountable,
    required ProductPricingType pricingType,
    required bool hasInventory, // NEW
    required String? photoPath, // NEW
    required Map<String, String> levelNames,
    required Map<String, String> levelDescriptions,
    required Map<String, String> levelPrices,
    required List<String> currentLevelKeys,
  }) async {
    try {
      existingProduct.updateInfo(
        name: name.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        unitPrice: unitPrice,
        category: category,
        unit: unit,
        isActive: isActive,
        isDiscountable: isDiscountable,
        isMainDifferentiator: pricingType == ProductPricingType.mainDifferentiator,
        enableLevelPricing: pricingType != ProductPricingType.simple,
        hasInventory: hasInventory, // NEW
        photoPath: photoPath, // NEW
      );

      // Update level prices
      updateProductLevels(
        product: existingProduct,
        pricingType: pricingType,
        levelNames: levelNames,
        levelDescriptions: levelDescriptions,
        levelPrices: levelPrices,
        currentLevelKeys: currentLevelKeys,
      );
      
      await appState.updateProduct(existingProduct);
      return ProductPersistenceResult.success();
    } catch (e) {
      return ProductPersistenceResult.error('Failed to update product: $e');
    }
  }

  /// Create new product
  /// Business logic copied exactly from ProductFormController._createNewProduct()
  static Future<ProductPersistenceResult> createNewProduct({
    required AppStateProvider appState,
    required String name,
    required String description,
    required double unitPrice,
    required String category,
    required String unit,
    required bool isActive,
    required bool isDiscountable,
    required ProductPricingType pricingType,
    required bool hasInventory, // NEW
    required String? photoPath, // NEW
    required Map<String, String> levelNames,
    required Map<String, String> levelDescriptions,
    required Map<String, String> levelPrices,
    required List<String> currentLevelKeys,
  }) async {
    try {
      final product = Product(
        name: name.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        unitPrice: unitPrice,
        category: category,
        unit: unit,
        isActive: isActive,
        isDiscountable: isDiscountable,
        isMainDifferentiator: pricingType == ProductPricingType.mainDifferentiator,
        enableLevelPricing: pricingType != ProductPricingType.simple,
        pricingType: pricingType,
        hasInventory: hasInventory, // NEW
        photoPath: photoPath, // NEW
      );

      // Add level prices
      updateProductLevels(
        product: product,
        pricingType: pricingType,
        levelNames: levelNames,
        levelDescriptions: levelDescriptions,
        levelPrices: levelPrices,
        currentLevelKeys: currentLevelKeys,
      );
      
      await appState.addProduct(product);
      return ProductPersistenceResult.success();
    } catch (e) {
      return ProductPersistenceResult.error('Failed to create product: $e');
    }
  }

  /// Update product levels
  /// Business logic copied exactly from ProductFormController._updateProductLevels()
  static void updateProductLevels({
    required Product product,
    required ProductPricingType pricingType,
    required Map<String, String> levelNames,
    required Map<String, String> levelDescriptions,
    required Map<String, String> levelPrices,
    required List<String> currentLevelKeys,
  }) {
    product.enhancedLevelPrices.clear();
    
    if (pricingType != ProductPricingType.simple) {
      for (final levelKey in currentLevelKeys) {
        final levelName = levelNames[levelKey];
        final levelDescription = levelDescriptions[levelKey];
        final levelPrice = levelPrices[levelKey];
        
        if (levelName?.trim().isNotEmpty == true) {
          final productLevelPrice = ProductLevelPrice(
            levelId: levelKey,
            levelName: levelName!.trim(),
            description: levelDescription?.trim().isEmpty == true ? null : levelDescription?.trim(),
            price: levelPrice?.trim().isEmpty == true ? 0.0 : double.tryParse(levelPrice!) ?? 0.0,
          );
          product.enhancedLevelPrices.add(productLevelPrice);
        }
      }
    }
  }
}