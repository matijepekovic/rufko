// lib/models/app_settings.dart - ENHANCED VERSION

import 'package:hive/hive.dart';

part '../../generated/app_settings.g.dart';

@HiveType(typeId: 6)
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

  @HiveField(7)
  String? companyName;

  @HiveField(8)
  String? companyAddress;

  @HiveField(9)
  String? companyPhone;

  @HiveField(10)
  String? companyEmail;

  @HiveField(11)
  String? companyLogoPath;

  // NEW FIELDS for enhanced settings
  @HiveField(12)
  late List<String> discountTypes; // 'percentage', 'fixed_amount', 'voucher'

  @HiveField(13)
  bool allowProductDiscountToggle; // Whether products can be marked as non-discountable

  @HiveField(14)
  double defaultDiscountLimit; // Maximum discount percentage allowed

  AppSettings({
    String? id,
    List<String>? productCategories,
    List<String>? productUnits,
    String? defaultUnit,
    List<String>? defaultQuoteLevelNames,
    this.taxRate = 0.0,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.companyLogoPath,
    List<String>? discountTypes,
    this.allowProductDiscountToggle = true,
    this.defaultDiscountLimit = 25.0,
    DateTime? updatedAt,
  })  : productCategories = productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'],
        productUnits = productUnits ?? ['sq ft', 'lin ft', 'each', 'hour', 'day', 'bundle', 'roll', 'sheet'],
        defaultUnit = defaultUnit ?? 'sq ft',
        defaultQuoteLevelNames = defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'],
        discountTypes = discountTypes ?? ['percentage', 'fixed_amount', 'voucher'],
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? 'singleton_app_settings';
  }

  // Enhanced methods for managing categories
  void addProductCategory(String category) {
    if (!productCategories.contains(category)) {
      productCategories.add(category);
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateCompanyLogo(String? logoPath) {
    companyLogoPath = logoPath;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void removeProductCategory(String category) {
    if (productCategories.remove(category)) {
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateProductCategories(List<String> categories) {
    productCategories = categories;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Enhanced methods for managing units
  void addProductUnit(String unit) {
    if (!productUnits.contains(unit)) {
      productUnits.add(unit);
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void removeProductUnit(String unit) {
    if (productUnits.remove(unit)) {
      // Don't remove if it's the default unit
      if (defaultUnit == unit && productUnits.isNotEmpty) {
        defaultUnit = productUnits.first;
      }
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateProductUnits(List<String> units) {
    productUnits = units;
    // Ensure default unit is still valid
    if (!units.contains(defaultUnit) && units.isNotEmpty) {
      defaultUnit = units.first;
    }
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void updateDefaultUnit(String unit) {
    if (productUnits.contains(unit)) {
      defaultUnit = unit;
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateDefaultQuoteLevelNames(List<String> levels) {
    defaultQuoteLevelNames = levels;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void updateTaxRate(double newTaxRate) {
    taxRate = newTaxRate;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

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
    if (isInBox) save();
  }

  // NEW: Discount settings
  void updateDiscountSettings({
    List<String>? types,
    bool? allowToggle,
    double? discountLimit,
  }) {
    if (types != null) discountTypes = types;
    if (allowToggle != null) allowProductDiscountToggle = allowToggle;
    if (discountLimit != null) defaultDiscountLimit = discountLimit;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productCategories': productCategories,
      'productUnits': productUnits,
      'defaultUnit': defaultUnit,
      'defaultQuoteLevelNames': defaultQuoteLevelNames,
      'taxRate': taxRate,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'companyLogoPath': companyLogoPath,
      'discountTypes': discountTypes,
      'allowProductDiscountToggle': allowProductDiscountToggle,
      'defaultDiscountLimit': defaultDiscountLimit,
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
      companyName: map['companyName'],
      companyAddress: map['companyAddress'],
      companyPhone: map['companyPhone'],
      companyEmail: map['companyEmail'],
      companyLogoPath: map['companyLogoPath'],
      discountTypes: List<String>.from(map['discountTypes'] ?? ['percentage', 'fixed_amount', 'voucher']),
      allowProductDiscountToggle: map['allowProductDiscountToggle'] ?? true,
      defaultDiscountLimit: map['defaultDiscountLimit']?.toDouble() ?? 25.0,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppSettings(id: $id, company: $companyName, categories: ${productCategories.length}, units: ${productUnits.length})';
  }
}