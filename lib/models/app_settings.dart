// lib/models/app_settings.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'app_settings.g.dart'; // Remember to run build_runner after changes

@HiveType(typeId: 6) // Unique Type ID
class AppSettings extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late List<String> productCategories;

  @HiveField(2)
  late List<String> productUnits;

  @HiveField(3)
  late String defaultUnit;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  late List<String> defaultQuoteLevelNames;

  @HiveField(6)
  double taxRate;

  @HiveField(7) // New field
  String? companyName;

  @HiveField(8) // New field
  String? companyAddress;

  @HiveField(9) // New field
  String? companyPhone;

  @HiveField(10) // New field
  String? companyEmail;

  @HiveField(11) // New field - for logo path or base64 string
  String? companyLogoPath;


  AppSettings({
    String? id,
    List<String>? productCategories,
    List<String>? productUnits,
    String? defaultUnit,
    List<String>? defaultQuoteLevelNames,
    this.taxRate = 0.0,
    this.companyName, // Added
    this.companyAddress, // Added
    this.companyPhone,   // Added
    this.companyEmail,   // Added
    this.companyLogoPath,// Added
    DateTime? updatedAt,
  })  : productCategories = productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'],
        productUnits = productUnits ?? ['sq ft', 'lin ft', 'each', 'hour', 'day'],
        defaultUnit = defaultUnit ?? 'sq ft',
        defaultQuoteLevelNames = defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'],
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? 'singleton_app_settings'; // Using a fixed ID for singleton behavior
  }

  void updateProductCategories(List<String> categories) {
    productCategories = categories;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  void updateProductUnits(List<String> units) {
    productUnits = units;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  void updateDefaultUnit(String unit) {
    defaultUnit = unit;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  void updateDefaultQuoteLevelNames(List<String> levels) {
    defaultQuoteLevelNames = levels;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  void updateTaxRate(double newTaxRate) {
    taxRate = newTaxRate;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  // Method to update company info
  void updateCompanyInfo({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
  }) {
    if (name != null) companyName = name;
    if (address != null) companyAddress = address;
    if (phone != null) companyPhone = phone;
    if (email != null) companyEmail = email;
    if (logoPath != null) companyLogoPath = logoPath;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productCategories': productCategories,
      'productUnits': productUnits,
      'defaultUnit': defaultUnit,
      'defaultQuoteLevelNames': defaultQuoteLevelNames,
      'taxRate': taxRate,
      'companyName': companyName, // Added
      'companyAddress': companyAddress, // Added
      'companyPhone': companyPhone,     // Added
      'companyEmail': companyEmail,     // Added
      'companyLogoPath': companyLogoPath, // Added
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] ?? 'singleton_app_settings',
      productCategories: List<String>.from(map['productCategories'] ?? []),
      productUnits: List<String>.from(map['productUnits'] ?? []),
      defaultUnit: map['defaultUnit'] ?? 'sq ft',
      defaultQuoteLevelNames: List<String>.from(map['defaultQuoteLevelNames'] ?? ['Basic', 'Standard', 'Premium']),
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      companyName: map['companyName'], // Added
      companyAddress: map['companyAddress'], // Added
      companyPhone: map['companyPhone'],       // Added
      companyEmail: map['companyEmail'],       // Added
      companyLogoPath: map['companyLogoPath'],   // Added
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppSettings(id: $id, company: $companyName, taxRate: $taxRate%)';
  }
}