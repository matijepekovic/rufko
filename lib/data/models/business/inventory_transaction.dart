import 'package:uuid/uuid.dart';

/// Enum representing different types of inventory transactions
enum InventoryTransactionType {
  add,       // Adding new inventory (purchases, returns)
  remove,    // Removing inventory (sales, usage, waste)
  adjust,    // Adjusting inventory (corrections, audits)
  initial,   // Initial inventory count when first added
}

/// Model representing a single inventory transaction
/// Provides complete audit trail of all inventory changes
class InventoryTransaction {
  final String id;
  final String inventoryItemId;
  final InventoryTransactionType type;
  final int quantity; // Positive for additions, negative for removals
  final int previousQuantity;
  final int newQuantity;
  final String reason;
  final DateTime timestamp;
  final String? userId; // Optional: track who made the change

  InventoryTransaction({
    String? id,
    required this.inventoryItemId,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    DateTime? timestamp,
    this.userId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Get description of the transaction type
  String get typeDescription {
    switch (type) {
      case InventoryTransactionType.add:
        return 'Added';
      case InventoryTransactionType.remove:
        return 'Removed';
      case InventoryTransactionType.adjust:
        return 'Adjusted';
      case InventoryTransactionType.initial:
        return 'Initial Count';
    }
  }

  /// Get quantity change as a formatted string with sign
  String get quantityChangeFormatted {
    if (quantity > 0) {
      return '+$quantity';
    } else {
      return quantity.toString();
    }
  }

  /// Check if this transaction increased inventory
  bool get isIncrease => quantity > 0;

  /// Check if this transaction decreased inventory
  bool get isDecrease => quantity < 0;

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'type': type.name,
      'quantity': quantity,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
    };
  }

  /// Create from Map (SQLite result)
  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction(
      id: map['id'] as String,
      inventoryItemId: map['inventory_item_id'] as String,
      type: InventoryTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InventoryTransactionType.adjust,
      ),
      quantity: map['quantity'] as int,
      previousQuantity: map['previous_quantity'] as int,
      newQuantity: map['new_quantity'] as int,
      reason: map['reason'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['user_id'] as String?,
    );
  }

  /// Create a transaction for adding inventory
  factory InventoryTransaction.add({
    required String inventoryItemId,
    required int quantityAdded,
    required int previousQuantity,
    required String reason,
    String? userId,
  }) {
    return InventoryTransaction(
      inventoryItemId: inventoryItemId,
      type: InventoryTransactionType.add,
      quantity: quantityAdded,
      previousQuantity: previousQuantity,
      newQuantity: previousQuantity + quantityAdded,
      reason: reason,
      userId: userId,
    );
  }

  /// Create a transaction for removing inventory
  factory InventoryTransaction.remove({
    required String inventoryItemId,
    required int quantityRemoved,
    required int previousQuantity,
    required String reason,
    String? userId,
  }) {
    return InventoryTransaction(
      inventoryItemId: inventoryItemId,
      type: InventoryTransactionType.remove,
      quantity: -quantityRemoved,
      previousQuantity: previousQuantity,
      newQuantity: previousQuantity - quantityRemoved,
      reason: reason,
      userId: userId,
    );
  }

  /// Create a transaction for adjusting inventory
  factory InventoryTransaction.adjust({
    required String inventoryItemId,
    required int previousQuantity,
    required int newQuantity,
    required String reason,
    String? userId,
  }) {
    return InventoryTransaction(
      inventoryItemId: inventoryItemId,
      type: InventoryTransactionType.adjust,
      quantity: newQuantity - previousQuantity,
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
      reason: reason,
      userId: userId,
    );
  }

  /// Create a transaction for initial inventory count
  factory InventoryTransaction.initial({
    required String inventoryItemId,
    required int initialQuantity,
    String reason = 'Initial inventory count',
    String? userId,
  }) {
    return InventoryTransaction(
      inventoryItemId: inventoryItemId,
      type: InventoryTransactionType.initial,
      quantity: initialQuantity,
      previousQuantity: 0,
      newQuantity: initialQuantity,
      reason: reason,
      userId: userId,
    );
  }

  @override
  String toString() {
    return 'InventoryTransaction(id: $id, type: $typeDescription, quantity: $quantityChangeFormatted, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}