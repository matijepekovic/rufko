import 'package:flutter/foundation.dart';
import '../models/business/simplified_quote.dart';
import '../models/business/quote.dart';
import '../models/business/quote_extras.dart';
import 'customer_test_data.dart';
import 'product_test_data.dart';

/// Test data for quote development and testing
/// This data will be populated during development but removed for production
class QuoteTestData {
  static const bool _isTestDataEnabled = kDebugMode;

  /// Generate sample quotes for testing
  static List<SimplifiedMultiLevelQuote> getSampleQuotes() {
    if (!_isTestDataEnabled) return [];

    // Get sample customers and products to use their actual IDs
    final customers = CustomerTestData.getSampleCustomers();
    final products = ProductTestData.getSampleProducts();
    
    // Find specific products by name for reference
    final shingles = products.firstWhere((p) => p.name == 'Architectural Shingles');
    final nails = products.firstWhere((p) => p.name == 'Roofing Nails');
    final felt = products.firstWhere((p) => p.name == 'Roofing Felt');
    final iceWater = products.firstWhere((p) => p.name == 'Ice & Water Shield');
    final ridgeVent = products.firstWhere((p) => p.name == 'Ridge Vent');
    final gutters = products.firstWhere((p) => p.name == 'Aluminum Gutters');
    final downspouts = products.firstWhere((p) => p.name == 'Downspouts');
    final metalRoofing = products.firstWhere((p) => p.name == 'Metal Roofing Panels');
    final laborInstall = products.firstWhere((p) => p.name == 'Labor - Installation');
    final tarp = products.firstWhere((p) => p.name == 'Tarp - Emergency Cover');
    
    return [
      // Quote 1: Multi-level residential quote with discounts
      SimplifiedMultiLevelQuote(
        customerId: customers.isNotEmpty ? customers[0].id : 'test-customer-1',
        quoteNumber: 'SQ-2024-001',
        status: 'draft',
        taxRate: 8.5,
        notes: 'Large residential project with multiple shingle options',
        baseProductId: shingles.id,
        baseProductName: shingles.name,
        baseProductUnit: shingles.unit,
        levels: [
          QuoteLevel(
            id: 'level-builder-001',
            name: 'Builder Grade',
            levelNumber: 1,
            basePrice: 12000.0,
            baseQuantity: 35.0,
            includedItems: [
              QuoteItem(
                productId: nails.id,
                productName: nails.name,
                quantity: 8.0,
                unitPrice: nails.unitPrice,
                unit: nails.unit,
                description: nails.description,
              ),
              QuoteItem(
                productId: felt.id,
                productName: felt.name,
                quantity: 40.0,
                unitPrice: felt.unitPrice,
                unit: felt.unit,
                description: felt.description,
              ),
            ],
          ),
          QuoteLevel(
            id: 'level-homeowner-001',
            name: 'Homeowner Grade',
            levelNumber: 2,
            basePrice: 18000.0,
            baseQuantity: 35.0,
            includedItems: [
              QuoteItem(
                productId: nails.id,
                productName: nails.name,
                quantity: 8.0,
                unitPrice: nails.unitPrice,
                unit: nails.unit,
                description: nails.description,
              ),
              QuoteItem(
                productId: iceWater.id,
                productName: iceWater.name,
                quantity: 15.0,
                unitPrice: iceWater.unitPrice,
                unit: iceWater.unit,
                description: iceWater.description,
              ),
            ],
          ),
          QuoteLevel(
            id: 'level-platinum-001',
            name: 'Platinum Grade',
            levelNumber: 3,
            basePrice: 25000.0,
            baseQuantity: 35.0,
            includedItems: [
              QuoteItem(
                productId: nails.id,
                productName: nails.name,
                quantity: 8.0,
                unitPrice: nails.unitPrice,
                unit: nails.unit,
                description: nails.description,
              ),
              QuoteItem(
                productId: iceWater.id,
                productName: iceWater.name,
                quantity: 20.0,
                unitPrice: iceWater.unitPrice,
                unit: iceWater.unit,
                description: 'Premium self-adhering membrane',
              ),
              QuoteItem(
                productId: ridgeVent.id,
                productName: ridgeVent.name,
                quantity: 85.0,
                unitPrice: ridgeVent.unitPrice,
                unit: ridgeVent.unit,
                description: ridgeVent.description,
              ),
            ],
          ),
        ],
        addons: [
          QuoteItem(
            productId: gutters.id,
            productName: gutters.name,
            quantity: 120.0,
            unitPrice: gutters.unitPrice,
            unit: gutters.unit,
            description: gutters.description,
          ),
          QuoteItem(
            productId: downspouts.id,
            productName: downspouts.name,
            quantity: 40.0,
            unitPrice: downspouts.unitPrice,
            unit: downspouts.unit,
            description: downspouts.description,
          ),
        ],
        discounts: [
          QuoteDiscount(
            type: 'percentage',
            value: 5.0,
            description: 'Early bird discount - 5% off',
            applyToAddons: true,
          ),
        ],
        permits: [
          PermitItem(
            name: 'Building Permit',
            amount: 450.0,
            description: 'City building permit for roof replacement',
          ),
          PermitItem(
            name: 'Construction Dumpster',
            amount: 350.0,
            description: '30-yard dumpster for debris removal',
          ),
        ],
        customLineItems: [
          CustomLineItem(
            name: 'Site Cleanup',
            amount: 300.0,
            description: 'Additional cleanup and site preparation',
          ),
        ],
        selectedLevelId: 'level-homeowner-001',
      ),

      // Quote 2: Commercial metal roofing quote
      SimplifiedMultiLevelQuote(
        customerId: 'test-customer-2',
        quoteNumber: 'SQ-2024-002',
        status: 'sent',
        taxRate: 9.0,
        notes: 'Commercial warehouse metal roofing project',
        baseProductId: metalRoofing.id,
        baseProductName: metalRoofing.name,
        baseProductUnit: 'square',
        levels: [
          QuoteLevel(
            id: 'level-galvalume-001',
            name: 'Galvalume Finish',
            levelNumber: 1,
            basePrice: 45000.0,
            baseQuantity: 85.0,
            includedItems: [
              QuoteItem(
                productId: 'test-product-fasteners',
                productName: 'Metal Roof Fasteners',
                quantity: 25.0,
                unitPrice: 65.0,
                unit: 'box',
                description: 'Self-drilling metal roof screws',
              ),
            ],
          ),
          QuoteLevel(
            id: 'level-painted-001',
            name: 'Painted Finish',
            levelNumber: 2,
            basePrice: 55000.0,
            baseQuantity: 85.0,
            includedItems: [
              QuoteItem(
                productId: 'test-product-fasteners',
                productName: 'Metal Roof Fasteners',
                quantity: 25.0,
                unitPrice: 65.0,
                unit: 'box',
                description: 'Self-drilling metal roof screws',
              ),
              QuoteItem(
                productId: 'test-product-trim',
                productName: 'Metal Roof Trim',
                quantity: 200.0,
                unitPrice: 8.50,
                unit: 'linear foot',
                description: 'Matching painted trim pieces',
              ),
            ],
          ),
        ],
        addons: [
          QuoteItem(
            productId: 'test-product-insulation',
            productName: 'Roof Insulation',
            quantity: 8500.0,
            unitPrice: 1.25,
            unit: 'square foot',
            description: 'R-30 rigid foam insulation',
          ),
        ],
        discounts: [
          QuoteDiscount(
            type: 'fixed_amount',
            value: 2500.0,
            description: 'Commercial volume discount',
            applyToAddons: false,
          ),
        ],
        permits: [
          PermitItem(
            name: 'Commercial Building Permit',
            amount: 1200.0,
            description: 'City commercial building permit',
          ),
        ],
        selectedLevelId: 'level-painted-001',
      ),

      // Quote 3: Emergency repair quote
      SimplifiedMultiLevelQuote(
        customerId: 'test-customer-3',
        quoteNumber: 'SQ-2024-003',
        status: 'accepted',
        taxRate: 8.0,
        notes: 'Emergency storm damage repair - insurance claim',
        baseProductId: 'test-product-emergency',
        baseProductName: 'Emergency Roof Repair',
        baseProductUnit: 'job',
        levels: [
          QuoteLevel(
            id: 'level-emergency-001',
            name: 'Emergency Repair',
            levelNumber: 1,
            basePrice: 3500.0,
            baseQuantity: 1.0,
            includedItems: [
              QuoteItem(
                productId: tarp.id,
                productName: tarp.name,
                quantity: 2.0,
                unitPrice: tarp.unitPrice,
                unit: tarp.unit,
                description: tarp.description,
              ),
              QuoteItem(
                productId: laborInstall.id,
                productName: laborInstall.name,
                quantity: 12.0,
                unitPrice: laborInstall.unitPrice,
                unit: laborInstall.unit,
                description: 'Emergency repair labor - after hours',
              ),
            ],
          ),
        ],
        addons: [],
        discounts: [],
        permits: [],
        customLineItems: [
          CustomLineItem(
            name: 'Emergency Service Fee',
            amount: 200.0,
            description: 'After-hours emergency service call',
            isTaxable: false,
          ),
        ],
        selectedLevelId: 'level-emergency-001',
      ),

      // Quote 4: Gutter-only project
      SimplifiedMultiLevelQuote(
        customerId: 'test-customer-4',
        quoteNumber: 'SQ-2024-004',
        status: 'draft',
        taxRate: 7.5,
        notes: 'Gutter replacement with mesh protection options',
        baseProductId: gutters.id,
        baseProductName: gutters.name,
        baseProductUnit: 'linear foot',
        levels: [
          QuoteLevel(
            id: 'level-standard-gutters',
            name: 'Standard Gutters',
            levelNumber: 1,
            basePrice: 2800.0,
            baseQuantity: 180.0,
            includedItems: [
              QuoteItem(
                productId: downspouts.id,
                productName: downspouts.name,
                quantity: 60.0,
                unitPrice: downspouts.unitPrice,
                unit: downspouts.unit,
                description: downspouts.description,
              ),
            ],
          ),
          QuoteLevel(
            id: 'level-mesh-gutters',
            name: 'With Mesh Protection',
            levelNumber: 2,
            basePrice: 3600.0,
            baseQuantity: 180.0,
            includedItems: [
              QuoteItem(
                productId: downspouts.id,
                productName: downspouts.name,
                quantity: 60.0,
                unitPrice: downspouts.unitPrice,
                unit: downspouts.unit,
                description: downspouts.description,
              ),
              QuoteItem(
                productId: 'test-product-mesh',
                productName: 'Gutter Mesh Protection',
                quantity: 180.0,
                unitPrice: 4.25,
                unit: 'linear foot',
                description: 'Leaf and debris protection mesh',
              ),
            ],
          ),
        ],
        addons: [
          QuoteItem(
            productId: 'test-product-cleanup',
            productName: 'Old Gutter Removal',
            quantity: 1.0,
            unitPrice: 450.0,
            unit: 'job',
            description: 'Remove and dispose of existing gutters',
          ),
        ],
        discounts: [],
        permits: [],
        customLineItems: [],
        selectedLevelId: 'level-mesh-gutters',
      ),

      // Quote 5: Large commercial project with multiple discounts
      SimplifiedMultiLevelQuote(
        customerId: 'test-customer-5',
        quoteNumber: 'SQ-2024-005',
        status: 'sent',
        taxRate: 9.25,
        notes: 'Multi-building commercial complex - phase 1 of 3',
        baseProductId: 'test-product-membrane',
        baseProductName: 'TPO Membrane Roofing',
        baseProductUnit: 'square',
        levels: [
          QuoteLevel(
            id: 'level-standard-tpo',
            name: 'Standard TPO',
            levelNumber: 1,
            basePrice: 85000.0,
            baseQuantity: 125.0,
            includedItems: [
              QuoteItem(
                productId: 'test-product-insulation',
                productName: 'Roof Insulation',
                quantity: 12500.0,
                unitPrice: 1.25,
                unit: 'square foot',
                description: 'R-30 polyiso insulation',
              ),
              QuoteItem(
                productId: 'test-product-membrane-adhesive',
                productName: 'Membrane Adhesive',
                quantity: 45.0,
                unitPrice: 75.0,
                unit: 'gallon',
                description: 'TPO membrane bonding adhesive',
              ),
            ],
          ),
          QuoteLevel(
            id: 'level-premium-tpo',
            name: 'Premium TPO with Warranty',
            levelNumber: 2,
            basePrice: 105000.0,
            baseQuantity: 125.0,
            includedItems: [
              QuoteItem(
                productId: 'test-product-premium-insulation',
                productName: 'Premium Roof Insulation',
                quantity: 12500.0,
                unitPrice: 1.85,
                unit: 'square foot',
                description: 'R-38 premium polyiso insulation',
              ),
              QuoteItem(
                productId: 'test-product-membrane-adhesive',
                productName: 'Membrane Adhesive',
                quantity: 45.0,
                unitPrice: 75.0,
                unit: 'gallon',
                description: 'Premium TPO membrane bonding adhesive',
              ),
              QuoteItem(
                productId: 'test-product-warranty',
                productName: 'Extended Warranty',
                quantity: 1.0,
                unitPrice: 3500.0,
                unit: 'project',
                description: '20-year manufacturer warranty',
              ),
            ],
          ),
        ],
        addons: [
          QuoteItem(
            productId: 'test-product-roof-drains',
            productName: 'Roof Drains',
            quantity: 8.0,
            unitPrice: 450.0,
            unit: 'each',
            description: 'Commercial roof drain assemblies',
          ),
          QuoteItem(
            productId: 'test-product-walkway-pads',
            productName: 'Walkway Pads',
            quantity: 200.0,
            unitPrice: 12.0,
            unit: 'square foot',
            description: 'HVAC walkway protection pads',
          ),
        ],
        discounts: [
          QuoteDiscount(
            type: 'percentage',
            value: 8.0,
            description: 'Multi-building project discount',
            applyToAddons: true,
          ),
          QuoteDiscount(
            type: 'fixed_amount',
            value: 1500.0,
            description: 'Cash payment discount',
            applyToAddons: false,
          ),
        ],
        permits: [
          PermitItem(
            name: 'Commercial Roofing Permit',
            amount: 2500.0,
            description: 'City commercial roofing permit - large project',
          ),
          PermitItem(
            name: 'Environmental Impact Fee',
            amount: 800.0,
            description: 'Waste disposal environmental fee',
          ),
        ],
        customLineItems: [
          CustomLineItem(
            name: 'Project Management Fee',
            amount: 5000.0,
            description: 'Dedicated project manager for large project',
          ),
          CustomLineItem(
            name: 'Equipment Rental',
            amount: 3200.0,
            description: 'Crane and specialized equipment rental',
          ),
        ],
        selectedLevelId: 'level-premium-tpo',
        nonDiscountableProductIds: ['test-product-warranty'],
      ),

      // Quote 6: Expired quote for testing
      SimplifiedMultiLevelQuote(
        customerId: 'test-customer-6',
        quoteNumber: 'SQ-2023-099',
        status: 'sent',
        taxRate: 8.0,
        notes: 'Expired quote - customer requested new pricing',
        validUntil: DateTime.now().subtract(const Duration(days: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        baseProductId: 'test-product-shingles',
        baseProductName: 'Architectural Shingles',
        baseProductUnit: 'square',
        levels: [
          QuoteLevel(
            id: 'level-standard-expired',
            name: 'Standard Shingles',
            levelNumber: 1,
            basePrice: 8500.0,
            baseQuantity: 28.0,
            includedItems: [
              QuoteItem(
                productId: 'test-product-felt',
                productName: 'Roofing Felt',
                quantity: 30.0,
                unitPrice: 35.0,
                unit: 'roll',
                description: '15lb asphalt saturated felt paper',
              ),
            ],
          ),
        ],
        addons: [],
        discounts: [],
        permits: [],
        customLineItems: [],
        selectedLevelId: 'level-standard-expired',
      ),

      // Quote 7: Rejected quote for testing
      SimplifiedMultiLevelQuote(
        customerId: 'test-customer-7',
        quoteNumber: 'SQ-2024-006',
        status: 'rejected',
        taxRate: 8.5,
        notes: 'Customer chose another contractor - pricing too high',
        baseProductId: 'test-product-shingles',
        baseProductName: 'Architectural Shingles',
        baseProductUnit: 'square',
        levels: [
          QuoteLevel(
            id: 'level-premium-rejected',
            name: 'Premium Shingles',
            levelNumber: 1,
            basePrice: 15000.0,
            baseQuantity: 32.0,
            includedItems: [
              QuoteItem(
                productId: 'test-product-ice-water',
                productName: 'Ice & Water Shield',
                quantity: 12.0,
                unitPrice: 85.0,
                unit: 'roll',
                description: 'Premium ice and water barrier',
              ),
            ],
          ),
        ],
        addons: [
          QuoteItem(
            productId: 'test-product-gutters',
            productName: 'Aluminum Gutters',
            quantity: 95.0,
            unitPrice: 12.0,
            unit: 'linear foot',
            description: 'Premium 6-inch seamless gutters',
          ),
        ],
        discounts: [],
        permits: [
          PermitItem(
            name: 'Building Permit',
            amount: 350.0,
            description: 'Standard residential building permit',
          ),
        ],
        customLineItems: [],
        selectedLevelId: 'level-premium-rejected',
      ),
    ];
  }

  /// Get quotes for specific testing scenarios
  static List<SimplifiedMultiLevelQuote> getQuotesForScenario(String scenario) {
    if (!_isTestDataEnabled) return [];

    final allQuotes = getSampleQuotes();
    
    switch (scenario) {
      case 'draft_quotes':
        return allQuotes.where((q) => q.status == 'draft').toList();
      case 'sent_quotes':
        return allQuotes.where((q) => q.status == 'sent').toList();
      case 'accepted_quotes':
        return allQuotes.where((q) => q.status == 'accepted').toList();
      case 'rejected_quotes':
        return allQuotes.where((q) => q.status == 'rejected').toList();
      case 'expired_quotes':
        return allQuotes.where((q) => q.isExpired).toList();
      case 'multi_level_quotes':
        return allQuotes.where((q) => q.levels.length > 1).toList();
      case 'quotes_with_discounts':
        return allQuotes.where((q) => q.discounts.isNotEmpty).toList();
      case 'quotes_with_addons':
        return allQuotes.where((q) => q.addons.isNotEmpty).toList();
      case 'commercial_quotes':
        return allQuotes.where((q) => q.notes?.toLowerCase().contains('commercial') ?? false).toList();
      case 'residential_quotes':
        return allQuotes.where((q) => q.notes?.toLowerCase().contains('residential') ?? false).toList();
      case 'emergency_quotes':
        return allQuotes.where((q) => q.notes?.toLowerCase().contains('emergency') ?? false).toList();
      default:
        return allQuotes;
    }
  }

  /// Create a single test quote with specific attributes
  static SimplifiedMultiLevelQuote createTestQuote({
    String? customerId,
    String? status,
    bool hasMultipleLevels = false,
    bool hasDiscounts = false,
    bool hasAddons = false,
    bool isExpired = false,
  }) {
    if (!_isTestDataEnabled) {
      return SimplifiedMultiLevelQuote(customerId: customerId ?? 'test-customer');
    }

    final levels = <QuoteLevel>[
      QuoteLevel(
        id: 'test-level-1',
        name: 'Standard Level',
        levelNumber: 1,
        basePrice: 5000.0,
        baseQuantity: 25.0,
        includedItems: [
          QuoteItem(
            productId: 'test-product-1',
            productName: 'Test Product',
            quantity: 10.0,
            unitPrice: 50.0,
            unit: 'each',
          ),
        ],
      ),
    ];

    if (hasMultipleLevels) {
      levels.add(
        QuoteLevel(
          id: 'test-level-2',
          name: 'Premium Level',
          levelNumber: 2,
          basePrice: 7500.0,
          baseQuantity: 25.0,
          includedItems: [
            QuoteItem(
              productId: 'test-product-2',
              productName: 'Premium Test Product',
              quantity: 15.0,
              unitPrice: 75.0,
              unit: 'each',
            ),
          ],
        ),
      );
    }

    final addons = hasAddons ? [
      QuoteItem(
        productId: 'test-addon-1',
        productName: 'Test Addon',
        quantity: 5.0,
        unitPrice: 100.0,
        unit: 'each',
      ),
    ] : <QuoteItem>[];

    final discounts = hasDiscounts ? [
      QuoteDiscount(
        type: 'percentage',
        value: 10.0,
        description: 'Test discount',
      ),
    ] : <QuoteDiscount>[];

    final validUntil = isExpired 
        ? DateTime.now().subtract(const Duration(days: 10))
        : DateTime.now().add(const Duration(days: 30));

    return SimplifiedMultiLevelQuote(
      customerId: customerId ?? 'test-customer',
      quoteNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
      status: status ?? 'draft',
      levels: levels,
      addons: addons,
      discounts: discounts,
      validUntil: validUntil,
      notes: 'Test quote created for development purposes',
      selectedLevelId: levels.first.id,
    );
  }

  /// Get all available quote statuses
  static List<String> getAvailableStatuses() {
    if (!_isTestDataEnabled) return [];

    return getSampleQuotes()
        .map((q) => q.status)
        .toSet()
        .toList()
        ..sort();
  }

  /// Get quotes by status with counts
  static Map<String, List<SimplifiedMultiLevelQuote>> getQuotesByStatus() {
    if (!_isTestDataEnabled) return {};

    final allQuotes = getSampleQuotes();
    final Map<String, List<SimplifiedMultiLevelQuote>> quotesByStatus = {};

    for (final quote in allQuotes) {
      quotesByStatus.putIfAbsent(quote.status, () => []);
      quotesByStatus[quote.status]!.add(quote);
    }

    return quotesByStatus;
  }
}