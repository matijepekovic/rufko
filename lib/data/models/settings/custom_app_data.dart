// lib/models/custom_app_data.dart (HIVE ANNOTATIONS REMOVED)

import 'package:uuid/uuid.dart';

class CustomAppDataField {
  late String id;
  String fieldName; // e.g., "companyName", "licenseNumber"
  String displayName; // e.g., "Company Name", "License Number"
  String fieldType; // "text", "number", "email", "phone", "multiline", "date", "currency"
  String currentValue; // The actual value
  String category; // "company", "contact", "legal", "pricing", "custom"
  bool isRequired;
  String? placeholder; // Placeholder text
  String? description; // Help text
  int sortOrder; // For organizing fields
  DateTime createdAt;
  DateTime updatedAt;
  List<String>? dropdownOptions; // Add dropdown options support

  CustomAppDataField({
    String? id,
    required this.fieldName,
    required this.displayName,
    this.fieldType = 'text',
    this.currentValue = '',
    this.category = 'custom',
    this.isRequired = false,
    this.placeholder,
    this.description,
    this.sortOrder = 0,
    this.dropdownOptions,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  void updateValue(String newValue) {
    currentValue = newValue;
    updatedAt = DateTime.now();
  }

  void updateField({
    String? displayName,
    String? fieldType,
    String? category,
    bool? isRequired,
    String? placeholder,
    String? description,
    int? sortOrder,
    List<String>? dropdownOptions,
  }) {
    if (displayName != null) this.displayName = displayName;
    if (fieldType != null) this.fieldType = fieldType;
    if (category != null) this.category = category;
    if (isRequired != null) this.isRequired = isRequired;
    if (placeholder != null) this.placeholder = placeholder;
    if (description != null) this.description = description;
    if (sortOrder != null) this.sortOrder = sortOrder;
    if (dropdownOptions != null) this.dropdownOptions = dropdownOptions;

    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldName': fieldName,
      'displayName': displayName,
      'fieldType': fieldType,
      'currentValue': currentValue,
      'category': category,
      'isRequired': isRequired,
      'placeholder': placeholder,
      'description': description,
      'sortOrder': sortOrder,
      'dropdownOptions': dropdownOptions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomAppDataField.fromMap(Map<String, dynamic> map) {
    return CustomAppDataField(
      id: map['id'],
      fieldName: map['fieldName'] ?? '',
      displayName: map['displayName'] ?? '',
      fieldType: map['fieldType'] ?? 'text',
      currentValue: map['currentValue'] ?? '',
      category: map['category'] ?? 'custom',
      isRequired: map['isRequired'] ?? false,
      placeholder: map['placeholder'],
      description: map['description'],
      sortOrder: map['sortOrder']?.toInt() ?? 0,
      dropdownOptions: map['dropdownOptions'] != null
          ? List<String>.from(map['dropdownOptions'])
          : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CustomAppDataField(fieldName: $fieldName, displayName: $displayName, value: "$currentValue")';
  }
}

// Predefined field templates for common use cases
