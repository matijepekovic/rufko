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
  String _quoteType = 'multi-level';
  bool _isLoading = false;

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SimplifiedQuoteDetailScreen(
              quote: quote,
              customer: customer,
            ),
          ),
        );
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
}

