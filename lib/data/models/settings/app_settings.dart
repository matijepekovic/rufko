// lib/models/app_settings.dart - ENHANCED VERSION (HIVE ANNOTATIONS REMOVED)


class AppSettings {
  late String id;
  late List<String> productCategories;
  late List<String> productUnits;
  late String defaultUnit;
  late DateTime updatedAt;
  late List<String> defaultQuoteLevelNames;
  double taxRate;
  String? companyName;
  String? companyAddress;
  String? companyPhone;
  String? companyEmail;
  String? companyLogoPath;

  // Enhanced settings fields
  late List<String> discountTypes; // 'percentage', 'fixed_amount', 'voucher'
  bool allowProductDiscountToggle; // Whether products can be marked as non-discountable
  double defaultDiscountLimit; // Maximum discount percentage allowed
  bool showCalculatorQuickChips; // Whether to show quick formula chips in calculator
  
  // Job management settings
  late List<String> jobTypes; // User-configurable job types

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
    this.showCalculatorQuickChips = true,
    List<String>? jobTypes,
    DateTime? updatedAt,
  })  : productCategories = productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'],
        productUnits = productUnits ?? ['sq ft', 'lin ft', 'each', 'hour', 'day', 'bundle', 'roll', 'sheet'],
        defaultUnit = defaultUnit ?? 'sq ft',
        defaultQuoteLevelNames = defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'],
        discountTypes = discountTypes ?? ['percentage', 'fixed_amount', 'voucher'],
        jobTypes = jobTypes ?? [
          'Roof Replacement',
          'Roof Repair',
          'Gutter Installation', 
          'Gutter Repair',
          'Emergency Repair',
          'Inspection',
          'Maintenance',
          'Siding',
          'Windows',
          'Other'
        ],
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? 'singleton_app_settings';
  }

  // Enhanced methods for managing categories
  void addProductCategory(String category) {
    if (!productCategories.contains(category)) {
      productCategories.add(category);
      updatedAt = DateTime.now();
    }
  }

  void updateCompanyLogo(String? logoPath) {
    companyLogoPath = logoPath;
    updatedAt = DateTime.now();
  }

  void removeProductCategory(String category) {
    if (productCategories.remove(category)) {
      updatedAt = DateTime.now();
    }
  }

  void updateProductCategories(List<String> categories) {
    productCategories = categories;
    updatedAt = DateTime.now();
  }

  // Enhanced methods for managing units
  void addProductUnit(String unit) {
    if (!productUnits.contains(unit)) {
      productUnits.add(unit);
      updatedAt = DateTime.now();
    }
  }

  void removeProductUnit(String unit) {
    if (productUnits.remove(unit)) {
      // Don't remove if it's the default unit
      if (defaultUnit == unit && productUnits.isNotEmpty) {
        defaultUnit = productUnits.first;
      }
      updatedAt = DateTime.now();
    }
  }

  void updateProductUnits(List<String> units) {
    productUnits = units;
    // Ensure default unit is still valid
    if (!units.contains(defaultUnit) && units.isNotEmpty) {
      defaultUnit = units.first;
    }
    updatedAt = DateTime.now();
  }

  void updateDefaultUnit(String unit) {
    if (productUnits.contains(unit)) {
      defaultUnit = unit;
      updatedAt = DateTime.now();
    }
  }

  void updateDefaultQuoteLevelNames(List<String> levels) {
    defaultQuoteLevelNames = levels;
    updatedAt = DateTime.now();
  }

  void updateTaxRate(double newTaxRate) {
    taxRate = newTaxRate;
    updatedAt = DateTime.now();
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
  }

  // Calculator settings
  void updateCalculatorSettings({
    bool? showQuickChips,
  }) {
    if (showQuickChips != null) showCalculatorQuickChips = showQuickChips;
    updatedAt = DateTime.now();
  }

  // Job type management methods
  void addJobType(String jobType) {
    if (!jobTypes.contains(jobType)) {
      jobTypes.add(jobType);
      updatedAt = DateTime.now();
    }
  }

  void removeJobType(String jobType) {
    if (jobTypes.remove(jobType)) {
      updatedAt = DateTime.now();
    }
  }

  void updateJobTypes(List<String> types) {
    jobTypes = types;
    updatedAt = DateTime.now();
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
      'showCalculatorQuickChips': showCalculatorQuickChips,
      'jobTypes': jobTypes,
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
      showCalculatorQuickChips: map['showCalculatorQuickChips'] ?? true,
      jobTypes: List<String>.from(map['jobTypes'] ?? [
        'Roof Replacement',
        'Roof Repair',
        'Gutter Installation', 
        'Gutter Repair',
        'Emergency Repair',
        'Inspection',
        'Maintenance',
        'Siding',
        'Windows',
        'Other'
      ]),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppSettings(id: $id, company: $companyName, categories: ${productCategories.length}, units: ${productUnits.length})';
  }
}