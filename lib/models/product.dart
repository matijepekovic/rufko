// lib/models/product.dart - ENHANCED VERSION

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'product.g.dart';

// NEW: Enhanced level pricing with descriptions
@HiveType(typeId: 7) // New type ID for ProductLevelPrice
class ProductLevelPrice extends HiveObject {
  @HiveField(0)
  String levelId; // e.g., 'basic', 'standard', 'premium'

  @HiveField(1)
  String levelName; // Display name e.g., 'Basic Package', 'Standard Service'

  @HiveField(2)
  double price; // Price for this level

  @HiveField(3)
  String? description; // Description of what this level includes

  @HiveField(4)
  bool isActive; // Whether this level is available

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

@HiveType(typeId: 1) // Keep existing type ID
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

  // NEW FIELDS
  @HiveField(12)
  bool isDiscountable; // Whether this product can have discounts applied

  @HiveField(13)
  List<ProductLevelPrice> enhancedLevelPrices; // Enhanced level pricing with descriptions

  @HiveField(14)
  int maxLevels; // Maximum number of levels this product supports (3, 4, 5, etc.)

  @HiveField(15)
  String? notes; // Internal notes about the product

  Product({
    String? id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.unit = 'each',
    this.category = 'Materials',
    this.sku,
    this.isActive = true,
    Map<String, double>? levelPrices, // DEPRECATED
    this.isAddon = false,
    this.isDiscountable = true, // NEW: Default to discountable
    List<ProductLevelPrice>? enhancedLevelPrices, // NEW
    this.maxLevels = 3, // NEW: Default to 3 levels
    this.notes, // NEW
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : levelPrices = levelPrices ?? {}, // Keep for backward compatibility
        enhancedLevelPrices = enhancedLevelPrices ?? [], // NEW
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();

    // Initialize enhanced level prices if not provided
    if (this.enhancedLevelPrices.isEmpty) {
      _initializeDefaultLevels();
    }
  }

  // Initialize default level pricing structure
  void _initializeDefaultLevels() {
    final defaultLevels = ['basic', 'standard', 'premium'];
    final defaultNames = ['Basic', 'Standard', 'Premium'];
    final multipliers = [0.9, 1.0, 1.2]; // Basic is 10% less, Premium is 20% more

    for (int i = 0; i < maxLevels && i < defaultLevels.length; i++) {
      enhancedLevelPrices.add(ProductLevelPrice(
        levelId: defaultLevels[i],
        levelName: defaultNames[i],
        price: unitPrice * multipliers[i],
        description: 'Default ${defaultNames[i].toLowerCase()} pricing level',
        isActive: true,
      ));
    }
  }

  // Get price for a specific level (backward compatible)
  double getPriceForLevel(String levelId) {
    // First check enhanced level prices
    final enhancedLevel = enhancedLevelPrices.where((l) => l.levelId == levelId && l.isActive).firstOrNull;
    if (enhancedLevel != null) {
      return enhancedLevel.price;
    }

    // Fallback to old system
    return levelPrices[levelId] ?? unitPrice;
  }

  // Get level description
  String? getDescriptionForLevel(String levelId) {
    final enhancedLevel = enhancedLevelPrices.where((l) => l.levelId == levelId && l.isActive).firstOrNull;
    return enhancedLevel?.description;
  }

  // Get level display name
  String getLevelName(String levelId) {
    final enhancedLevel = enhancedLevelPrices.where((l) => l.levelId == levelId && l.isActive).firstOrNull;
    return enhancedLevel?.levelName ?? levelId.toUpperCase();
  }

  // Add or update a level price
  void setLevelPrice({
    required String levelId,
    required String levelName,
    required double price,
    String? description,
    bool isActive = true,
  }) {
    final existingIndex = enhancedLevelPrices.indexWhere((l) => l.levelId == levelId);

    if (existingIndex >= 0) {
      // Update existing
      enhancedLevelPrices[existingIndex] = ProductLevelPrice(
        levelId: levelId,
        levelName: levelName,
        price: price,
        description: description,
        isActive: isActive,
      );
    } else {
      // Add new
      enhancedLevelPrices.add(ProductLevelPrice(
        levelId: levelId,
        levelName: levelName,
        price: price,
        description: description,
        isActive: isActive,
      ));
    }

    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Remove a level price
  void removeLevelPrice(String levelId) {
    enhancedLevelPrices.removeWhere((l) => l.levelId == levelId);
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Get all active levels
  List<ProductLevelPrice> get activeLevels => enhancedLevelPrices.where((l) => l.isActive).toList();

  double calculateTotal(double quantity, {String? levelId}) {
    final price = levelId != null ? getPriceForLevel(levelId) : unitPrice;
    return price * quantity;
  }

  void updateInfo({
    String? name,
    String? description,
    double? unitPrice,
    String? unit,
    String? category,
    String? sku,
    bool? isActive,
    Map<String, double>? levelPrices, // DEPRECATED but kept for compatibility
    bool? isAddon,
    bool? isDiscountable, // NEW
    int? maxLevels, // NEW
    String? notes, // NEW
  }) {
    if (name != null) this.name = name;
    if (description != null) this.description = description;
    if (unitPrice != null) {
      this.unitPrice = unitPrice;
      // Update base level prices proportionally if they exist
      _updateLevelPricesProportionally(unitPrice);
    }
    if (unit != null) this.unit = unit;
    if (category != null) this.category = category;
    if (sku != null) this.sku = sku;
    if (isActive != null) this.isActive = isActive;
    if (levelPrices != null) this.levelPrices = levelPrices; // Backward compatibility
    if (isAddon != null) this.isAddon = isAddon;
    if (isDiscountable != null) this.isDiscountable = isDiscountable; // NEW
    if (maxLevels != null) this.maxLevels = maxLevels; // NEW
    if (notes != null) this.notes = notes; // NEW

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
      'levelPrices': levelPrices, // Keep for backward compatibility
      'isAddon': isAddon,
      'isDiscountable': isDiscountable, // NEW
      'enhancedLevelPrices': enhancedLevelPrices.map((l) => l.toMap()).toList(), // NEW
      'maxLevels': maxLevels, // NEW
      'notes': notes, // NEW
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
      isDiscountable: map['isDiscountable'] ?? true, // NEW
      enhancedLevelPrices: (map['enhancedLevelPrices'] as List<dynamic>?)
          ?.map((levelData) => ProductLevelPrice.fromMap(levelData as Map<String, dynamic>))
          .toList(), // NEW
      maxLevels: map['maxLevels'] ?? 3, // NEW
      notes: map['notes'], // NEW
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, unitPrice: \$${unitPrice.toStringAsFixed(2)}/$unit, discountable: $isDiscountable)';
  }
}