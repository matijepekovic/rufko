import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/quote_form/quote_form_service.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/roof_scope_data.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/quote.dart';
import '../../../../data/models/business/quote_extras.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../app/constants/quote_form_constants.dart';

/// UI Controller for quote form operations
/// Handles state management and event emission without UI concerns
class QuoteFormUIController extends ChangeNotifier {
  QuoteFormUIController({
    required this.customer,
    required AppStateProvider appState,
    this.roofScopeData,
    this.existingQuote,
  }) : _appState = appState, _service = QuoteFormService() {
    _initializeForm();
  }

  final Customer customer;
  final RoofScopeData? roofScopeData;
  final SimplifiedMultiLevelQuote? existingQuote;
  final AppStateProvider _appState;
  final QuoteFormService _service;

  // Form state
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
  String? _lastError;
  String? _lastSuccess;

  // Getters
  bool get isEditMode => existingQuote != null;
  SimplifiedMultiLevelQuote? get editingQuote => existingQuote;
  double get taxRate => _taxRate;
  Product? get mainProduct => _mainProduct;
  double get mainQuantity => _mainQuantity;
  List<QuoteLevel> get quoteLevels => List.unmodifiable(_quoteLevels);
  List<QuoteItem> get addedProducts => List.unmodifiable(_addedProducts);
  List<PermitItem> get permits => List.unmodifiable(_permits);
  bool get noPermitsRequired => _noPermitsRequired;
  List<CustomLineItem> get customLineItems => List.unmodifiable(_customLineItems);
  String get quoteType => _quoteType;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  bool get isPermitsRequirementSatisfied => _noPermitsRequired || _permits.isNotEmpty;

  /// Factory constructor for easy creation with context
  factory QuoteFormUIController.fromContext({
    required BuildContext context,
    required Customer customer,
    RoofScopeData? roofScopeData,
    SimplifiedMultiLevelQuote? existingQuote,
  }) {
    return QuoteFormUIController(
      customer: customer,
      appState: context.read<AppStateProvider>(),
      roofScopeData: roofScopeData,
      existingQuote: existingQuote,
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _lastSuccess = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _lastSuccess = success;
    _lastError = null;
    notifyListeners();
  }

  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();
  }

  void _initializeForm() {
    if (existingQuote != null) {
      loadExistingQuoteData();
    }
  }

  /// Update tax rate
  void setTaxRate(double value) {
    _taxRate = value;
    _updateQuoteLevelsQuantity();
    notifyListeners();
  }

  /// Update main product
  void setMainProduct(Product? value) {
    _mainProduct = value;
    if (value != null) {
      createQuoteLevels();
    }
    notifyListeners();
  }

  /// Update main quantity
  void setMainQuantity(double value) {
    _mainQuantity = value;
    _updateQuoteLevelsQuantity();
    notifyListeners();
  }

  /// Set no permits required
  void setNoPermitsRequired(bool value) {
    _noPermitsRequired = value;
    // Clear permits when no permits are required
    if (value) {
      _permits.clear();
    }
    notifyListeners();
  }

  /// Set quote type
  void setQuoteType(String type) {
    _quoteType = type;
    if (_mainProduct != null) {
      createQuoteLevels();
    }
    notifyListeners();
  }

  /// Create quote levels based on current settings
  void createQuoteLevels() {
    if (_mainProduct == null) return;

    _quoteLevels.clear();
    _quoteLevels.addAll(_service.createQuoteLevels(
      mainProduct: _mainProduct!,
      mainQuantity: _mainQuantity,
      quoteType: _quoteType,
      addedProducts: _addedProducts,
    ));
    notifyListeners();
  }

  /// Update quote levels quantity
  void _updateQuoteLevelsQuantity() {
    for (final level in _quoteLevels) {
      level.baseQuantity = _mainQuantity;
      level.calculateSubtotal();
    }
    notifyListeners();
  }

  /// Add permit
  void addPermit(PermitItem permit) {
    _permits.add(permit);
    notifyListeners();
  }

  /// Remove permit
  void removePermit(PermitItem permit) {
    _permits.remove(permit);
    notifyListeners();
  }

  /// Add custom line item
  void addCustomLineItem(CustomLineItem item) {
    _customLineItems.add(item);
    notifyListeners();
  }

  /// Remove custom line item
  void removeCustomLineItem(CustomLineItem item) {
    _customLineItems.remove(item);
    notifyListeners();
  }

  /// Add product
  void addProduct(QuoteItem item) {
    _addedProducts.add(item);
    for (final level in _quoteLevels) {
      level.includedItems.add(item);
      level.calculateSubtotal();
    }
    notifyListeners();
  }

  /// Remove product
  void removeProduct(QuoteItem item) {
    _addedProducts.remove(item);
    for (final level in _quoteLevels) {
      level.includedItems.remove(item);
      level.calculateSubtotal();
    }
    notifyListeners();
  }

  /// Auto-detect tax rate
  Future<bool> autoDetectTaxRate() async {
    final result = _service.detectTaxRate(
      customer: customer,
      appState: _appState,
    );

    if (result.isSuccess && result.detectedTaxRate != null) {
      _taxRate = result.detectedTaxRate!;
      _updateQuoteLevelsQuantity();
      _setSuccess(result.successMessage);
      return true;
    } else {
      if (result.errorMessage == 'Manual tax rate entry required') {
        // This will trigger manual tax rate dialog in the handler
        _setError(result.errorMessage);
        return false;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    }
  }

  /// Load existing quote data
  void loadExistingQuoteData() {
    if (existingQuote == null) return;

    try {
      final data = _service.loadExistingQuoteData(
        existingQuote: existingQuote!,
        availableProducts: _appState.products,
      );

      _taxRate = data['taxRate'];
      _quoteType = data['quoteType'];
      _mainProduct = data['mainProduct'];
      _mainQuantity = data['mainQuantity'];
      
      _quoteLevels.clear();
      _quoteLevels.addAll(data['quoteLevels']);
      
      _addedProducts.clear();
      _addedProducts.addAll(data['addedProducts']);
      
      _permits.clear();
      _permits.addAll(data['permits']);
      
      _noPermitsRequired = data['noPermitsRequired'];
      
      _customLineItems.clear();
      _customLineItems.addAll(data['customLineItems']);

      notifyListeners();
    } catch (e) {
      _setError('Failed to load existing quote data: $e');
    }
  }

  /// Generate or update quote
  Future<SimplifiedMultiLevelQuote?> generateQuote() async {
    // Validate form
    final validation = _service.validateQuoteForm(
      mainProduct: _mainProduct,
      quoteLevels: _quoteLevels,
      isPermitsRequirementSatisfied: isPermitsRequirementSatisfied,
    );

    if (!validation.isSuccess) {
      _setError(validation.errorMessage);
      return null;
    }

    _setLoading(true);

    try {
      QuoteFormOperationResult result;

      if (isEditMode) {
        result = await _service.updateQuote(
          existingQuote: existingQuote!,
          mainProduct: _mainProduct!,
          quoteLevels: _quoteLevels,
          taxRate: _taxRate,
          permits: _permits,
          noPermitsRequired: _noPermitsRequired,
          customLineItems: _customLineItems,
          quoteType: _quoteType,
          roofScopeData: roofScopeData,
          appState: _appState,
        );
      } else {
        result = await _service.createQuote(
          customer: customer,
          mainProduct: _mainProduct!,
          mainQuantity: _mainQuantity,
          quoteLevels: _quoteLevels,
          taxRate: _taxRate,
          permits: _permits,
          noPermitsRequired: _noPermitsRequired,
          customLineItems: _customLineItems,
          quoteType: _quoteType,
          roofScopeData: roofScopeData,
          appState: _appState,
        );
      }

      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        return result.quote;
      } else {
        _setError(result.errorMessage);
        return null;
      }
    } finally {
      _setLoading(false);
    }
  }
}