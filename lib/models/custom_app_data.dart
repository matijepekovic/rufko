// lib/models/custom_app_data.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'custom_app_data.g.dart';

@HiveType(typeId: 12) // New type ID
class CustomAppDataField extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String fieldName; // e.g., "companyName", "licenseNumber"

  @HiveField(2)
  String displayName; // e.g., "Company Name", "License Number"

  @HiveField(3)
  String fieldType; // "text", "number", "email", "phone", "multiline", "date", "currency"

  @HiveField(4)
  String currentValue; // The actual value

  @HiveField(5)
  String category; // "company", "contact", "legal", "pricing", "custom"

  @HiveField(6)
  bool isRequired;

  @HiveField(7)
  String? placeholder; // Placeholder text

  @HiveField(8)
  String? description; // Help text

  @HiveField(9)
  int sortOrder; // For organizing fields

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12) // Add dropdown options support
  List<String>? dropdownOptions;

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
    if (isInBox) save();
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
    if (isInBox) save();
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
class CustomAppDataTemplates {
  // Protected categories that cannot be deleted or renamed
  static const List<String> protectedCategories = ['inspection'];

  static bool isProtectedCategory(String category) {
    return protectedCategories.contains(category.toLowerCase());
  }

  static List<CustomAppDataField> getCompanyFields() {
    return [
      CustomAppDataField(
        fieldName: 'companyName',
        displayName: 'Company Name',
        fieldType: 'text',
        category: 'company',
        isRequired: true,
        placeholder: 'Your Company Name',
        sortOrder: 1,
      ),
      CustomAppDataField(
        fieldName: 'companyAddress',
        displayName: 'Company Address',
        fieldType: 'multiline',
        category: 'company',
        placeholder: '123 Main St\nCity, State ZIP',
        sortOrder: 2,
      ),
      CustomAppDataField(
        fieldName: 'companyPhone',
        displayName: 'Company Phone',
        fieldType: 'phone',
        category: 'company',
        placeholder: '(555) 123-4567',
        sortOrder: 3,
      ),
      CustomAppDataField(
        fieldName: 'companyEmail',
        displayName: 'Company Email',
        fieldType: 'email',
        category: 'company',
        placeholder: 'info@yourcompany.com',
        sortOrder: 4,
      ),
      CustomAppDataField(
        fieldName: 'companyWebsite',
        displayName: 'Company Website',
        fieldType: 'text',
        category: 'company',
        placeholder: 'www.yourcompany.com',
        sortOrder: 5,
      ),
    ];
  }

  static List<CustomAppDataField> getLegalFields() {
    return [
      CustomAppDataField(
        fieldName: 'licenseNumber',
        displayName: 'License Number',
        fieldType: 'text',
        category: 'legal',
        isRequired: true,
        placeholder: 'CON-12345',
        sortOrder: 1,
      ),
      CustomAppDataField(
        fieldName: 'insurancePolicy',
        displayName: 'Insurance Policy',
        fieldType: 'text',
        category: 'legal',
        placeholder: 'Policy #123456',
        sortOrder: 2,
      ),
      CustomAppDataField(
        fieldName: 'bondNumber',
        displayName: 'Bond Number',
        fieldType: 'text',
        category: 'legal',
        placeholder: 'Bond #789012',
        sortOrder: 3,
      ),
    ];
  }

  static List<CustomAppDataField> getPricingFields() {
    return [
      CustomAppDataField(
        fieldName: 'defaultTaxRate',
        displayName: 'Default Tax Rate',
        fieldType: 'number',
        category: 'pricing',
        currentValue: '8.5',
        placeholder: '8.5',
        description: 'Default tax rate percentage',
        sortOrder: 1,
      ),
      CustomAppDataField(
        fieldName: 'defaultMarkup',
        displayName: 'Default Markup',
        fieldType: 'number',
        category: 'pricing',
        currentValue: '20',
        placeholder: '20',
        description: 'Default markup percentage',
        sortOrder: 2,
      ),
      CustomAppDataField(
        fieldName: 'warrantyPeriod',
        displayName: 'Warranty Period',
        fieldType: 'text',
        category: 'pricing',
        currentValue: '25 years',
        placeholder: '25 years',
        sortOrder: 3,
      ),
    ];
  }

  static List<CustomAppDataField> getAllDefaultFields() {
    return [
      ...getCompanyFields(),
      ...getLegalFields(),
      ...getPricingFields(),
    ];
  }
}