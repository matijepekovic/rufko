import 'package:uuid/uuid.dart';

/// Model representing an inventory item for a specific product
/// Tracks current stock levels, minimum stock alerts, and location information
class InventoryItem {
  final String id;
  final String productId;
  int quantity;
  int? minimumStock;
  String? location;
  DateTime lastUpdated;
  String? notes;

  InventoryItem({
    String? id,
    required this.productId,
    required this.quantity,
    this.minimumStock,
    this.location,
    DateTime? lastUpdated,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Check if inventory is at or below minimum stock level
  bool get isLowStock {
    if (minimumStock == null) return false;
    return quantity <= minimumStock!;
  }

  /// Check if inventory is completely out of stock
  bool get isOutOfStock => quantity <= 0;

  /// Update inventory quantity and timestamp
  void updateQuantity(int newQuantity, {String? reason}) {
    quantity = newQuantity;
    lastUpdated = DateTime.now();
  }

  /// Update inventory details
  void updateInfo({
    int? quantity,
    int? minimumStock,
    String? location,
    String? notes,
  }) {
    if (quantity != null) this.quantity = quantity;
    if (minimumStock != null) this.minimumStock = minimumStock;
    if (location != null) this.location = location;
    if (notes != null) this.notes = notes;
    lastUpdated = DateTime.now();
  }

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'minimum_stock': minimumStock,
      'location': location,
      'last_updated': lastUpdated.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create from Map (SQLite result)
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int,
      minimumStock: map['minimum_stock'] as int?,
      location: map['location'] as String?,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      notes: map['notes'] as String?,
    );
  }

  /// Create a copy with modified values
  InventoryItem copyWith({
    String? id,
    String? productId,
    int? quantity,
    int? minimumStock,
    String? location,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, productId: $productId, quantity: $quantity, lowStock: $isLowStock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}