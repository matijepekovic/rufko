import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'quote.dart';
import 'product.dart';

part 'multi_level_quote.g.dart';

@HiveType(typeId: 7)
class LevelQuote extends HiveObject {
  @HiveField(0)
  String levelId;  // "good", "better", "best", etc.

  @HiveField(1)
  String levelName; // "Good", "Better", "Best", etc.

  @HiveField(2)
  int levelNumber; // 1, 2, 3, etc.

  @HiveField(3)
  List<QuoteItem> items;

  @HiveField(4)
  double subtotal;

  @HiveField(5)
  double taxAmount;

  @HiveField(6)
  double total;

  LevelQuote({
    required this.levelId,
    required this.levelName,
    required this.levelNumber,
    List<QuoteItem>? items,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.total = 0.0,
  }) : items = items ?? [];

  // Calculate totals for this level
  void calculateTotals(double taxRate) {
    subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    taxAmount = subtotal * (taxRate / 100);
    total = subtotal + taxAmount;
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'levelName': levelName,
      'levelNumber': levelNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
    };
  }

  // Create from Map
  factory LevelQuote.fromMap(Map<String, dynamic> map) {
    return LevelQuote(
      levelId: map['levelId'],
      levelName: map['levelName'],
      levelNumber: map['levelNumber'],
      items: (map['items'] as List?)?.map((item) => QuoteItem.fromMap(item)).toList() ?? [],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      taxAmount: map['taxAmount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
    );
  }
}

@HiveType(typeId: 8)
class MultiLevelQuote extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String? roofScopeDataId;

  @HiveField(3)
  late String quoteNumber;

  @HiveField(4)
  Map<String, LevelQuote> levels; // Map of levelId -> LevelQuote

  @HiveField(5)
  List<QuoteItem> commonItems; // Items common to all levels (like permits)

  @HiveField(6)
  List<QuoteItem> addons; // Optional add-ons

  @HiveField(7)
  double taxRate;

  @HiveField(8)
  double commonSubtotal; // Subtotal of common items

  @HiveField(9)
  double discount;

  @HiveField(10)
  String status; // draft, sent, accepted, declined

  @HiveField(11)
  String? notes;

  @HiveField(12)
  late DateTime validUntil;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  MultiLevelQuote({
    String? id,
    required this.customerId,
    this.roofScopeDataId,
    String? quoteNumber,
    Map<String, LevelQuote>? levels,
    List<QuoteItem>? commonItems,
    List<QuoteItem>? addons,
    this.taxRate = 0.0,
    this.commonSubtotal = 0.0,
    this.discount = 0.0,
    this.status = 'draft',
    this.notes,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        levels = levels ?? {},
        commonItems = commonItems ?? [],
        addons = addons ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
    this.quoteNumber = quoteNumber ?? 'MLQ-${DateTime.now().millisecondsSinceEpoch}';
    this.validUntil = validUntil ?? DateTime.now().add(const Duration(days: 30));
  }

  // Add a new level to the quote
  LevelQuote addLevel({
    required String levelId,
    required String levelName,
    required int levelNumber,
  }) {
    final level = LevelQuote(
      levelId: levelId,
      levelName: levelName,
      levelNumber: levelNumber,
    );
    levels[levelId] = level;
    calculateTotals();
    return level;
  }

  // Add product to a specific level
  void addProductToLevel(String levelId, Product product, double quantity) {
    if (!levels.containsKey(levelId)) {
      throw Exception('Level $levelId does not exist in this quote');
    }

    // Get price for this level
    final price = product.levelPrices[levelId] ?? product.unitPrice;

    final item = QuoteItem(
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: price,
      unit: product.unit,
      description: product.description,
    );

    levels[levelId]!.items.add(item);
    calculateTotals();
  }

  // Add common item to the quote (applies to all levels)
  void addCommonItem(QuoteItem item) {
    commonItems.add(item);
    calculateTotals();
  }

  // Add add-on item to the quote
  void addAddonItem(QuoteItem item) {
    addons.add(item);
    calculateTotals();
  }

  // Remove level
  void removeLevel(String levelId) {
    levels.remove(levelId);
    calculateTotals();
  }

  // Remove item from a level
  void removeItemFromLevel(String levelId, int index) {
    if (!levels.containsKey(levelId)) return;

    if (index >= 0 && index < levels[levelId]!.items.length) {
      levels[levelId]!.items.removeAt(index);
      calculateTotals();
    }
  }

  // Remove common item
  void removeCommonItem(int index) {
    if (index >= 0 && index < commonItems.length) {
      commonItems.removeAt(index);
      calculateTotals();
    }
  }

  // Remove add-on item
  void removeAddonItem(int index) {
    if (index >= 0 && index < addons.length) {
      addons.removeAt(index);
      calculateTotals();
    }
  }

  // Calculate all totals
  void calculateTotals() {
    // Calculate common subtotal
    commonSubtotal = commonItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    // Calculate level-specific totals
    for (final level in levels.values) {
      level.calculateTotals(taxRate);
    }

    updatedAt = DateTime.now();
    save();
  }

  // Get total for a specific level including common items
  double getLevelTotal(String levelId) {
    if (!levels.containsKey(levelId)) return 0.0;

    // Level items + common items + add-ons - discount
    return levels[levelId]!.total + commonSubtotal - discount;
  }

  // Update tax rate and recalculate
  void updateTaxRate(double newTaxRate) {
    taxRate = newTaxRate;
    calculateTotals();
  }

  // Apply discount
  void applyDiscount(double discountAmount) {
    discount = discountAmount;
    calculateTotals();
  }

  // Update status
  void updateStatus(String newStatus) {
    status = newStatus;
    updatedAt = DateTime.now();
    save();
  }

  // Check if quote is expired
  bool get isExpired => DateTime.now().isAfter(validUntil);

  // Get formatted quote number
  String get formattedQuoteNumber => quoteNumber;

  // Convert to Map for JSON/PDF generation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'roofScopeDataId': roofScopeDataId,
      'quoteNumber': quoteNumber,
      'levels': levels.map((key, level) => MapEntry(key, level.toMap())),
      'commonItems': commonItems.map((item) => item.toMap()).toList(),
      'addons': addons.map((item) => item.toMap()).toList(),
      'taxRate': taxRate,
      'commonSubtotal': commonSubtotal,
      'discount': discount,
      'status': status,
      'notes': notes,
      'validUntil': validUntil.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory MultiLevelQuote.fromMap(Map<String, dynamic> map) {
    return MultiLevelQuote(
      id: map['id'],
      customerId: map['customerId'],
      roofScopeDataId: map['roofScopeDataId'],
      quoteNumber: map['quoteNumber'],
      levels: (map['levels'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), LevelQuote.fromMap(value))
      ) ?? {},
      commonItems: (map['commonItems'] as List?)?.map((item) => QuoteItem.fromMap(item)).toList() ?? [],
      addons: (map['addons'] as List?)?.map((item) => QuoteItem.fromMap(item)).toList() ?? [],
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      commonSubtotal: map['commonSubtotal']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'draft',
      notes: map['notes'],
      validUntil: DateTime.parse(map['validUntil']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'MultiLevelQuote(id: $id, number: $quoteNumber, levels: ${levels.length}, status: $status)';
  }
}
