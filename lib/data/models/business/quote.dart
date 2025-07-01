// lib/models/quote.dart - MIGRATED TO SQLITE

class QuoteItem {
  String productId;
  String productName;
  double quantity;
  double unitPrice;
  String unit;
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
      productId: map['productId'] ?? '', // Provide default if nullable
      productName: map['productName'] ?? 'Unknown Product', // Provide default
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'each', // Provide default
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'QuoteItem(productName: $productName, quantity: $quantity, totalPrice: $totalPrice)';
  }
}


// Old Quote class has been completely removed - migration to SQLite complete