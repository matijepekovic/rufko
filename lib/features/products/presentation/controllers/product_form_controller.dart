import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/business/product.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/products/product_form_service.dart';
import '../../../../core/services/products/product_validation_service.dart';
import '../../../../core/services/products/product_persistence_service.dart';

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
  
  // NEW: Photo and inventory state
  bool _hasInventory = false;
  String? _photoPath;

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
  
  // NEW: Photo and inventory getters
  bool get hasInventory => _hasInventory;
  String? get photoPath => _photoPath;

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
  
  // NEW: Photo and inventory setters
  set hasInventory(bool value) {
    _hasInventory = value;
    notifyListeners();
  }
  
  set photoPath(String? value) {
    _photoPath = value;
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
    
    // NEW: Initialize photo and inventory state
    _hasInventory = product.hasInventory;
    _photoPath = product.photoPath;

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
    // Business logic extracted to service
    final defaultLevels = ProductFormService.initializeMainDifferentiatorLevels(appState);
    
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
    // Business logic extracted to service
    final defaultSubLevels = ProductFormService.initializeSubLeveledLevels();
    
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
    // Business logic extracted to service
    return ProductFormService.canRemoveLevel(_pricingType, _currentLevelKeys.length);
  }

  /// Check if level can be added
  bool canAddLevel() {
    // Business logic extracted to service
    return ProductFormService.canAddLevel(_pricingType, _currentLevelKeys.length);
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
    // Business logic extracted to service
    final levelNames = Map<String, String>.fromEntries(
      _levelNameControllers.entries.map((e) => MapEntry(e.key, e.value.text))
    );
    
    return ProductValidationService.validateLevels(
      pricingType: _pricingType,
      levelNames: levelNames,
      currentLevelKeys: _currentLevelKeys,
    );
  }

  /// Save product
  Future<bool> saveProduct() async {
    if (!validateForm()) {
      return false;
    }

    try {
      final appState = context.read<AppStateProvider>();
      
      // Prepare data for service layer
      final levelNames = Map<String, String>.fromEntries(
        _levelNameControllers.entries.map((e) => MapEntry(e.key, e.value.text))
      );
      final levelDescriptions = Map<String, String>.fromEntries(
        _levelDescriptionControllers.entries.map((e) => MapEntry(e.key, e.value.text))
      );
      final levelPrices = Map<String, String>.fromEntries(
        _levelPriceControllers.entries.map((e) => MapEntry(e.key, e.value.text))
      );
      
      final ProductPersistenceResult result;
      
      if (isEditing) {
        // Business logic extracted to service
        result = await ProductPersistenceService.updateExistingProduct(
          existingProduct: initialProduct!,
          appState: appState,
          name: nameController.text,
          description: descriptionController.text,
          unitPrice: double.parse(basePriceController.text),
          category: _selectedCategory,
          unit: _selectedUnit,
          isActive: _isActive,
          isDiscountable: _isDiscountable,
          pricingType: _pricingType,
          hasInventory: _hasInventory,
          photoPath: _photoPath,
          levelNames: levelNames,
          levelDescriptions: levelDescriptions,
          levelPrices: levelPrices,
          currentLevelKeys: _currentLevelKeys,
        );
      } else {
        // Business logic extracted to service
        result = await ProductPersistenceService.createNewProduct(
          appState: appState,
          name: nameController.text,
          description: descriptionController.text,
          unitPrice: double.parse(basePriceController.text),
          category: _selectedCategory,
          unit: _selectedUnit,
          isActive: _isActive,
          isDiscountable: _isDiscountable,
          pricingType: _pricingType,
          hasInventory: _hasInventory,
          photoPath: _photoPath,
          levelNames: levelNames,
          levelDescriptions: levelDescriptions,
          levelPrices: levelPrices,
          currentLevelKeys: _currentLevelKeys,
        );
      }
      
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }


  /// Get pricing type description
  String getPricingTypeDescription() {
    // Business logic extracted to service
    return ProductFormService.getPricingTypeDescription(_pricingType);
  }

  /// NEW: Pick product photo from camera or gallery
  Future<void> pickProductPhoto() async {
    try {
      // Show photo picker dialog
      final ImageSource? source = await _showPhotoSourceDialog();
      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _photoPath = image.path;
        notifyListeners();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product photo added'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// NEW: Remove product photo
  void removeProductPhoto() {
    _photoPath = null;
    notifyListeners();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product photo removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// NEW: Show photo source selection dialog
  Future<ImageSource?> _showPhotoSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Photo Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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