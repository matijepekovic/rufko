// lib/models/quote.dart

import 'package:hive/hive.dart';
// No Uuid needed here if not used by QuoteItem directly

part '../../generated/quote.g.dart'; // Will be generated

@HiveType(typeId: 3) // Unique Type ID for QuoteItem
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


// If you had an old "Quote" class here:
/*
@HiveType(typeId: 4) // Ensure this typeId is different and unique
class Quote extends HiveObject {
  // ... your old Quote class fields and methods ...
  // This class will eventually be removed or fully migrated.
  // For now, ensure its typeId doesn't clash.
}
*/
// For now, to reduce errors, if you are NOT immediately migrating data from an old "Quote" class,
// I recommend commenting out or removing the old "Quote" class definition from this file
// to focus on getting "QuoteItem" and the new "SimplifiedMultiLevelQuote" system working.
// If you keep it, make sure its typeId (e.g., 4) is unique and you register its adapter in main.dart.