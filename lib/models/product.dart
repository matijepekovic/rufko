import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'product.g.dart';

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
  String unit; // sq ft, linear ft, each, etc.

  @HiveField(5)
  String category; // shingles, gutters, flashing, labor, etc.

  @HiveField(6)
  String? sku;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  bool definesLevel;

  @HiveField(11)
  String? levelName;

  @HiveField(12)
  int? levelNumber;

  @HiveField(13)
  Map<String, double> levelPrices;

  @HiveField(14)
  bool isUpgrade;

  @HiveField(15)
  bool isAddon;

  Product({
    String? id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.unit = 'sq ft',
    this.category = 'materials',
    this.sku,
    this.isActive = true,
    this.definesLevel = false,
    this.levelName,
    this.levelNumber,
    Map<String, double>? levelPrices,
    this.isUpgrade = false,
    this.isAddon = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        levelPrices = levelPrices ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();

    // Initialize the base price in levelPrices if it's a new product
    if (this.levelPrices.isEmpty) {
      this.levelPrices['base'] = unitPrice;
    }
  }

  // Update product info
  void updateInfo({
    String? name,
    String? description,
    double? unitPrice,
    String? unit,
    String? category,
    String? sku,
    bool? isActive,
    bool? definesLevel,
    String? levelName,
    int? levelNumber,
    Map<String, double>? levelPrices,
    bool? isUpgrade,
    bool? isAddon,
  }) {
    if (name != null) this.name = name;
    if (description != null) this.description = description;
    if (unitPrice != null) {
      this.unitPrice = unitPrice;
      this.levelPrices['base'] = unitPrice; // Update base price too
    }
    if (unit != null) this.unit = unit;
    if (category != null) this.category = category;
    if (sku != null) this.sku = sku;
    if (isActive != null) this.isActive = isActive;
    if (definesLevel != null) this.definesLevel = definesLevel;
    if (levelName != null) this.levelName = levelName;
    if (levelNumber != null) this.levelNumber = levelNumber;
    if (levelPrices != null) this.levelPrices = levelPrices;
    if (isUpgrade != null) this.isUpgrade = isUpgrade;
    if (isAddon != null) this.isAddon = isAddon;

    updatedAt = DateTime.now();
    save();
  }

  // Set level-specific price
  void setLevelPrice(String level, double price) {
    levelPrices[level] = price;
    updatedAt = DateTime.now();
    save();
  }

  // Get price for a specific level
  double getPriceForLevel(String level) {
    return levelPrices[level] ?? unitPrice;
  }

  // Calculate total price for given quantity and level
  double calculateTotal(double quantity, {String? level}) {
    final price = level != null ? getPriceForLevel(level) : unitPrice;
    return price * quantity;
  }

  // Convert to Map for JSON serialization
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
      'definesLevel': definesLevel,
      'levelName': levelName,
      'levelNumber': levelNumber,
      'levelPrices': levelPrices,
      'isUpgrade': isUpgrade,
      'isAddon': isAddon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'sq ft',
      category: map['category'] ?? 'materials',
      sku: map['sku'],
      isActive: map['isActive'] ?? true,
      definesLevel: map['definesLevel'] ?? false,
      levelName: map['levelName'],
      levelNumber: map['levelNumber'],
      levelPrices: map['levelPrices'] != null
        ? Map<String, double>.from(map['levelPrices'])
        : {'base': map['unitPrice']?.toDouble() ?? 0.0},
      isUpgrade: map['isUpgrade'] ?? false,
      isAddon: map['isAddon'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, unitPrice: \$${unitPrice.toStringAsFixed(2)}/$unit)';
  }
}

