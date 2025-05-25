// lib/models/simplified_quote.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'quote.dart'; // For QuoteItem

part 'simplified_quote.g.dart'; // Will be generated

@HiveType(typeId: 9) // Unique Type ID for QuoteLevel
class QuoteLevel extends HiveObject {
  @HiveField(0)
  String id; // e.g., "basic", "standard", "premium" or a UUID for custom levels

  @HiveField(1)
  String name; // e.g., "Basic", "Standard", "Premium"

  @HiveField(2)
  int levelNumber; // For ordering

  @HiveField(3)
  double basePrice; // Price of the main "base product" for THIS level

  @HiveField(4)
  List<QuoteItem> includedItems; // Items specifically included in this level's package

  @HiveField(5)
  double subtotal; // Calculated: basePrice + sum of includedItems.totalPrice

  QuoteLevel({
    required this.id,
    required this.name,
    required this.levelNumber,
    required this.basePrice,
    List<QuoteItem>? includedItems, // Made nullable, defaults to empty list
    this.subtotal = 0.0,
  }) : includedItems = includedItems ?? [];

  void calculateSubtotal() {
    subtotal = basePrice +
        includedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'levelNumber': levelNumber,
      'basePrice': basePrice,
      'includedItems': includedItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
    };
  }

  factory QuoteLevel.fromMap(Map<String, dynamic> map) {
    return QuoteLevel(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? 'Unnamed Level',
      levelNumber: map['levelNumber']?.toInt() ?? 0,
      basePrice: map['basePrice']?.toDouble() ?? 0.0,
      includedItems: (map['includedItems'] as List<dynamic>?)
          ?.map((itemData) => QuoteItem.fromMap(itemData as Map<String, dynamic>))
          .toList() ??
          [],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'QuoteLevel(name: $name, basePrice: $basePrice, subtotal: $subtotal, items: ${includedItems.length})';
  }
}

@HiveType(typeId: 10) // Unique Type ID for SimplifiedMultiLevelQuote
class SimplifiedMultiLevelQuote extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String? roofScopeDataId; // Optional

  @HiveField(3)
  late String quoteNumber;

  @HiveField(4)
  List<QuoteLevel> levels; // List of configured levels

  @HiveField(5)
  List<QuoteItem> addons; // Optional add-ons for the entire quote

  @HiveField(6)
  double taxRate;

  @HiveField(7)
  double discount;

  @HiveField(8)
  String status; // e.g., draft, sent, accepted, declined

  @HiveField(9)
  String? notes;

  @HiveField(10)
  late DateTime validUntil;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  SimplifiedMultiLevelQuote({
    String? id,
    required this.customerId,
    this.roofScopeDataId,
    String? quoteNumber,
    List<QuoteLevel>? levels,
    List<QuoteItem>? addons,
    this.taxRate = 0.0,
    this.discount = 0.0,
    this.status = 'draft',
    this.notes,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : levels = levels ?? [],
        addons = addons ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
    this.quoteNumber = quoteNumber ?? 'SQ-${DateTime.now().millisecondsSinceEpoch}'; // SQ for Simplified Quote
    this.validUntil = validUntil ?? DateTime.now().add(const Duration(days: 30));
  }

  /// Recalculates subtotals for all levels.
  void calculateAllLevelSubtotals() {
    for (var level in levels) {
      level.calculateSubtotal();
    }
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  /// Gets the total for a specific quote level, including tax and applying the overall quote discount.
  double getDisplayTotalForLevel(String levelId) {
    final level = levels.firstWhere(
          (l) => l.id == levelId,
      // Return a dummy level if not found to prevent errors, though this shouldn't happen if levelId is valid
      orElse: () => QuoteLevel(id: '', name: 'Error', levelNumber: -1, basePrice: 0),
    );

    if (level.id.isEmpty) return 0.0; // Level not found

    // Total for a level is its subtotal + (its subtotal * taxRate) - discount for that level (if any)
    // The current model has a quote-wide discount, not per-level.
    // If discount is quote-wide, it should ideally be applied after summing up selected level and addons.
    // For display purposes here, let's assume the discount applies to the level.
    double levelSubtotal = level.subtotal;
    double taxAmountOnLevel = levelSubtotal * (taxRate / 100);
    // This interpretation of discount might change based on business logic.
    // Typically, a quote-wide discount is applied at the very end.
    return levelSubtotal + taxAmountOnLevel - discount;
  }

  /// Gets the total for the entire quote if a specific level and specific addons are chosen.
  /// This is a utility for display/PDF after customer makes selections.
  double calculateFinalTotal({required String selectedLevelId, List<QuoteItem>? selectedAddons}) {
    final selectedLevel = levels.firstWhere(
          (l) => l.id == selectedLevelId,
      orElse: () => QuoteLevel(id: '', name: 'Error', levelNumber: -1, basePrice: 0),
    );

    if (selectedLevel.id.isEmpty) return 0.0;

    double currentTotal = selectedLevel.subtotal;

    if (selectedAddons != null) {
      currentTotal += selectedAddons.fold(0.0, (sum, addon) => sum + addon.totalPrice);
    }

    double taxAmount = currentTotal * (taxRate / 100);
    return currentTotal + taxAmount - discount;
  }


  bool get isExpired => DateTime.now().isAfter(validUntil);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'roofScopeDataId': roofScopeDataId,
      'quoteNumber': quoteNumber,
      'levels': levels.map((level) => level.toMap()).toList(),
      'addons': addons.map((addon) => addon.toMap()).toList(),
      'taxRate': taxRate,
      'discount': discount,
      'status': status,
      'notes': notes,
      'validUntil': validUntil.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SimplifiedMultiLevelQuote.fromMap(Map<String, dynamic> map) {
    return SimplifiedMultiLevelQuote(
      id: map['id'],
      customerId: map['customerId'] ?? '',
      roofScopeDataId: map['roofScopeDataId'],
      quoteNumber: map['quoteNumber'] ?? 'SQ-${DateTime.now().millisecondsSinceEpoch}',
      levels: (map['levels'] as List<dynamic>?)
          ?.map((levelData) => QuoteLevel.fromMap(levelData as Map<String, dynamic>))
          .toList() ??
          [],
      addons: (map['addons'] as List<dynamic>?)
          ?.map((addonData) => QuoteItem.fromMap(addonData as Map<String, dynamic>))
          .toList() ??
          [],
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'draft',
      notes: map['notes'],
      validUntil: map['validUntil'] != null ? DateTime.parse(map['validUntil']) : DateTime.now().add(const Duration(days: 30)),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'SimplifiedMultiLevelQuote(id: $id, quoteNumber: $quoteNumber, levels: ${levels.length}, status: $status)';
  }
}