// lib/screens/products_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state_provider.dart';
import '../models/product.dart';
// import '../widgets/product_card.dart'; // Assuming this widget will be updated or replaced
import 'excel_mapping_screen.dart';
import '../services/excel_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchField = false; // To control visibility of search field

  // Updated to use productCategories from AppSettings if available
  List<String> _categoryTabs = ['All'];

  @override
  void initState() {
    super.initState();
    _updateCategoryTabs();
    _tabController = TabController(length: _categoryTabs.length, vsync: this);

    // Listen to AppSettings changes to update tabs if categories change
    // Note: This might require AppStateProvider to notify listeners when appSettings.productCategories changes.
    // For simplicity, we'll initialize once. A more robust solution might involve a listener.
  }

  void _updateCategoryTabs() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.appSettings != null && appState.appSettings!.productCategories.isNotEmpty) {
      _categoryTabs = ['All', ...appState.appSettings!.productCategories];
    } else {
      // Fallback if appSettings or categories are not loaded/empty
      _categoryTabs = ['All', 'Roofing', 'Gutters', 'Flashing', 'Labor', 'Other'];
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If categories could change dynamically and you want the tabs to update:
    // final newCategories = Provider.of<AppStateProvider>(context).appSettings?.productCategories;
    // if (newCategories != null && !listEquals(['All', ...newCategories], _categoryTabs)) {
    //   setState(() {
    //     _categoryTabs = ['All', ...newCategories];
    //     _tabController.dispose(); // Dispose old controller
    //     _tabController = TabController(length: _categoryTabs.length, vsync: this); // Create new
    //   });
    // }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: Icon(_showSearchField ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import from Excel',
            onPressed: _importFromExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Products',
            onPressed: () => context.read<AppStateProvider>().loadAllData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categoryTabs.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (_showSearchField) // Use the new boolean
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categoryTabs.map((category) => _buildProductsList(category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'import_excel_fab',
            onPressed: _importFromExcel,
            backgroundColor: Colors.orange,
            tooltip: 'Import Products from Excel',
            child: const Icon(Icons.file_upload),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_product_fab',
            onPressed: () => _showAddProductDialog(context),
            tooltip: 'Add New Product',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(String categoryFilter) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (appState.isLoading && appState.products.isEmpty) { // Show loading if products are empty
          return const Center(child: CircularProgressIndicator());
        }

        List<Product> productsToDisplay = appState.products;

        if (categoryFilter != 'All') {
          productsToDisplay = productsToDisplay.where((p) =>
          p.category.toLowerCase() == categoryFilter.toLowerCase()
          ).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final lowerQuery = _searchQuery.toLowerCase();
          productsToDisplay = productsToDisplay.where((product) =>
          product.name.toLowerCase().contains(lowerQuery) ||
              (product.description?.toLowerCase().contains(lowerQuery) ?? false) ||
              product.category.toLowerCase().contains(lowerQuery) ||
              (product.sku?.toLowerCase().contains(lowerQuery) ?? false)
          ).toList();
        }

        productsToDisplay.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (productsToDisplay.isEmpty) {
          return Center( /* ... Your empty state widget ... */ );
        }

        return RefreshIndicator(
          onRefresh: () => appState.loadAllData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productsToDisplay.length,
            itemBuilder: (context, index) {
              final product = productsToDisplay[index];
              // Replace ProductCard with a temporary ListTile or an updated ProductCard
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text('${product.category} - \$${product.unitPrice.toStringAsFixed(2)}/${product.unit}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: product.isActive,
                        onChanged: (value) => _toggleProductStatus(product),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey), onPressed: () => _showEditProductDialog(context, product)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _showDeleteConfirmation(context, product)),
                    ],
                  ),
                  onTap: () => _showProductDetails(product),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) { // Clear search when hiding field
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _showProductDetails(Product product) {
    // ... (your existing _showProductDetails method should be mostly fine,
    // just ensure it doesn't reference deleted properties like definesLevel)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView( // Added SingleChildScrollView
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.description != null && product.description!.isNotEmpty) ...[
                Text('Description:', style: Theme.of(context).textTheme.titleSmall),
                Text(product.description!), const SizedBox(height: 12),
              ],
              Text('Base Price:', style: Theme.of(context).textTheme.titleSmall),
              Text('\$${product.unitPrice.toStringAsFixed(2)} per ${product.unit}'),
              const SizedBox(height: 12),
              Text('Category:', style: Theme.of(context).textTheme.titleSmall),
              Text(product.category),
              if (product.sku != null && product.sku!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('SKU:', style: Theme.of(context).textTheme.titleSmall), Text(product.sku!),
              ],
              const SizedBox(height: 12),
              Text('Status:', style: Theme.of(context).textTheme.titleSmall),
              Text(product.isActive ? 'Active' : 'Inactive'),
              const SizedBox(height: 12),
              Text('Is Addon:', style: Theme.of(context).textTheme.titleSmall),
              Text(product.isAddon ? 'Yes' : 'No'),
              if (product.levelPrices.isNotEmpty && product.levelPrices.keys.any((k) => k != 'base' || product.levelPrices.length > 1)) ...[
                const SizedBox(height: 12),
                Text('Level Prices:', style: Theme.of(context).textTheme.titleSmall),
                ...product.levelPrices.entries.map((entry) => Text('${entry.key}: \$${entry.value.toStringAsFixed(2)}')),
              ]
            ],
          ),
        ),
        actions: [ /* ... your actions ... */ ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) => const _ModernProductFormDialog(), // Use const if dialog is stateless
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModernProductFormDialog(product: product),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    // ... (your existing _showDeleteConfirmation method is likely fine)
  }

  void _toggleProductStatus(Product product) {
    // ... (your existing _toggleProductStatus method is likely fine)
  }

  void _importFromExcel() async {
    // ... (your existing _importFromExcel method)
    // Ensure it calls the correct AppStateProvider method for importing if that changes.
    // The call to ExcelMappingScreen will have errors due to its own issues.
    // For now, this method will show errors when navigating to ExcelMappingScreen.
    // We can simplify this later to directly use excelService.loadProductsFromExcel(filePath)
    // and then appState.importProducts(products);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final appState = context.read<AppStateProvider>();
        final excelService = ExcelService();
        appState.setLoading(true, 'Analyzing Excel file...');
        try {
          final excelStructure = await excelService.getExcelStructureForMapping(filePath); // This can throw if file is bad
          appState.setLoading(false);
          if (!mounted) return;
          final importedProductCount = await Navigator.push<int?>(
            context,
            MaterialPageRoute(builder: (context) => ExcelMappingScreen(
              filePath: filePath, // This argument is required by ExcelMappingScreen
              excelInfo: excelStructure,
              headers: List<String>.from(excelStructure['headers'] ?? []),
              levels: List<String>.from(excelStructure['potentialLevels'] ?? []), // This 'levels' concept is old
            )),
          );
          // ... (rest of your snackbar logic)
        } catch (e) { /* ... error handling ... */ }
      }
    } catch (e) { /* ... error handling ... */ }
  }
}

// --- _ModernProductFormDialog ---
class _ModernProductFormDialog extends StatefulWidget {
  final Product? product;
  const _ModernProductFormDialog({Key? key, this.product}) : super(key: key); // Added Key

  @override
  State<_ModernProductFormDialog> createState() => _ModernProductFormDialogState();
}

// --- Make sure this is within your _ProductsScreenState or wherever _ModernProductFormDialog is defined ---
// (Assuming _ModernProductFormDialog is a StatefulWidget defined within products_screen.dart)

class _ModernProductFormDialogState extends State<_ModernProductFormDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _skuController = TextEditingController();

  String _selectedCategory = 'materials';
  String _selectedUnit = 'each';
  bool _isActive = true;
  bool _isAddon = false;

  Map<String, double> _currentLevelPrices = {};
  Map<String, TextEditingController> _levelPriceControllers = {};
  final List<String> _formLevelKeys = ['basic', 'standard', 'premium'];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    for (final key in _formLevelKeys) {
      _levelPriceControllers[key] = TextEditingController();
    }

    if (_isEditing && widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _basePriceController.text = p.unitPrice.toStringAsFixed(2);
      _skuController.text = p.sku ?? '';
      _selectedCategory = p.category;
      _selectedUnit = p.unit;
      _isActive = p.isActive;
      _isAddon = p.isAddon;
      _currentLevelPrices = Map.from(p.levelPrices);

      _currentLevelPrices.forEach((levelId, price) {
        if (_levelPriceControllers.containsKey(levelId)) {
          _levelPriceControllers[levelId]!.text = price.toStringAsFixed(2);
        } else {
          _levelPriceControllers[levelId] = TextEditingController(text: price.toStringAsFixed(2));
          // Consider if _formLevelKeys should be dynamically updated if truly custom keys are found
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _skuController.dispose();
    _levelPriceControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dialog structure (from previous correct version)
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox( // Use SizedBox for better control if Column is not expanding
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isEditing ? 'Edit Product' : 'Create Product', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Basic Info'),
                Tab(text: 'Level Pricing'),
              ],
            ),
            Flexible( // Use Flexible instead of Expanded if Column is mainAxisSize.min
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildLevelPricingTab(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _saveProduct, child: Text(_isEditing ? 'Update' : 'Create')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    // ... (This method was correct in the previous full file I sent)
    // Ensure the Dropdowns use items from AppStateProvider for categories/units
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernTextField(controller: _nameController, label: 'Product Name', icon: Icons.label, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          _buildModernTextField(controller: _descriptionController, label: 'Description', icon: Icons.notes, maxLines: 3),
          const SizedBox(height: 16),
          _buildModernTextField(controller: _basePriceController, label: 'Base Unit Price', icon: Icons.attach_money, keyboardType: TextInputType.number, validator: (v) => v == null || (double.tryParse(v) == null || double.parse(v) < 0) ? 'Invalid price' : null),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildModernDropdown<String>(
                value: _selectedCategory,
                label: 'Category',
                icon: Icons.category,
                items: Provider.of<AppStateProvider>(context, listen:false).appSettings?.productCategories ?? ['materials', 'labor', 'roofing'], // Added listen:false
                onChanged: (v) => setState(() => _selectedCategory = v!))),
            const SizedBox(width: 12),
            Expanded(child: _buildModernDropdown<String>(
                value: _selectedUnit,
                label: 'Unit',
                icon: Icons.square_foot,
                items: Provider.of<AppStateProvider>(context, listen:false).appSettings?.productUnits ?? ['each', 'sq ft', 'lin ft'], // Added listen:false
                onChanged: (v) => setState(() => _selectedUnit = v!))),
          ]),
          const SizedBox(height: 16),
          _buildModernTextField(controller: _skuController, label: 'SKU (Optional)', icon: Icons.qr_code),
          const SizedBox(height: 20),
          _buildModernSwitch(title: 'Active Product', subtitle: 'Product is available for use', value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
          const SizedBox(height: 12),
          _buildModernSwitch(title: 'Is Optional Add-on', subtitle: 'Typically offered separately', value: _isAddon, onChanged: (v) => setState(() => _isAddon = v)),
        ],
      ),
    );
  }

  Widget _buildLevelPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Level Pricing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Define specific prices for this product if its cost varies when included in different quote levels (e.g., "basic", "standard"). If a level price isn\'t set, the "Base Unit Price" will be used by default when this product is part of that quote level.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700), // CORRECTED
          ),
          const SizedBox(height: 16),
          ..._formLevelKeys.map((levelKey) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextFormField(
                controller: _levelPriceControllers[levelKey],
                decoration: InputDecoration(
                  labelText: 'Price for "$levelKey" Level (Optional)',
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                  hintText: _basePriceController.text.isNotEmpty ? 'Defaults to \$${_basePriceController.text}' : 'e.g. 150.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null && price >= 0) {
                    _currentLevelPrices[levelKey] = price;
                  } else {
                    _currentLevelPrices.remove(levelKey);
                  }
                  // No setState needed here if only updating map, form submit handles it
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildModernDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString()), // No .toUpperCase() for better readability
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildModernSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
  // IconData _getCategoryIcon(String category) { ... } // This helper can be removed if not used

  void _saveProduct() {
    // ... (This method was correct in the previous full file I sent,
    // ensure it doesn't reference definesLevel, levelName, levelNumber for Product constructor/updateInfo)
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Go to the tab with validation errors
      return;
    }

    final appState = context.read<AppStateProvider>();
    final basePriceText = _basePriceController.text.trim();
    final basePrice = double.tryParse(basePriceText) ?? 0.0;

    Map<String, double> finalLevelPrices = {};
    _levelPriceControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        final price = double.tryParse(controller.text.trim());
        if (price != null && price >= 0) {
          finalLevelPrices[key] = price;
        }
      }
    });

    // If no specific level prices are set, but there's a base price,
    // ensure it's represented. If levelPrices is used, 'base' usually refers to the default/unitPrice.
    // The Product model's getPriceForLevel will fallback to unitPrice if a key isn't in levelPrices.
    // So, we only need to store explicit overrides in product.levelPrices.
    // However, if user *intends* all level prices to be distinct from unitPrice, we just save what they entered.

    if (_isEditing && widget.product != null) {
      widget.product!.updateInfo(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: basePrice,
        unit: _selectedUnit,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
        isAddon: _isAddon,
        levelPrices: finalLevelPrices, // Pass the map of specific level prices
      );
      appState.updateProduct(widget.product!);
    } else {
      final newProduct = Product(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: basePrice,
        unit: _selectedUnit,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
        isAddon: _isAddon,
        levelPrices: finalLevelPrices, // Pass the map of specific level prices
      );
      appState.addProduct(newProduct);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Product updated!' : 'Product created!'), backgroundColor: Colors.green),
    );
  }
}