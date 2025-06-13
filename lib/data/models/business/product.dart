// lib/models/product.dart - ENHANCED WITH 3-TIER SYSTEM + MISSING METHODS

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part '../../generated/product.g.dart';

// Enhanced level pricing with descriptions
@HiveType(typeId: 7)
class ProductLevelPrice extends HiveObject {
  @HiveField(0)
  String levelId;

  @HiveField(1)
  String levelName;

  @HiveField(2)
  double price;

  @HiveField(3)
  String? description;

  @HiveField(4)
  bool isActive;

  ProductLevelPrice({
    required this.levelId,
    required this.levelName,
    required this.price,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'levelName': levelName,
      'price': price,
      'description': description,
      'isActive': isActive,
    };
  }

  factory ProductLevelPrice.fromMap(Map<String, dynamic> map) {
    return ProductLevelPrice(
      levelId: map['levelId'] ?? '',
      levelName: map['levelName'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      description: map['description'],
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  String toString() {
    return 'ProductLevelPrice(levelId: $levelId, name: $levelName, price: $price)';
  }
}

@HiveType(typeId: 1)
class Product extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  late double unitPrice;

  @HiveField(4)
  String unit;

  @HiveField(5)
  String category;

  @HiveField(6)
  String? sku;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  Map<String, double> levelPrices; // DEPRECATED - kept for backward compatibility

  @HiveField(11)
  bool isAddon;

  @HiveField(12)
  bool isDiscountable;

  @HiveField(13)
  List<ProductLevelPrice> enhancedLevelPrices;

  @HiveField(14)
  int maxLevels;

  @HiveField(15)
  String? notes;

  // NEW: 3-Tier System Fields
  @HiveField(16)
  bool isMainDifferentiator; // Sets quote column headers (only one per quote)

  @HiveField(17)
  bool enableLevelPricing; // Has different prices for different situations

  @HiveField(18)
  ProductPricingType pricingType; // mainDifferentiator,  subLeveled, simple

  Product({
    String? id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.unit = 'each',
    this.category = 'Materials',
    this.sku,
    this.isActive = true,
    Map<String, double>? levelPrices,
    this.isAddon = false,
    this.isDiscountable = true,
    List<ProductLevelPrice>? enhancedLevelPrices,
    this.maxLevels = 3,
    this.notes,
    this.isMainDifferentiator = false, // NEW
    this.enableLevelPricing = false, // NEW
    ProductPricingType? pricingType, // NEW
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : levelPrices = levelPrices ?? {},
        enhancedLevelPrices = enhancedLevelPrices ?? [],
        pricingType = pricingType ?? ProductPricingType.simple, // NEW
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();

    // Auto-determine pricing type based on flags
    _updatePricingType();
  }

  // Auto-determine pricing type
  void _updatePricingType() {
    if (isMainDifferentiator) {
      pricingType = ProductPricingType.mainDifferentiator;
    } else if (enableLevelPricing && enhancedLevelPrices.isNotEmpty) {
      pricingType = ProductPricingType.subLeveled;
    } else {
      pricingType = ProductPricingType.simple;
    }
  }

  // Get display name for product type
  String get pricingTypeDisplay {
    switch (pricingType) {
      case ProductPricingType.mainDifferentiator:
        return 'Main Differentiator';
      case ProductPricingType.subLeveled:
        return 'Sub-Leveled Options';
      case ProductPricingType.simple:
        return 'Simple Product';
    }
  }

  // MISSING METHOD 1: Generic getPriceForLevel - backwards compatibility
  double getPriceForLevel(String levelId) {
    // First try enhanced level prices
    if (enhancedLevelPrices.isNotEmpty) {
      final level = enhancedLevelPrices.where((l) => l.levelId == levelId && l.isActive).firstOrNull;
      if (level != null) return level.price;
    }

    // Fallback to legacy levelPrices map
    if (levelPrices.containsKey(levelId)) {
      return levelPrices[levelId]!;
    }

    // Final fallback to base unit price
    return unitPrice;
  }

  // MISSING GETTER: activeLevels - backwards compatibility
  List<ProductLevelPrice> get activeLevels {
    return enhancedLevelPrices.where((level) => level.isActive).toList();
  }

  // Get price for main differentiator level (Builder/Homeowner/Platinum)
  double getPriceForMainLevel(String mainLevelId) {
    if (!isMainDifferentiator) return unitPrice;

    final level = enhancedLevelPrices.where((l) => l.levelId == mainLevelId && l.isActive).firstOrNull;
    return level?.price ?? unitPrice;
  }

  // Get price for sub-level (mesh/no-mesh, etc.)
  double getPriceForSubLevel(String subLevelId) {
    if (pricingType != ProductPricingType. subLeveled) return unitPrice;

    final level = enhancedLevelPrices.where((l) => l.levelId == subLevelId && l.isActive).firstOrNull;
    return level?.price ?? unitPrice;
  }

  // Get all available sub-levels for this product
  List<ProductLevelPrice> get availableSubLevels {
    if (pricingType != ProductPricingType. subLeveled) return [];
    return enhancedLevelPrices.where((l) => l.isActive).toList();
  }

  // Get all available main levels for this product
  List<ProductLevelPrice> get availableMainLevels {
    if (pricingType != ProductPricingType.mainDifferentiator) return [];
    return enhancedLevelPrices.where((l) => l.isActive).toList();
  }

  // UPDATED: Update product info with new flags
  void updateInfo({
    String? name,
    String? description,
    double? unitPrice,
    String? unit,
    String? category,
    String? sku,
    bool? isActive,
    Map<String, double>? levelPrices,
    bool? isAddon,
    bool? isDiscountable,
    int? maxLevels,
    String? notes,
    bool? isMainDifferentiator, // NEW
    bool? enableLevelPricing, // NEW
  }) {
    if (name != null) this.name = name;
    if (description != null) this.description = description;
    if (unitPrice != null) {
      this.unitPrice = unitPrice;
      _updateLevelPricesProportionally(unitPrice);
    }
    if (unit != null) this.unit = unit;
    if (category != null) this.category = category;
    if (sku != null) this.sku = sku;
    if (isActive != null) this.isActive = isActive;
    if (levelPrices != null) this.levelPrices = levelPrices;
    if (isAddon != null) this.isAddon = isAddon;
    if (isDiscountable != null) this.isDiscountable = isDiscountable;
    if (maxLevels != null) this.maxLevels = maxLevels;
    if (notes != null) this.notes = notes;

    // NEW: Update 3-tier system flags
    if (isMainDifferentiator != null) this.isMainDifferentiator = isMainDifferentiator;
    if (enableLevelPricing != null) this.enableLevelPricing = enableLevelPricing;

    _updatePricingType(); // Recalculate pricing type
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Helper to update level prices when base price changes
  void _updateLevelPricesProportionally(double newBasePrice) {
    if (enhancedLevelPrices.isEmpty) return;

    final oldBasePrice = unitPrice;
    if (oldBasePrice == 0) return;

    final ratio = newBasePrice / oldBasePrice;
    for (final level in enhancedLevelPrices) {
      level.price = level.price * ratio;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unitPrice': unitPrice,
      'unit': unit,
      'category': category,
      'sku': sku,
      'isActive': isActive,
      'levelPrices': levelPrices,
      'isAddon': isAddon,
      'isDiscountable': isDiscountable,
      'enhancedLevelPrices': enhancedLevelPrices.map((l) => l.toMap()).toList(),
      'maxLevels': maxLevels,
      'notes': notes,
      'isMainDifferentiator': isMainDifferentiator, // NEW
      'enableLevelPricing': enableLevelPricing, // NEW
      'pricingType': pricingType.toString(), // NEW
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'each',
      category: map['category'] ?? 'Materials',
      sku: map['sku'],
      isActive: map['isActive'] ?? true,
      levelPrices: Map<String, double>.from(map['levelPrices'] ?? {}),
      isAddon: map['isAddon'] ?? false,
      isDiscountable: map['isDiscountable'] ?? true,
      enhancedLevelPrices: (map['enhancedLevelPrices'] as List<dynamic>?)
          ?.map((levelData) => ProductLevelPrice.fromMap(levelData as Map<String, dynamic>))
          .toList() ?? [],
      maxLevels: map['maxLevels'] ?? 3,
      notes: map['notes'],
      isMainDifferentiator: map['isMainDifferentiator'] ?? false, // NEW
      enableLevelPricing: map['enableLevelPricing'] ?? false, // NEW
      pricingType: ProductPricingType.values.firstWhere(
            (type) => type.toString() == map['pricingType'],
        orElse: () => ProductPricingType.simple,
      ), // NEW
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Product(name: $name, type: $pricingTypeDisplay, mainDiff: $isMainDifferentiator, levels: ${enhancedLevelPrices.length})';
  }
}

// NEW: Product pricing type enum
@HiveType(typeId: 19)
enum ProductPricingType {
  @HiveField(0)
  mainDifferentiator, // Sets quote columns (Shingles: Builder/Homeowner/Platinum)

  @HiveField(1)
   subLeveled,        // Independent options (Gutters: mesh/no-mesh)

  @HiveField(2)
  simple              // Same price everywhere (Labor, Nails)
}