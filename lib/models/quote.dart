import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'quote.g.dart';

@HiveType(typeId: 3)
class QuoteItem extends HiveObject {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double unitPrice;

  @HiveField(4)
  String unit;

  @HiveField(5)
  String? description;

  QuoteItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unit,
    this.description,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unit': unit,
      'description': description,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      unit: map['unit'],
      description: map['description'],
    );
  }
}

@HiveType(typeId: 4)
class Quote extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String? roofScopeDataId;

  @HiveField(3)
  late String quoteNumber;

  @HiveField(4)
  List<QuoteItem> items;

  @HiveField(5)
  double subtotal;

  @HiveField(6)
  double taxRate;

  @HiveField(7)
  double taxAmount;

  @HiveField(8)
  double discount;

  @HiveField(9)
  double total;

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

  Quote({
    String? id,
    required this.customerId,
    this.roofScopeDataId,
    String? quoteNumber,
    List<QuoteItem>? items,
    this.subtotal = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.status = 'draft',
    this.notes,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
    this.quoteNumber = quoteNumber ?? 'Q-${DateTime.now().millisecondsSinceEpoch}';
    this.validUntil = validUntil ?? DateTime.now().add(const Duration(days: 30));
  }

  // Add item to quote
  void addItem(QuoteItem item) {
    items.add(item);
    calculateTotals();
  }

  // Remove item from quote
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      calculateTotals();
    }
  }

  // Update item quantity
  void updateItemQuantity(int index, double quantity) {
    if (index >= 0 && index < items.length) {
      items[index].quantity = quantity;
      calculateTotals();
    }
  }

  // Calculate all totals
  void calculateTotals() {
    subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    taxAmount = subtotal * (taxRate / 100);
    total = subtotal + taxAmount - discount;
    updatedAt = DateTime.now();
    save();
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
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'discount': discount,
      'total': total,
      'status': status,
      'notes': notes,
      'validUntil': validUntil.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      customerId: map['customerId'],
      roofScopeDataId: map['roofScopeDataId'],
      quoteNumber: map['quoteNumber'],
      items: (map['items'] as List?)?.map((item) => QuoteItem.fromMap(item)).toList() ?? [],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      taxAmount: map['taxAmount']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'draft',
      notes: map['notes'],
      validUntil: DateTime.parse(map['validUntil']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Quote(id: $id, number: $quoteNumber, total: \$${total.toStringAsFixed(2)}, status: $status)';
  }
}