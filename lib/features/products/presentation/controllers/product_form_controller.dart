import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/product.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for managing product form state and operations
/// Extracted from ProductFormDialog to separate business logic from UI
class ProductFormController extends ChangeNotifier {
  final BuildContext context;
  final Product? initialProduct;

  // Form key and controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController basePriceController = TextEditingController();

  // Basic form state
  String _selectedCategory = 'Materials';
  String _selectedUnit = 'each';
  bool _isActive = true;
  bool _isDiscountable = true;
  bool _settingsExpanded = false;

  // Pricing type state
  ProductPricingType _pricingType = ProductPricingType.simple;
  bool _isMainDifferentiator = false;

  // Level management
  final Map<String, TextEditingController> _levelPriceControllers = {};
  final Map<String, TextEditingController> _levelNameControllers = {};
  final Map<String, TextEditingController> _levelDescriptionControllers = {};
  final List<String> _currentLevelKeys = [];
  bool _isInitialized = false;

  ProductFormController({
    required this.context,
    this.initialProduct,
  }) {
    _initializeFormData();
  }

  // Getters
  bool get isEditing => initialProduct != null;
  String get selectedCategory => _selectedCategory;
  String get selectedUnit => _selectedUnit;
  bool get isActive => _isActive;
  bool get isDiscountable => _isDiscountable;
  bool get settingsExpanded => _settingsExpanded;
  ProductPricingType get pricingType => _pricingType;
  bool get isMainDifferentiator => _isMainDifferentiator;
  List<String> get currentLevelKeys => _currentLevelKeys;
  bool get isInitialized => _isInitialized;
  Map<String, TextEditingController> get levelPriceControllers => _levelPriceControllers;
  Map<String, TextEditingController> get levelNameControllers => _levelNameControllers;
  Map<String, TextEditingController> get levelDescriptionControllers => _levelDescriptionControllers;

  // Setters with notification
  set selectedCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  set selectedUnit(String value) {
    _selectedUnit = value;
    notifyListeners();
  }

  set isActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  set isDiscountable(bool value) {
    _isDiscountable = value;
    notifyListeners();
  }

  set settingsExpanded(bool value) {
    _settingsExpanded = value;
    notifyListeners();
  }

  set pricingType(ProductPricingType value) {
    _pricingType = value;
    _isMainDifferentiator = value == ProductPricingType.mainDifferentiator;
    _initializeLevelsForPricingType();
    notifyListeners();
  }

  /// Initialize form data from existing product or defaults
  void _initializeFormData() {
    if (initialProduct != null) {
      _initializeFromExistingProduct();
    } else {
      _initializeForNewProduct();
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Initialize form from existing product
  void _initializeFromExistingProduct() {
    final product = initialProduct!;
    
    nameController.text = product.name;
    descriptionController.text = product.description ?? '';
    basePriceController.text = product.unitPrice.toString();
    
    _selectedCategory = product.category;
    _selectedUnit = product.unit;
    _isActive = product.isActive;
    _isDiscountable = product.isDiscountable;
    _pricingType = product.pricingType;
    _isMainDifferentiator = product.pricingType == ProductPricingType.mainDifferentiator;

    // Initialize level controllers from existing product
    _initializeLevelControllersFromProduct(product);
  }

  /// Initialize form for new product
  void _initializeForNewProduct() {
    _pricingType = ProductPricingType.simple;
    _isMainDifferentiator = false;
    _initializeLevelsForPricingType();
  }

  /// Initialize level controllers from existing product
  void _initializeLevelControllersFromProduct(Product product) {
    _currentLevelKeys.clear();
    _clearLevelControllers();

    if (product.enhancedLevelPrices.isNotEmpty) {
      for (int i = 0; i < product.enhancedLevelPrices.length; i++) {
        final levelPrice = product.enhancedLevelPrices[i];
        final levelKey = 'level_$i';
        _currentLevelKeys.add(levelKey);

        _levelNameControllers[levelKey] = TextEditingController(text: levelPrice.levelName);
        _levelDescriptionControllers[levelKey] = TextEditingController(text: levelPrice.description ?? '');
        _levelPriceControllers[levelKey] = TextEditingController(
          text: levelPrice.price.toString()
        );
      }
    } else {
      _initializeLevelsForPricingType();
    }
  }

  /// Initialize levels based on pricing type
  void _initializeLevelsForPricingType() {
    _clearLevelControllers();
    _currentLevelKeys.clear();

    final appState = context.read<AppStateProvider>();
    
    switch (_pricingType) {
      case ProductPricingType.mainDifferentiator:
        _initializeMainDifferentiatorLevels(appState);
        break;
      case ProductPricingType.subLeveled:
        _initializeSubLeveledLevels();
        break;
      case ProductPricingType.simple:
        // Simple type doesn't use levels
        break;
    }
  }

  /// Initialize main differentiator levels from app settings
  void _initializeMainDifferentiatorLevels(AppStateProvider appState) {
    final defaultLevels = appState.appSettings?.defaultQuoteLevelNames ?? 
                         ['Builder', 'Standard', 'Premium'];
    
    for (int i = 0; i < defaultLevels.length; i++) {
      final levelKey = 'level_$i';
      _currentLevelKeys.add(levelKey);
      
      _levelNameControllers[levelKey] = TextEditingController(text: defaultLevels[i]);
      _levelDescriptionControllers[levelKey] = TextEditingController();
      _levelPriceControllers[levelKey] = TextEditingController();
    }
  }

  /// Initialize sub-leveled levels with defaults
  void _initializeSubLeveledLevels() {
    const defaultSubLevels = ['Basic', 'Premium'];
    
    for (int i = 0; i < defaultSubLevels.length; i++) {
      final levelKey = 'level_$i';
      _currentLevelKeys.add(levelKey);
      
      _levelNameControllers[levelKey] = TextEditingController(text: defaultSubLevels[i]);
      _levelDescriptionControllers[levelKey] = TextEditingController();
      _levelPriceControllers[levelKey] = TextEditingController();
    }
  }

  /// Clear all level controllers
  void _clearLevelControllers() {
    for (final controller in _levelPriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _levelNameControllers.values) {
      controller.dispose();
    }
    for (final controller in _levelDescriptionControllers.values) {
      controller.dispose();
    }
    
    _levelPriceControllers.clear();
    _levelNameControllers.clear();
    _levelDescriptionControllers.clear();
  }

  /// Add new level
  void addLevel() {
    final newLevelKey = 'level_${_currentLevelKeys.length}';
    _currentLevelKeys.add(newLevelKey);
    
    _levelNameControllers[newLevelKey] = TextEditingController();
    _levelDescriptionControllers[newLevelKey] = TextEditingController();
    _levelPriceControllers[newLevelKey] = TextEditingController();
    
    notifyListeners();
  }

  /// Remove level at index
  void removeLevel(int index) {
    if (index < 0 || index >= _currentLevelKeys.length) return;
    if (!canRemoveLevel()) return;

    final levelKey = _currentLevelKeys[index];
    
    // Dispose controllers
    _levelNameControllers[levelKey]?.dispose();
    _levelDescriptionControllers[levelKey]?.dispose();
    _levelPriceControllers[levelKey]?.dispose();
    
    // Remove from maps and list
    _levelNameControllers.remove(levelKey);
    _levelDescriptionControllers.remove(levelKey);
    _levelPriceControllers.remove(levelKey);
    _currentLevelKeys.removeAt(index);
    
    notifyListeners();
  }

  /// Check if level can be removed
  bool canRemoveLevel() {
    switch (_pricingType) {
      case ProductPricingType.mainDifferentiator:
        return _currentLevelKeys.length > 2;
      case ProductPricingType.subLeveled:
        return _currentLevelKeys.length > 2;
      case ProductPricingType.simple:
        return false;
    }
  }

  /// Check if level can be added
  bool canAddLevel() {
    switch (_pricingType) {
      case ProductPricingType.mainDifferentiator:
        return _currentLevelKeys.length < 6;
      case ProductPricingType.subLeveled:
        return _currentLevelKeys.length < 4;
      case ProductPricingType.simple:
        return false;
    }
  }

  /// Validate form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    // Validate levels if applicable
    if (_pricingType != ProductPricingType.simple) {
      return validateLevels();
    }

    return true;
  }

  /// Validate levels
  bool validateLevels() {
    for (final levelKey in _currentLevelKeys) {
      final nameController = _levelNameControllers[levelKey];
      if (nameController?.text.trim().isEmpty ?? true) {
        return false;
      }
    }
    return true;
  }

  /// Save product
  Future<bool> saveProduct() async {
    if (!validateForm()) {
      return false;
    }

    try {
      final appState = context.read<AppStateProvider>();
      
      if (isEditing) {
        await _updateExistingProduct(appState);
      } else {
        await _createNewProduct(appState);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update existing product
  Future<void> _updateExistingProduct(AppStateProvider appState) async {
    final product = initialProduct!;
    
    product.updateInfo(
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      unitPrice: double.parse(basePriceController.text),
      category: _selectedCategory,
      unit: _selectedUnit,
      isActive: _isActive,
      isDiscountable: _isDiscountable,
      isMainDifferentiator: _pricingType == ProductPricingType.mainDifferentiator,
      enableLevelPricing: _pricingType != ProductPricingType.simple,
    );

    // Update level prices
    _updateProductLevels(product);
    
    await appState.updateProduct(product);
  }

  /// Create new product
  Future<void> _createNewProduct(AppStateProvider appState) async {
    final product = Product(
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      unitPrice: double.parse(basePriceController.text),
      category: _selectedCategory,
      unit: _selectedUnit,
      isActive: _isActive,
      isDiscountable: _isDiscountable,
      isMainDifferentiator: _pricingType == ProductPricingType.mainDifferentiator,
      enableLevelPricing: _pricingType != ProductPricingType.simple,
      pricingType: _pricingType,
    );

    // Add level prices
    _updateProductLevels(product);
    
    await appState.addProduct(product);
  }

  /// Update product levels
  void _updateProductLevels(Product product) {
    product.enhancedLevelPrices.clear();
    
    if (_pricingType != ProductPricingType.simple) {
      for (final levelKey in _currentLevelKeys) {
        final nameController = _levelNameControllers[levelKey];
        final descriptionController = _levelDescriptionControllers[levelKey];
        final priceController = _levelPriceControllers[levelKey];
        
        if (nameController?.text.trim().isNotEmpty == true) {
          final levelPrice = ProductLevelPrice(
            levelId: levelKey,
            levelName: nameController!.text.trim(),
            description: descriptionController?.text.trim().isEmpty == true ? null : descriptionController?.text.trim(),
            price: priceController?.text.trim().isEmpty == true ? 0.0 : double.tryParse(priceController!.text) ?? 0.0,
          );
          product.enhancedLevelPrices.add(levelPrice);
        }
      }
    }
  }

  /// Get pricing type description
  String getPricingTypeDescription() {
    switch (_pricingType) {
      case ProductPricingType.mainDifferentiator:
        return 'Sets quote column headers (Builder/Standard/Premium)';
      case ProductPricingType.subLeveled:
        return 'Independent customer choices (Basic vs Mesh Gutters)';
      case ProductPricingType.simple:
        return 'Same price everywhere';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    basePriceController.dispose();
    _clearLevelControllers();
    super.dispose();
  }
}