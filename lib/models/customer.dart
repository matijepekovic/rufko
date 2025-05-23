import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? address;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  List<String> communicationHistory;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  Customer({
    String? id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    List<String>? communicationHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        communicationHistory = communicationHistory ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  // Add communication entry
  void addCommunication(String entry) {
    communicationHistory.add('${DateTime.now().toIso8601String()}: $entry');
    updatedAt = DateTime.now();
    save();
  }

  // Update customer info
  void updateInfo({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    if (name != null) this.name = name;
    if (phone != null) this.phone = phone;
    if (email != null) this.email = email;
    if (address != null) this.address = address;
    if (notes != null) this.notes = notes;
    updatedAt = DateTime.now();
    save();
  }

  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'communicationHistory': communicationHistory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      communicationHistory: List<String>.from(map['communicationHistory'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, email: $email)';
  }
}