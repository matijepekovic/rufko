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

class QuoteFormController extends ChangeNotifier {
  QuoteFormController({
    required this.context,
    required this.customer,
    this.roofScopeData,
    this.existingQuote,
  }) : appState = context.read<AppStateProvider>();

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
    notifyListeners();
  }

  Product? get mainProduct => _mainProduct;
  set mainProduct(Product? value) {
    _mainProduct = value;
    notifyListeners();
  }

  double get mainQuantity => _mainQuantity;
  set mainQuantity(double value) {
    _mainQuantity = value;
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
    if (_mainProduct == null) return;

    _quoteLevels.clear();

    if (_quoteType == 'multi-level') {
      final mainLevels = _mainProduct!.availableMainLevels;
      for (var i = 0; i < mainLevels.length; i++) {
        final mainLevel = mainLevels[i];
        final quoteLevel = QuoteLevel(
          id: mainLevel.levelId,
          name: mainLevel.levelName,
          levelNumber: i + 1,
          basePrice: mainLevel.price,
          baseQuantity: _mainQuantity,
          includedItems: List.from(_addedProducts),
        );
        quoteLevel.calculateSubtotal();
        _quoteLevels.add(quoteLevel);
      }
    } else {
      final quoteLevel = QuoteLevel(
        id: 'single-tier-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Quote',
        levelNumber: 1,
        basePrice: _mainProduct!.unitPrice,
        baseQuantity: _mainQuantity,
        includedItems: List.from(_addedProducts),
      );
      quoteLevel.calculateSubtotal();
      _quoteLevels.add(quoteLevel);
    }
    notifyListeners();
  }

  void switchQuoteType(String newType) {
    if (_quoteType == newType) return;

    _quoteType = newType;
    _mainProduct = null;
    _quoteLevels.clear();
    _addedProducts.clear();
    _mainQuantity = QuoteFormConstants.defaultMainQuantity;
    _permits.clear();
    _noPermitsRequired = false;
    _customLineItems.clear();
    notifyListeners();
  }

  void updateQuoteLevelsQuantity() {
    for (final level in _quoteLevels) {
      level.baseQuantity = _mainQuantity;
      level.calculateSubtotal();
    }
    notifyListeners();
  }

  void removeProduct(QuoteItem product) {
    _addedProducts.remove(product);
    for (final level in _quoteLevels) {
      level.includedItems.remove(product);
      level.calculateSubtotal();
    }
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
    for (final level in _quoteLevels) {
      level.includedItems.add(item);
      level.calculateSubtotal();
    }
    notifyListeners();
  }

  void autoDetectTaxRate() {
    final c = customer;
    final detectedRate = appState.detectTaxRate(
      city: c.city,
      stateAbbreviation: c.stateAbbreviation,
      zipCode: c.zipCode,
    );

    if (detectedRate != null && detectedRate > 0) {
      _taxRate = detectedRate;
      updateQuoteLevelsQuantity();
      String source = '';
      if (c.zipCode != null && c.zipCode!.isNotEmpty) {
        source = 'ZIP ${c.zipCode}';
      } else if (c.stateAbbreviation != null) {
        source = 'state ${c.stateAbbreviation}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Tax rate set to ${detectedRate.toStringAsFixed(2)}% from $source'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final fallbackRate =
          appState.appSettings?.taxRate ?? QuoteFormConstants.defaultTaxRate;
      if (fallbackRate > 0) {
        _taxRate = fallbackRate;
        updateQuoteLevelsQuantity();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default tax rate: ${fallbackRate.toStringAsFixed(2)}%'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        TaxRateDialogs.showManualTaxRateDialog(
          context,
          customer,
          this,
        );
      }
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

    if (_mainProduct == null || _quoteLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a main product first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (isEditMode) {
        final updatedQuote = editingQuote!;
        updatedQuote.levels = _quoteLevels.map((level) {
          level.calculateSubtotal();
          return level;
        }).toList();
        updatedQuote.taxRate = _taxRate;
        updatedQuote.baseProductId = _mainProduct!.id;
        updatedQuote.baseProductName = _mainProduct!.name;
        updatedQuote.baseProductUnit = _mainProduct!.unit;
        updatedQuote.roofScopeDataId = roofScopeData?.id;
        updatedQuote.permits = List.from(_permits);
        updatedQuote.noPermitsRequired = _noPermitsRequired;
        updatedQuote.customLineItems = List.from(_customLineItems);
        updatedQuote.updatedAt = DateTime.now();

        await appState.updateSimplifiedQuote(updatedQuote);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_quoteType == 'single-tier' ? 'Single-tier' : 'Multi-level'} quote ${updatedQuote.quoteNumber} updated with ${_taxRate.toStringAsFixed(2)}% tax!'),
            backgroundColor: Colors.green,
          ),
        );

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SimplifiedQuoteDetailScreen(
              quote: updatedQuote,
              customer: customer,
            ),
          ),
        );
      } else {
        final newQuote = SimplifiedMultiLevelQuote(
          customerId: customer.id,
          roofScopeDataId: roofScopeData?.id,
          levels: _quoteLevels.map((level) {
            level.calculateSubtotal();
            return level;
          }).toList(),
          addons: [],
          taxRate: _taxRate,
          baseProductId: _mainProduct!.id,
          baseProductName: _mainProduct!.name,
          baseProductUnit: _mainProduct!.unit,
          permits: List.from(_permits),
          noPermitsRequired: _noPermitsRequired,
          customLineItems: List.from(_customLineItems),
        );

        await appState.addSimplifiedQuote(newQuote);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_quoteType == 'single-tier' ? 'Single-tier' : 'Multi-level'} quote ${newQuote.quoteNumber} generated with ${_taxRate.toStringAsFixed(2)}% tax!'),
            backgroundColor: Colors.green,
          ),
        );

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SimplifiedQuoteDetailScreen(
              quote: newQuote,
              customer: customer,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode
              ? 'Error updating ${_quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e'
              : 'Error generating ${_quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

