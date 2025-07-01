// lib/models/simplified_quote.dart - MIGRATED TO SQLITE

import 'package:uuid/uuid.dart';
import 'quote.dart'; // For QuoteItem
import 'quote_extras.dart';
import 'customer.dart';
import '../../../core/services/naming/naming_service.dart';

// NEW: Discount/Voucher model
class QuoteDiscount {
  late String id;
  String type; // 'percentage', 'fixed_amount', 'voucher'
  double value; // Percentage (0-100) or fixed amount
  String? code; // Voucher code if applicable
  String? description; // Description of the discount
  bool applyToAddons; // Whether discount applies to add-ons
  List<String> excludedProductIds; // Products excluded from this discount
  DateTime? expiryDate; // When this discount expires
  bool isActive;

  QuoteDiscount({
    String? id,
    required this.type,
    required this.value,
    this.code,
    this.description,
    this.applyToAddons = true,
    List<String>? excludedProductIds,
    this.expiryDate,
    this.isActive = true,
  }) : excludedProductIds = excludedProductIds ?? [] {
    this.id = id ?? const Uuid().v4();
  }

  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isValid => isActive && !isExpired;

  double calculateDiscountAmount(double subtotal) {
    if (!isValid) return 0.0;

    switch (type) {
      case 'percentage':
        return subtotal * (value / 100);
      case 'fixed_amount':
        return value;
      default:
        return 0.0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'code': code,
      'description': description,
      'applyToAddons': applyToAddons,
      'excludedProductIds': excludedProductIds,
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory QuoteDiscount.fromMap(Map<String, dynamic> map) {
    return QuoteDiscount(
      id: map['id'],
      type: map['type'] ?? 'percentage',
      value: map['value']?.toDouble() ?? 0.0,
      code: map['code'],
      description: map['description'],
      applyToAddons: map['applyToAddons'] ?? true,
      excludedProductIds: List<String>.from(map['excludedProductIds'] ?? []),
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  String toString() {
    return 'QuoteDiscount(type: $type, value: $value, code: $code)';
  }
}





class QuoteLevel {
  String id;
  String name;
  int levelNumber;
  double basePrice;
  List<QuoteItem> includedItems;
  double subtotal;
  double baseQuantity;

  QuoteLevel({
    required this.id,
    required this.name,
    required this.levelNumber,
    required this.basePrice,
    this.baseQuantity = 1.0,
    List<QuoteItem>? includedItems,
    this.subtotal = 0.0,
  }) : includedItems = includedItems ?? [];

  void calculateSubtotal() {
    subtotal = (basePrice * baseQuantity) +
        includedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get baseProductTotal => basePrice * baseQuantity;

  // NEW: Calculate discounted subtotal
  double calculateDiscountedSubtotal(List<QuoteDiscount> discounts, List<String> nonDiscountableProductIds) {
    double discountableAmount = baseProductTotal;
    double nonDiscountableAmount = 0.0;

    // Separate discountable and non-discountable items
    for (final item in includedItems) {
      if (nonDiscountableProductIds.contains(item.productId)) {
        nonDiscountableAmount += item.totalPrice;
      } else {
        discountableAmount += item.totalPrice;
      }
    }

    // Apply discounts only to discountable amount
    double totalDiscountAmount = 0.0;
    for (final discount in discounts.where((d) => d.isValid)) {
      totalDiscountAmount += discount.calculateDiscountAmount(discountableAmount);
    }

    return (discountableAmount - totalDiscountAmount) + nonDiscountableAmount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'levelNumber': levelNumber,
      'basePrice': basePrice,
      'baseQuantity': baseQuantity,
      'includedItems': includedItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
    };
  }

  factory QuoteLevel.fromMap(Map<String, dynamic> map) {
    return QuoteLevel(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? 'Unnamed Level',
      levelNumber: map['levelNumber']?.toInt() ?? 0,
      basePrice: map['basePrice']?.toDouble() ?? 0.0,
      baseQuantity: map['baseQuantity']?.toDouble() ?? 1.0,
      includedItems: (map['includedItems'] as List<dynamic>?)
          ?.map((itemData) => QuoteItem.fromMap(itemData as Map<String, dynamic>))
          .toList() ??
          [],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'QuoteLevel(name: $name, basePrice: $basePrice, baseQty: $baseQuantity, subtotal: $subtotal, items: ${includedItems.length})';
  }
}

class SimplifiedMultiLevelQuote {
  late String id;
  String customerId;
  String? roofScopeDataId;
  late String quoteNumber;
  List<QuoteLevel> levels;
  List<QuoteItem> addons;
  double taxRate;
  double discount; // DEPRECATED - use discounts list instead
  String status;
  String? previousStatus; // NEW: Track previous status for undo functionality
  int version; // NEW: Version number starting at 1
  String? parentQuoteId; // NEW: Links to original quote for versioning
  bool isCurrentVersion; // NEW: Only one version should be current
  String? notes;
  late DateTime validUntil;
  DateTime createdAt;
  DateTime updatedAt;
  String? baseProductId;
  String? baseProductName;
  String? baseProductUnit;
  // NEW FIELDS for enhanced discount system
  List<QuoteDiscount> discounts; // Multiple discounts/vouchers
  List<String> nonDiscountableProductIds; // Products excluded from discounts
  // NEW: Store generated PDF path
  String? pdfPath; // Path to the last generated PDF
  String? pdfTemplateId; // ID of template used for last PDF generation
  DateTime? pdfGeneratedAt; // When the PDF was last generated
  String? selectedLevelId; // Currently selected level ID

  List<PermitItem> permits = [];
  bool noPermitsRequired = false;
  List<CustomLineItem> customLineItems = [];

  SimplifiedMultiLevelQuote({
    String? id,
    required this.customerId,
    this.roofScopeDataId,
    String? quoteNumber,
    List<QuoteLevel>? levels,
    List<QuoteItem>? addons,
    this.taxRate = 0.0,
    this.discount = 0.0, // DEPRECATED
    this.status = 'draft',
    this.previousStatus,
    this.version = 1,
    this.parentQuoteId,
    this.isCurrentVersion = true,
    this.notes,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.baseProductId,
    this.baseProductName,
    this.baseProductUnit,
    List<QuoteDiscount>? discounts, // NEW
    List<String>? nonDiscountableProductIds, // NEW
    this.pdfPath, // NEW
    this.pdfTemplateId, // NEW
    this.pdfGeneratedAt, // NEW
    List<PermitItem>? permits, // NEW
    this.noPermitsRequired = false, // NEW
    List<CustomLineItem>? customLineItems, // NEW
    this.selectedLevelId, // NEW
    Customer? customer, // NEW: Optional customer for quote number generation
  })  : levels = levels ?? [],
        addons = addons ?? [],
        discounts = discounts ?? [], // NEW
        nonDiscountableProductIds = nonDiscountableProductIds ?? [], // NEW
        permits = permits ?? [], // NEW
        customLineItems = customLineItems ?? [], // NEW
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
    // Use new naming service if customer provided, otherwise fall back to old format
    this.quoteNumber = quoteNumber ?? 
        (customer != null 
            ? NamingService.generateQuoteNumber(customer)
            : 'SQ-${DateTime.now().millisecondsSinceEpoch}');
    this.validUntil = validUntil ?? DateTime.now().add(const Duration(days: 30));
  }

  // Get the effective selected level ID (stored selection or first level as fallback)
  String? get effectiveSelectedLevelId {
    if (selectedLevelId != null && levels.any((level) => level.id == selectedLevelId)) {
      return selectedLevelId;
    }
    return levels.isNotEmpty ? levels.first.id : null;
  }

  // Add a discount/voucher
  void addDiscount(QuoteDiscount discount) {
    discounts.add(discount);
    updatedAt = DateTime.now();
  }

  // Remove a discount
  void removeDiscount(String discountId) {
    discounts.removeWhere((d) => d.id == discountId);
    updatedAt = DateTime.now();
  }

  // Get total discount amount for a level
  double getTotalDiscountForLevel(String levelId) {
    final level = levels.firstWhere((l) => l.id == levelId, orElse: () => QuoteLevel(id: '', name: '', levelNumber: 0, basePrice: 0));
    if (level.id.isEmpty) return 0.0;

    return level.subtotal - level.calculateDiscountedSubtotal(discounts, nonDiscountableProductIds);
  }

  void calculateAllLevelSubtotals() {
    for (var level in levels) {
      level.calculateSubtotal();
    }
    updatedAt = DateTime.now();
  }

  // UPDATED: Get display total with new discount system
  double getDisplayTotalForLevel(String levelId) {
    final level = levels.firstWhere(
          (l) => l.id == levelId,
      orElse: () => QuoteLevel(id: '', name: 'Error', levelNumber: -1, basePrice: 0),
    );

    if (level.id.isEmpty) return 0.0;

    // Calculate discounted subtotal for this level
    double discountedSubtotal = level.calculateDiscountedSubtotal(discounts, nonDiscountableProductIds);

    // Add discountable addons
    double addonTotal = 0.0;
    double nonDiscountableAddonTotal = 0.0;

    for (final addon in addons) {
      if (nonDiscountableProductIds.contains(addon.productId)) {
        nonDiscountableAddonTotal += addon.totalPrice;
      } else {
        addonTotal += addon.totalPrice;
      }
    }

    // Apply discounts to addons
    double addonDiscountAmount = 0.0;
    for (final discount in discounts.where((d) => d.isValid && d.applyToAddons)) {
      addonDiscountAmount += discount.calculateDiscountAmount(addonTotal);
    }

    double finalSubtotal = discountedSubtotal + (addonTotal - addonDiscountAmount) + nonDiscountableAddonTotal;

    // 🔧 FIX: Apply tax to the final subtotal
    double taxAmount = finalSubtotal * (taxRate / 100);
    double totalWithTax = finalSubtotal + taxAmount;

    return totalWithTax;
  }

  // NEW: Get discounted subtotal for display (what user actually pays before tax)
  double getDiscountedSubtotalForLevel(String levelId) {
    final level = levels.firstWhere(
          (l) => l.id == levelId,
      orElse: () => QuoteLevel(id: '', name: 'Error', levelNumber: -1, basePrice: 0),
    );

    if (level.id.isEmpty) return 0.0;

    // Calculate discounted subtotal for this level
    double discountedSubtotal = level.calculateDiscountedSubtotal(discounts, nonDiscountableProductIds);

    // Add discountable addons
    double addonTotal = 0.0;
    double nonDiscountableAddonTotal = 0.0;

    for (final addon in addons) {
      if (nonDiscountableProductIds.contains(addon.productId)) {
        nonDiscountableAddonTotal += addon.totalPrice;
      } else {
        addonTotal += addon.totalPrice;
      }
    }

    // Apply discounts to addons
    double addonDiscountAmount = 0.0;
    for (final discount in discounts.where((d) => d.isValid && d.applyToAddons)) {
      addonDiscountAmount += discount.calculateDiscountAmount(addonTotal);
    }

    return discountedSubtotal + (addonTotal - addonDiscountAmount) + nonDiscountableAddonTotal;
  }

  // NEW: Get tax amount for display
  double getTaxAmountForLevel(String levelId) {
    final discountedSubtotal = getDiscountedSubtotalForLevel(levelId);
    return discountedSubtotal * (taxRate / 100);
  }

  // NEW: Get discount summary
  Map<String, dynamic> getDiscountSummary(String levelId) {
    final levelDiscount = getTotalDiscountForLevel(levelId);

    double addonDiscount = 0.0;
    double discountableAddonTotal = 0.0;

    for (final addon in addons) {
      if (!nonDiscountableProductIds.contains(addon.productId)) {
        discountableAddonTotal += addon.totalPrice;
      }
    }

    for (final discount in discounts.where((d) => d.isValid && d.applyToAddons)) {
      addonDiscount += discount.calculateDiscountAmount(discountableAddonTotal);
    }

    return {
      'levelDiscount': levelDiscount,
      'addonDiscount': addonDiscount,
      'totalDiscount': levelDiscount + addonDiscount,
      'appliedDiscounts': discounts.where((d) => d.isValid).toList(),
    };
  }

  double calculateFinalTotal({required String selectedLevelId, List<QuoteItem>? selectedAddons}) {
    return getDisplayTotalForLevel(selectedLevelId);
  }

  bool get isExpired => DateTime.now().isAfter(validUntil);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'roofScopeDataId': roofScopeDataId,
      'quoteNumber': quoteNumber,
      'levels': levels.map((level) => level.toMap()).toList(),
      'addons': addons.map((addon) => addon.toMap()).toList(),
      'taxRate': taxRate,
      'discount': discount, // Keep for backward compatibility
      'status': status,
      'previousStatus': previousStatus, // NEW
      'notes': notes,
      'validUntil': validUntil.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'baseProductId': baseProductId,
      'baseProductName': baseProductName,
      'baseProductUnit': baseProductUnit,
      'discounts': discounts.map((d) => d.toMap()).toList(), // NEW
      'nonDiscountableProductIds': nonDiscountableProductIds, // NEW
      'permits': permits.map((p) => p.toMap()).toList(), // NEW
      'noPermitsRequired': noPermitsRequired, // NEW
      'customLineItems': customLineItems.map((c) => c.toMap()).toList(), // NEW
    };
  }

  factory SimplifiedMultiLevelQuote.fromMap(Map<String, dynamic> map) {
    return SimplifiedMultiLevelQuote(
      id: map['id'],
      customerId: map['customerId'] ?? '',
      roofScopeDataId: map['roofScopeDataId'],
      quoteNumber: map['quoteNumber'] ?? 'SQ-${DateTime.now().millisecondsSinceEpoch}',
      levels: (map['levels'] as List<dynamic>?)
          ?.map((levelData) => QuoteLevel.fromMap(levelData as Map<String, dynamic>))
          .toList() ??
          [],
      addons: (map['addons'] as List<dynamic>?)
          ?.map((addonData) => QuoteItem.fromMap(addonData as Map<String, dynamic>))
          .toList() ??
          [],
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0, // Keep for backward compatibility
      status: map['status'] ?? 'draft',
      previousStatus: map['previousStatus'], // NEW
      notes: map['notes'],
      validUntil: map['validUntil'] != null ? DateTime.parse(map['validUntil']) : DateTime.now().add(const Duration(days: 30)),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      baseProductId: map['baseProductId'],
      baseProductName: map['baseProductName'],
      baseProductUnit: map['baseProductUnit'],
      discounts: (map['discounts'] as List<dynamic>?)
          ?.map((discountData) => QuoteDiscount.fromMap(discountData as Map<String, dynamic>))
          .toList() ??
          [], // NEW
      nonDiscountableProductIds: List<String>.from(map['nonDiscountableProductIds'] ?? []), // NEW
      permits: (map['permits'] as List<dynamic>?)
          ?.map((permitData) => PermitItem.fromMap(permitData as Map<String, dynamic>))
          .toList() ??
          [], // NEW
      noPermitsRequired: map['noPermitsRequired'] ?? false, // NEW
      customLineItems: (map['customLineItems'] as List<dynamic>?)
          ?.map((customData) => CustomLineItem.fromMap(customData as Map<String, dynamic>))
          .toList() ??
          [], // NEW
    );
  }

  // PDF STATE AWARENESS METHODS

  /// Check if the quote has a PDF generated
  bool get hasPdf => pdfPath != null && pdfPath!.isNotEmpty;

  /// Check if the PDF is outdated (quote was modified after PDF generation)
  bool get isPdfOutdated {
    if (!hasPdf || pdfGeneratedAt == null) return false;
    return updatedAt.isAfter(pdfGeneratedAt!);
  }

  /// Check if the PDF is current (exists and not outdated)
  bool get isPdfCurrent => hasPdf && !isPdfOutdated;

  /// Get PDF status for UI indicators
  String get pdfStatusIndicator {
    if (!hasPdf) return 'no_pdf';
    if (isPdfOutdated) return 'outdated';
    return 'current';
  }

  /// Get user-friendly PDF status text
  String get pdfStatusText {
    switch (pdfStatusIndicator) {
      case 'no_pdf':
        return 'No PDF generated';
      case 'outdated':
        return 'PDF outdated - quote modified';
      case 'current':
        return 'PDF up to date';
      default:
        return 'Unknown PDF status';
    }
  }

  /// Get appropriate action text based on PDF state
  String get pdfActionText {
    switch (pdfStatusIndicator) {
      case 'no_pdf':
      case 'outdated':
        return 'Generate PDF';
      case 'current':
        return 'Preview PDF';
      default:
        return 'PDF';
    }
  }

  /// Check if quote can be edited (business rule: only current versions)
  bool get canEdit => isCurrentVersion;

  /// Check if editing this quote should trigger versioning
  bool shouldCreateVersionOnEdit({String? currentStatus}) {
    final checkStatus = currentStatus ?? status;
    // Create version if quote was sent or accepted
    return checkStatus == 'sent' || checkStatus == 'accepted';
  }

  @override
  String toString() {
    return 'SimplifiedMultiLevelQuote(id: $id, quoteNumber: $quoteNumber, v$version, levels: ${levels.length}, discounts: ${discounts.length}, status: $status)';
  }
}