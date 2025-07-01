import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/roof_scope_data.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/quote.dart';
import '../../../../data/models/business/quote_extras.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/simplified_quote_detail_screen.dart';
import '../widgets/dialogs/tax_rate_dialogs.dart';
import '../../../../app/constants/quote_form_constants.dart';
import '../../../../core/services/quote/quote_calculation_service.dart';
import '../../../../core/services/quote/tax_detection_service.dart';
import '../../../../core/services/quote/quote_validation_service.dart';
import '../../../../core/services/quote/quote_generation_service.dart';
import '../../../../core/services/quote/quote_versioning_service.dart';
import '../widgets/dialogs/edit_reason_dialog.dart';

class QuoteFormController extends ChangeNotifier {
  QuoteFormController({
    required this.context,
    required this.customer,
    this.roofScopeData,
    this.existingQuote,
  }) : appState = context.read<AppStateProvider>() {
    // Load existing quote data if in edit mode
    if (existingQuote != null) {
      loadExistingQuoteData();
      // Create snapshot for change detection
      _originalQuote = _createQuoteSnapshot();
    }
  }

  final BuildContext context;
  final Customer customer;
  final RoofScopeData? roofScopeData;
  final SimplifiedMultiLevelQuote? existingQuote;
  final AppStateProvider appState;

  bool get isEditMode => existingQuote != null;
  SimplifiedMultiLevelQuote? get editingQuote => existingQuote;

  double _taxRate = QuoteFormConstants.defaultTaxRate;
  Product? _mainProduct;
  double _mainQuantity = QuoteFormConstants.defaultMainQuantity;
  final List<QuoteLevel> _quoteLevels = [];
  final List<QuoteItem> _addedProducts = [];
  final List<PermitItem> _permits = [];
  bool _noPermitsRequired = false;
  final List<CustomLineItem> _customLineItems = [];
  final List<QuoteDiscount> _discounts = [];
  String _quoteType = 'multi-level';
  bool _isLoading = false;
  
  // Version detection fields
  SimplifiedMultiLevelQuote? _originalQuote; // Snapshot for change detection
  final QuoteVersioningService _versioningService = QuoteVersioningService();
  VoidCallback? onVersionRequired; // Callback for version creation

  double get taxRate => _taxRate;
  set taxRate(double value) {
    _taxRate = value;
    updateQuoteLevelsQuantity();
    notifyListeners();
  }

  Product? get mainProduct => _mainProduct;
  set mainProduct(Product? value) {
    _mainProduct = value;
    if (value != null) {
      createQuoteLevels();
    }
    notifyListeners();
  }

  double get mainQuantity => _mainQuantity;
  set mainQuantity(double value) {
    _mainQuantity = value;
    updateQuoteLevelsQuantity();
    notifyListeners();
  }

  List<QuoteLevel> get quoteLevels => _quoteLevels;
  List<QuoteItem> get addedProducts => _addedProducts;
  List<PermitItem> get permits => _permits;
  bool get noPermitsRequired => _noPermitsRequired;
  set noPermitsRequired(bool value) {
    _noPermitsRequired = value;
    notifyListeners();
  }

  List<CustomLineItem> get customLineItems => _customLineItems;
  List<QuoteDiscount> get discounts => _discounts;
  String get quoteType => _quoteType;
  bool get isLoading => _isLoading;

  bool get isPermitsRequirementSatisfied =>
      _noPermitsRequired || _permits.isNotEmpty;

  void createQuoteLevels() {
    _quoteLevels.clear();
    
    // Business logic extracted to service
    final levels = QuoteCalculationService.createQuoteLevels(
      quoteType: _quoteType,
      mainProduct: _mainProduct,
      mainQuantity: _mainQuantity,
      addedProducts: _addedProducts,
    );
    
    _quoteLevels.addAll(levels);
    notifyListeners();
  }

  void switchQuoteType(String newType) {
    if (_quoteType == newType) return;

    _quoteType = newType;
    
    // Reset ALL fields when switching quote types
    _mainProduct = null;
    _mainQuantity = QuoteFormConstants.defaultMainQuantity;
    _taxRate = QuoteFormConstants.defaultTaxRate;
    _quoteLevels.clear();
    _addedProducts.clear();
    _permits.clear();
    _noPermitsRequired = false;
    _customLineItems.clear();
    
    notifyListeners();
  }

  void updateQuoteLevelsQuantity() {
    // Business logic extracted to service
    QuoteCalculationService.updateQuoteLevelsQuantity(
      quoteLevels: _quoteLevels,
      mainQuantity: _mainQuantity,
    );
    notifyListeners();
  }

  void removeProduct(QuoteItem product) {
    _addedProducts.remove(product);
    // Business logic extracted to service
    QuoteCalculationService.removeProductFromLevels(
      quoteLevels: _quoteLevels,
      product: product,
    );
    notifyListeners();
  }

  void addPermit(PermitItem permit) {
    _permits.add(permit);
    notifyListeners();
  }

  void removePermit(PermitItem permit) {
    _permits.remove(permit);
    notifyListeners();
  }

  void addCustomLineItem(CustomLineItem item) {
    _customLineItems.add(item);
    notifyListeners();
  }

  void removeCustomLineItem(CustomLineItem item) {
    _customLineItems.remove(item);
    notifyListeners();
  }

  void addProduct(QuoteItem item) {
    _addedProducts.add(item);
    
    // Business logic extracted to service
    final updatedLevels = QuoteCalculationService.addProductToLevels(
      quoteLevels: _quoteLevels,
      item: item,
      quoteType: _quoteType,
      mainProduct: _mainProduct,
      mainQuantity: _mainQuantity,
      addedProducts: _addedProducts,
    );
    
    _quoteLevels.clear();
    _quoteLevels.addAll(updatedLevels);
    notifyListeners();
  }

  void autoDetectTaxRate() {
    // Business logic extracted to service
    final result = TaxDetectionService.autoDetectTaxRate(
      customer: customer,
      appState: appState,
    );

    if (result.detectedRate != null) {
      _taxRate = result.detectedRate!;
      updateQuoteLevelsQuantity();
      
      if (result.usesFallback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default tax rate: ${result.detectedRate!.toStringAsFixed(2)}%'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Tax rate set to ${result.detectedRate!.toStringAsFixed(2)}% from ${result.source}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (result.requiresManualEntry) {
      TaxRateDialogs.showManualTaxRateDialog(
        context,
        customer,
        this,
      );
    }
    notifyListeners();
  }


  void loadExistingQuoteData() {
    if (editingQuote == null) return;

    _taxRate = editingQuote!.taxRate;
    _quoteType = editingQuote!.levels.length == 1 && editingQuote!.levels.first.name == 'Quote'
        ? 'single-tier'
        : 'multi-level';

    if (editingQuote!.baseProductId != null) {
      _mainProduct = appState.products.firstWhere(
        (p) => p.id == editingQuote!.baseProductId,
        orElse: () => throw Exception('Main product not found'),
      );
    }

    _quoteLevels.clear();
    _quoteLevels.addAll(editingQuote!.levels);

    if (_quoteLevels.isNotEmpty) {
      _mainQuantity = _quoteLevels.first.baseQuantity;
    }

    _addedProducts.clear();
    if (_quoteLevels.isNotEmpty) {
      _addedProducts.addAll(_quoteLevels.first.includedItems);
    }

    _permits.clear();
    _permits.addAll(editingQuote!.permits);
    _noPermitsRequired = editingQuote!.noPermitsRequired;

    _customLineItems.clear();
    _customLineItems.addAll(editingQuote!.customLineItems);

    _discounts.clear();
    _discounts.addAll(editingQuote!.discounts);

    notifyListeners();
  }

  Future<void> generateQuote(GlobalKey<FormState> formKey) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode
              ? 'Please fix errors before updating quote'
              : 'Please fix errors before generating quote'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Business logic extracted to validation service
    final validation = QuoteValidationService.validateQuoteData(
      quoteType: _quoteType,
      mainProduct: _mainProduct,
      quoteLevels: _quoteLevels,
      addedProducts: _addedProducts,
      isEditMode: isEditMode,
    );

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if there are any changes in edit mode
    if (isEditMode && !hasAnyChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes detected. Make changes before updating.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if versioning is required for edit mode
    print('🔍 Version check - isEditMode: $isEditMode, hasAnyChanges: $hasAnyChanges, isCurrentVersion: ${existingQuote?.isCurrentVersion}');
    if (isEditMode && hasAnyChanges && existingQuote!.isCurrentVersion) {
      print('✅ Showing version creation dialog');
      // Show edit reason dialog
      final editReasonResult = await showDialog<EditReasonResult>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return EditReasonDialog(
            title: 'Create New Version',
            subtitle: 'This quote has significant changes. Please provide a reason for creating a new version.',
            onReasonSelected: (result) {
              Navigator.of(context).pop(result);
            },
          );
        },
      );

      if (editReasonResult == null) {
        // User cancelled
        return;
      }

      // Create new version instead of updating
      _isLoading = true;
      notifyListeners();

      try {
        final versionResult = await _versioningService.createNewVersion(
          existingQuote!,
          editReasonResult.reason,
          editReasonResult.description,
        );

        if (!versionResult.isSuccess || versionResult.newQuote == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(versionResult.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Update app state with new version (proper architectural separation)
        await appState.addSimplifiedQuote(versionResult.newQuote!);
        
        // Update in-memory app state to match database (service handles DB updates)
        // Note: Don't call updateSimplifiedQuote as it triggers destructive repository.updateQuote()
        if (existingQuote!.parentQuoteId == null) {
          existingQuote!.parentQuoteId = existingQuote!.id;
          // In-memory update only - service already updated database correctly
        }

        // Update the new version with form data
        // Now safe to call updateExistingQuote since repository.updateQuote() protects new versions
        final result = await QuoteGenerationService.updateExistingQuote(
          appState: appState,
          existingQuote: versionResult.newQuote!,
          roofScopeData: roofScopeData,
          quoteLevels: _quoteLevels,
          taxRate: _taxRate,
          quoteType: _quoteType,
          mainProduct: _mainProduct,
          permits: _permits,
          noPermitsRequired: _noPermitsRequired,
          customLineItems: _customLineItems,
          discounts: _discounts,
        );

        if (!context.mounted) return;

        if (result.isSuccess) {
          final quote = result.quote!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New version v${quote.version} created for quote ${quote.quoteNumber}'),
              backgroundColor: Colors.green,
            ),
          );

          // Return to previous screen after creating new version
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final QuoteGenerationResult result;
      
      if (isEditMode) {
        // Business logic extracted to generation service
        result = await QuoteGenerationService.updateExistingQuote(
          appState: appState,
          existingQuote: editingQuote!,
          roofScopeData: roofScopeData,
          quoteLevels: _quoteLevels,
          taxRate: _taxRate,
          quoteType: _quoteType,
          mainProduct: _mainProduct,
          permits: _permits,
          noPermitsRequired: _noPermitsRequired,
          customLineItems: _customLineItems,
          discounts: _discounts,
        );
      } else {
        // Business logic extracted to generation service
        result = await QuoteGenerationService.generateNewQuote(
          appState: appState,
          customer: customer,
          roofScopeData: roofScopeData,
          quoteLevels: _quoteLevels,
          taxRate: _taxRate,
          quoteType: _quoteType,
          mainProduct: _mainProduct,
          permits: _permits,
          noPermitsRequired: _noPermitsRequired,
          customLineItems: _customLineItems,
          discounts: _discounts,
        );
      }

      if (!context.mounted) return;

      if (result.isSuccess) {
        final quote = result.quote!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode
                ? '${_quoteType == 'single-tier' ? 'Single' : 'Tiered'} quote ${quote.quoteNumber} updated with ${_taxRate.toStringAsFixed(2)}% tax!'
                : '${_quoteType == 'single-tier' ? 'Single' : 'Tiered'} quote ${quote.quoteNumber} generated with ${_taxRate.toStringAsFixed(2)}% tax!'),
            backgroundColor: Colors.green,
          ),
        );

        if (!context.mounted) return;
        
        // For edit mode, return to previous screen
        if (isEditMode) {
          Navigator.pop(context, true);
        } else {
          // For new quotes, navigate to detail screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SimplifiedQuoteDetailScreen(
                quote: quote,
                customer: customer,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addDiscount(QuoteDiscount discount) {
    _discounts.add(discount);
    notifyListeners();
  }

  void removeDiscount(String discountId) {
    _discounts.removeWhere((d) => d.id == discountId);
    notifyListeners();
  }

  // Version detection methods

  /// Check if current form data has any changes from original
  bool get hasAnyChanges {
    if (!isEditMode || _originalQuote == null) {
      print('📋 hasAnyChanges: false (isEditMode: $isEditMode, _originalQuote: $_originalQuote)');
      return false;
    }
    
    final currentSnapshot = _createQuoteSnapshot();
    final hasChanges = _versioningService.shouldCreateNewVersion(_originalQuote!, currentSnapshot);
    print('📋 hasAnyChanges: $hasChanges');
    print('📋 Original quote levels: ${_originalQuote!.levels.length}');
    print('📋 Current snapshot levels: ${currentSnapshot.levels.length}');
    print('📋 Original tax rate: ${_originalQuote!.taxRate}');
    print('📋 Current tax rate: ${currentSnapshot.taxRate}');
    
    return hasChanges;
  }

  /// Check if current form data has significant changes from original (same as hasAnyChanges now)
  bool get hasSignificantChanges => hasAnyChanges;

  /// Get a summary of changes for UI display
  Map<String, dynamic> get changesSummary {
    if (!isEditMode || _originalQuote == null) return {};
    
    final currentSnapshot = _createQuoteSnapshot();
    return _versioningService.generateChangesSummary(_originalQuote!, currentSnapshot);
  }

  /// Check if version creation should be triggered before saving
  Future<bool> checkVersionRequirement() async {
    if (!hasSignificantChanges) return true; // No versioning needed
    
    // Trigger version creation callback if set
    if (onVersionRequired != null) {
      onVersionRequired!();
      return false; // Prevent normal save until version is created
    }
    
    return true; // Allow normal save if no callback set
  }

  /// Create a snapshot of the current form state for comparison
  SimplifiedMultiLevelQuote _createQuoteSnapshot() {
    // Base the snapshot on existing quote if in edit mode, otherwise create new
    final baseQuote = existingQuote ?? SimplifiedMultiLevelQuote(
      customerId: customer.id,
      customer: customer,
    );

    // Create a copy with current form data
    return SimplifiedMultiLevelQuote(
      id: baseQuote.id,
      customerId: baseQuote.customerId,
      roofScopeDataId: baseQuote.roofScopeDataId,
      quoteNumber: baseQuote.quoteNumber,
      levels: _quoteLevels.map((level) {
        // Update level base quantity to match current main quantity
        final updatedLevel = QuoteLevel(
          id: level.id,
          name: level.name,
          levelNumber: level.levelNumber,
          basePrice: level.basePrice,
          baseQuantity: _mainQuantity, // Use current main quantity
          includedItems: List.from(level.includedItems),
          subtotal: level.subtotal,
        );
        updatedLevel.calculateSubtotal(); // Recalculate with new quantity
        return updatedLevel;
      }).toList(), // Copy current levels with updated quantities
      addons: List.from(_addedProducts), // Copy current addons
      taxRate: _taxRate, // Current tax rate
      discount: baseQuote.discount, // Keep existing discount (deprecated field)
      status: baseQuote.status,
      previousStatus: baseQuote.previousStatus,
      version: baseQuote.version,
      parentQuoteId: baseQuote.parentQuoteId,
      isCurrentVersion: baseQuote.isCurrentVersion,
      notes: baseQuote.notes,
      validUntil: baseQuote.validUntil,
      createdAt: baseQuote.createdAt,
      updatedAt: DateTime.now(), // Updated timestamp
      baseProductId: _mainProduct?.id,
      baseProductName: _mainProduct?.name,
      baseProductUnit: _mainProduct?.unit,
      discounts: List.from(_discounts), // Copy current discounts
      nonDiscountableProductIds: baseQuote.nonDiscountableProductIds,
      pdfPath: baseQuote.pdfPath,
      pdfTemplateId: baseQuote.pdfTemplateId,
      pdfGeneratedAt: baseQuote.pdfGeneratedAt,
      permits: List.from(_permits), // Copy current permits
      noPermitsRequired: _noPermitsRequired,
      customLineItems: List.from(_customLineItems), // Copy current custom items
      selectedLevelId: baseQuote.selectedLevelId,
    );
  }
}

