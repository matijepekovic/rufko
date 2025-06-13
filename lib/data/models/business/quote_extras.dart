// lib/models/quote_extras.dart

class PermitItem {
  final String id;
  final String name;
  final double amount;
  final String? description;
  final bool isRequired;

  PermitItem({
    String? id,
    required this.name,
    required this.amount,
    this.description,
    this.isRequired = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'description': description,
      'isRequired': isRequired,
    };
  }

  factory PermitItem.fromMap(Map<String, dynamic> map) {
    return PermitItem(
      id: map['id'],
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'],
      isRequired: map['isRequired'] ?? true,
    );
  }
}

class CustomLineItem {
  final String id;
  final String name;
  final double amount;
  final String? description;
  final bool isTaxable;

  CustomLineItem({
    String? id,
    required this.name,
    required this.amount,
    this.description,
    this.isTaxable = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'description': description,
      'isTaxable': isTaxable,
    };
  }

  factory CustomLineItem.fromMap(Map<String, dynamic> map) {
    return CustomLineItem(
      id: map['id'],
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'],
      isTaxable: map['isTaxable'] ?? true,
    );
  }
}