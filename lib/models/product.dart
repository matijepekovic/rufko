// lib/models/product.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'product.g.dart'; // Will be generated

@HiveType(typeId: 1) // Unique Type ID
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
  Map<String, double> levelPrices; // Key: levelId, Value: price for that level

  @HiveField(11)
  bool isAddon;

  Product({
    String? id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.unit = 'each',
    this.category = 'materials',
    this.sku,
    this.isActive = true,
    Map<String, double>? levelPrices,
    this.isAddon = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : levelPrices = levelPrices ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  double getPriceForLevel(String levelId) {
    return levelPrices[levelId] ?? unitPrice;
  }

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
    Map<String, double>? levelPrices,
    bool? isAddon,
  }) {
    if (name != null) this.name = name;
    if (description != null) this.description = description;
    if (unitPrice != null) this.unitPrice = unitPrice;
    if (unit != null) this.unit = unit;
    if (category != null) this.category = category;
    if (sku != null) this.sku = sku;
    if (isActive != null) this.isActive = isActive;
    if (levelPrices != null) this.levelPrices = levelPrices;
    if (isAddon != null) this.isAddon = isAddon;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
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
      category: map['category'] ?? 'materials',
      sku: map['sku'],
      isActive: map['isActive'] ?? true,
      levelPrices: Map<String, double>.from(map['levelPrices'] ?? {}),
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