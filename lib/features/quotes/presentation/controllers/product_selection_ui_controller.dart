import 'package:flutter/material.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for product selection dialog that handles all business logic
/// Separates product selection and quote item creation from UI presentation
class ProductSelectionUIController extends ChangeNotifier {
  final AppStateProvider _appStateProvider;
  final TextEditingController quantityController = TextEditingController(text: '1');
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Product? _selectedProduct;
  ProductLevelPrice? _selectedLevel;
  String _expandedCategory = '';
  bool _isLoading = false;
  String? _errorMessage;

  ProductSelectionUIController(this._appStateProvider);

  // Read-only getters for UI
  Product? get selectedProduct => _selectedProduct;
  ProductLevelPrice? get selectedLevel => _selectedLevel;
  String get expandedCategory => _expandedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Product> get availableProducts => _appStateProvider.products;

  /// Set selected product
  void selectProduct(Product product) {
    _selectedProduct = product;
    _selectedLevel = null; // Reset level when product changes
    notifyListeners();
  }

  /// Set selected product level
  void selectLevel(ProductLevelPrice level) {
    _selectedLevel = level;
    notifyListeners();
  }

  /// Set expanded category for UI
  void setExpandedCategory(String category) {
    _expandedCategory = category;
    notifyListeners();
  }

  /// Group products by category for UI display
  Map<String, List<Product>> groupProductsByCategory() {
    final grouped = <String, List<Product>>{};

    for (final product in _appStateProvider.products) {
      if (!product.isActive) continue;
      if (product.pricingType == ProductPricingType.mainDifferentiator) continue;

      final category = product.category;
      grouped.putIfAbsent(category, () => []).add(product);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final result = <String, List<Product>>{};
    for (final entry in sortedEntries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
      result[entry.key] = entry.value;
    }

    return result;
  }

  /// Get icon for category
  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'materials':
      case 'roofing':
        return Icons.roofing;
      case 'gutters':
        return Icons.water_drop;
      case 'labor':
        return Icons.engineering;
      case 'flashing':
        return Icons.flash_on;
      default:
        return Icons.category;
    }
  }

  /// Validate form and create quote item
  Future<QuoteItem?> createQuoteItem() async {
    if (!formKey.currentState!.validate()) return null;
    
    if (_selectedProduct == null) {
      _setError('Please select a product');
      return null;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Determine price to use
      double unitPrice;
      String productName = _selectedProduct!.name;

      if (_selectedProduct!.enhancedLevelPrices.isNotEmpty) {
        if (_selectedLevel == null) {
          _setError('Please select a level for this product');
          _setLoading(false);
          return null;
        }
        unitPrice = _selectedLevel!.price;
        productName += ' (${_selectedLevel!.levelName})';
      } else {
        unitPrice = _selectedProduct!.unitPrice;
      }

      final quantity = double.parse(quantityController.text);

      final quoteItem = QuoteItem(
        productId: _selectedProduct!.id,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        unit: _selectedProduct!.unit,
        description: _selectedLevel?.description,
      );

      _setLoading(false);
      return quoteItem;
    } catch (e) {
      _setError('Failed to create quote item: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Validate quantity input
  String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    final quantity = double.tryParse(value);
    if (quantity == null || quantity <= 0) {
      return 'Enter a valid quantity';
    }
    
    return null;
  }

  /// Get success message for quote item addition
  String getSuccessMessage() {
    if (_selectedProduct == null) return 'Product added to quote';
    
    String productName = _selectedProduct!.name;
    if (_selectedLevel != null) {
      productName += ' (${_selectedLevel!.levelName})';
    }
    
    return 'Added $productName to all quote levels';
  }

  /// Reset form state
  void reset() {
    _selectedProduct = null;
    _selectedLevel = null;
    _expandedCategory = '';
    quantityController.text = '1';
    _setError(null);
    _setLoading(false);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }
}