import 'package:flutter/foundation.dart';
import '../models/business/product.dart';

/// Test data for product development and testing
/// This data will be populated during development but removed for production
class ProductTestData {
  static const bool _isTestDataEnabled = kDebugMode;

  /// Generate sample products for testing
  static List<Product> getSampleProducts() {
    if (!_isTestDataEnabled) return [];

    return [
      // Main Differentiator Product (Shingles with 3-tier pricing)
      Product(
        name: "Architectural Shingles",
        description: "High-quality architectural shingles with 30-year warranty",
        unitPrice: 120.0,
        unit: "square",
        category: "Roofing Materials",
        sku: "ARCH-SHING-001",
        isMainDifferentiator: true,
        enableLevelPricing: true,
        hasInventory: true,
        enhancedLevelPrices: [
          ProductLevelPrice(
            levelId: "builder",
            levelName: "Builder Grade",
            price: 120.0,
            description: "Standard quality for budget-conscious customers",
          ),
          ProductLevelPrice(
            levelId: "homeowner",
            levelName: "Homeowner Grade",
            price: 180.0,
            description: "Enhanced quality for homeowner projects",
          ),
          ProductLevelPrice(
            levelId: "platinum",
            levelName: "Platinum Grade",
            price: 250.0,
            description: "Premium quality with extended warranty",
          ),
        ],
      ),

      // Sub-Leveled Product (Gutters with mesh options)
      Product(
        name: "Aluminum Gutters",
        description: "6-inch aluminum gutters with various protection options",
        unitPrice: 8.50,
        unit: "linear foot",
        category: "Gutters & Downspouts",
        sku: "ALU-GUTT-001",
        enableLevelPricing: true,
        hasInventory: true,
        enhancedLevelPrices: [
          ProductLevelPrice(
            levelId: "standard",
            levelName: "Standard Gutters",
            price: 8.50,
            description: "Basic aluminum gutters without protection",
          ),
          ProductLevelPrice(
            levelId: "mesh",
            levelName: "With Mesh Protection",
            price: 12.00,
            description: "Gutters with leaf and debris protection mesh",
          ),
          ProductLevelPrice(
            levelId: "premium_guard",
            levelName: "Premium Guard System",
            price: 18.50,
            description: "Advanced protection with micro-mesh technology",
          ),
        ],
      ),

      // Simple Products
      Product(
        name: "Roofing Nails",
        description: "1.25-inch galvanized roofing nails",
        unitPrice: 45.00,
        unit: "50lb box",
        category: "Hardware",
        sku: "NAIL-ROOF-125",
        hasInventory: true,
      ),

      Product(
        name: "Labor - Installation",
        description: "Professional roofing installation labor",
        unitPrice: 75.00,
        unit: "hour",
        category: "Labor",
        sku: "LAB-INST-001",
      ),

      // Addon Products
      Product(
        name: "Ridge Vent",
        description: "Continuous ridge ventilation system",
        unitPrice: 4.50,
        unit: "linear foot",
        category: "Ventilation",
        sku: "VENT-RIDGE-001",
        isAddon: true,
        hasInventory: true,
      ),

      Product(
        name: "Soffit Vents",
        description: "Under-eave ventilation panels",
        unitPrice: 12.00,
        unit: "each",
        category: "Ventilation",
        sku: "VENT-SOFF-001",
        isAddon: true,
        hasInventory: true,
      ),

      // More roofing materials
      Product(
        name: "Ice & Water Shield",
        description: "Self-adhering waterproof membrane",
        unitPrice: 85.00,
        unit: "roll",
        category: "Underlayment",
        sku: "ICE-WATER-001",
        hasInventory: true,
      ),

      Product(
        name: "Roofing Felt",
        description: "15lb asphalt saturated felt paper",
        unitPrice: 35.00,
        unit: "roll",
        category: "Underlayment",
        sku: "FELT-15LB-001",
        hasInventory: true,
      ),

      Product(
        name: "Flashing - Step",
        description: "Galvanized steel step flashing",
        unitPrice: 3.25,
        unit: "piece",
        category: "Flashing",
        sku: "FLASH-STEP-001",
        hasInventory: true,
      ),

      Product(
        name: "Drip Edge",
        description: "Aluminum drip edge trim",
        unitPrice: 2.75,
        unit: "linear foot",
        category: "Trim",
        sku: "DRIP-EDGE-001",
        hasInventory: true,
      ),

      // Premium products with level pricing
      Product(
        name: "Metal Roofing Panels",
        description: "Standing seam metal roofing with various finishes",
        unitPrice: 350.0,
        unit: "square",
        category: "Metal Roofing",
        sku: "METAL-PANEL-001",
        isMainDifferentiator: true,
        enableLevelPricing: true,
        enhancedLevelPrices: [
          ProductLevelPrice(
            levelId: "galvalume",
            levelName: "Galvalume Finish",
            price: 350.0,
            description: "Standard galvalume coating",
          ),
          ProductLevelPrice(
            levelId: "painted",
            levelName: "Painted Finish",
            price: 425.0,
            description: "Color-coated finish with 25-year warranty",
          ),
          ProductLevelPrice(
            levelId: "premium_coat",
            levelName: "Premium Coating",
            price: 550.0,
            description: "PVDF coating with 35-year warranty",
          ),
        ],
      ),

      // Insulation products
      Product(
        name: "Attic Insulation",
        description: "R-38 blown-in fiberglass insulation",
        unitPrice: 1.25,
        unit: "square foot",
        category: "Insulation",
        sku: "INSUL-R38-001",
        isAddon: true,
      ),

      // Chimney and specialty items
      Product(
        name: "Chimney Cap",
        description: "Stainless steel chimney cap with spark arrestor",
        unitPrice: 185.00,
        unit: "each",
        category: "Chimney",
        sku: "CHIM-CAP-001",
        isAddon: true,
        hasInventory: true,
      ),

      Product(
        name: "Skylight Installation",
        description: "Professional skylight installation with flashing kit",
        unitPrice: 450.00,
        unit: "each",
        category: "Skylights",
        sku: "SKY-INST-001",
        isAddon: true,
      ),

      // Gutter accessories
      Product(
        name: "Downspouts",
        description: "Aluminum downspouts with elbows",
        unitPrice: 6.50,
        unit: "linear foot",
        category: "Gutters & Downspouts",
        sku: "DOWN-SPOUT-001",
        hasInventory: true,
      ),

      // Emergency repair products
      Product(
        name: "Tarp - Emergency Cover",
        description: "Heavy-duty blue tarp for emergency weather protection",
        unitPrice: 85.00,
        unit: "each",
        category: "Emergency Repairs",
        sku: "TARP-EMERG-001",
        hasInventory: true,
        notes: "Keep in stock for emergency calls",
      ),

      // Cleanup and disposal
      Product(
        name: "Debris Removal",
        description: "Cleanup and disposal of old roofing materials",
        unitPrice: 125.00,
        unit: "ton",
        category: "Cleanup",
        sku: "CLEANUP-001",
        isAddon: true,
      ),

      // Premium service addon
      Product(
        name: "Extended Warranty",
        description: "Additional 10-year warranty coverage",
        unitPrice: 500.00,
        unit: "per project",
        category: "Services",
        sku: "WARR-EXT-001",
        isAddon: true,
        isDiscountable: false,
        notes: "Non-discountable premium service",
      ),
    ];
  }

  /// Get products for specific testing scenarios
  static List<Product> getProductsForScenario(String scenario) {
    if (!_isTestDataEnabled) return [];

    final allProducts = getSampleProducts();
    
    switch (scenario) {
      case 'main_differentiators':
        return allProducts.where((p) => p.isMainDifferentiator).toList();
      case 'addon_products':
        return allProducts.where((p) => p.isAddon).toList();
      case 'inventory_products':
        return allProducts.where((p) => p.hasInventory).toList();
      case 'labor_items':
        return allProducts.where((p) => p.category == 'Labor').toList();
      case 'roofing_materials':
        return allProducts.where((p) => 
          p.category == 'Roofing Materials' || 
          p.category == 'Underlayment' ||
          p.category == 'Metal Roofing'
        ).toList();
      case 'gutter_system':
        return allProducts.where((p) => 
          p.category == 'Gutters & Downspouts'
        ).toList();
      case 'emergency_items':
        return allProducts.where((p) => 
          p.category == 'Emergency Repairs'
        ).toList();
      default:
        return allProducts;
    }
  }

  /// Create a single test product with specific attributes
  static Product createTestProduct({
    String? name,
    String? category,
    double? price,
    bool isMainDifferentiator = false,
    bool isAddon = false,
    bool hasInventory = false,
    bool hasLevelPricing = false,
  }) {
    if (!_isTestDataEnabled) {
      return Product(name: "Test Product", unitPrice: 10.0);
    }

    final testProduct = Product(
      name: name ?? "Test Product ${DateTime.now().millisecondsSinceEpoch}",
      description: "Test product for development purposes",
      unitPrice: price ?? 50.0,
      unit: "each",
      category: category ?? "Test Category",
      sku: "TEST-${DateTime.now().millisecondsSinceEpoch}",
      isMainDifferentiator: isMainDifferentiator,
      isAddon: isAddon,
      hasInventory: hasInventory,
      enableLevelPricing: hasLevelPricing,
      notes: "Test product for development only",
    );

    // Add level prices if requested
    if (hasLevelPricing) {
      testProduct.enhancedLevelPrices.addAll([
        ProductLevelPrice(
          levelId: "basic",
          levelName: "Basic Level",
          price: price ?? 50.0,
          description: "Basic test level",
        ),
        ProductLevelPrice(
          levelId: "premium",
          levelName: "Premium Level",
          price: (price ?? 50.0) * 1.5,
          description: "Premium test level",
        ),
      ]);
    }

    return testProduct;
  }

  /// Get products by category for testing
  static Map<String, List<Product>> getProductsByCategory() {
    if (!_isTestDataEnabled) return {};

    final allProducts = getSampleProducts();
    final Map<String, List<Product>> productsByCategory = {};

    for (final product in allProducts) {
      productsByCategory.putIfAbsent(product.category, () => []);
      productsByCategory[product.category]!.add(product);
    }

    return productsByCategory;
  }

  /// Get all available categories
  static List<String> getAvailableCategories() {
    if (!_isTestDataEnabled) return [];

    return getSampleProducts()
        .map((p) => p.category)
        .toSet()
        .toList()
        ..sort();
  }
}