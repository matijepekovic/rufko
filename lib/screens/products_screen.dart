// lib/screens/products_screen.dart - MODERN UI VERSION (NO IMPORT BUTTONS)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  String _sortBy = 'name';
  bool _sortAscending = true;

  List<String> _categoryTabs = ['All'];

  @override
  void initState() {
    super.initState();
    _updateCategoryTabs();
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
  }

  void _updateCategoryTabs() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.appSettings != null && appState.appSettings!.productCategories.isNotEmpty) {
      _categoryTabs = ['All', ...appState.appSettings!.productCategories];
    } else {
      _categoryTabs = ['All', 'Materials', 'Roofing', 'Gutters', 'Labor', 'Other'];
    }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (value == _sortBy) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (context) => [
              _buildSortMenuItem('Name', Icons.sort_by_alpha, 'name'),
              _buildSortMenuItem('Category', Icons.category, 'category'),
              _buildSortMenuItem('Price', Icons.attach_money, 'price'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppStateProvider>().loadAllData(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showSearch ? 120 : 60),
          child: Column(
            children: [
              if (_showSearch) _buildSearchBar(),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).primaryColor,
                  isScrollable: true,
                  tabs: _categoryTabs.map((category) => Tab(text: category)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.isLoading && appState.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: _categoryTabs.map((category) => _buildProductsList(appState, category)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products by name, category, SKU...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600]),
              onPressed: _clearSearch,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String label, IconData icon, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
          if (_sortBy == value) ...[
            const Spacer(),
            Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsList(AppStateProvider appState, String categoryFilter) {
    List<Product> productsToDisplay = _getFilteredProducts(appState, categoryFilter);

    if (productsToDisplay.isEmpty) {
      return _buildEmptyState(categoryFilter);
    }

    return RefreshIndicator(
      onRefresh: () => appState.loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: productsToDisplay.length,
        itemBuilder: (context, index) {
          final product = productsToDisplay[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showProductDetails(product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Product Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(product.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(product.category),
                        color: _getCategoryColor(product.category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: product.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  product.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: product.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(product.category).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _getCategoryColor(product.category),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${product.unitPrice.toStringAsFixed(2)}/${product.unit}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),

                          if (product.description != null && product.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              product.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    if (product.pricingType != ProductPricingType.SIMPLE)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getPricingTypeLabel(product.pricingType),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    if (product.isAddon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Add-on',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),

                    // Active/Inactive toggle
                    Switch(
                      value: product.isActive,
                      onChanged: (value) => _toggleProductStatus(product),
                      activeColor: Theme.of(context).primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),

                    // Action buttons
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600),
                      onPressed: () => _showEditProductDialog(context, product),
                      tooltip: 'Edit Product',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                      onPressed: () => _showDeleteConfirmation(context, product),
                      tooltip: 'Delete Product',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String categoryFilter) {
    IconData icon;
    String title, subtitle;

    if (_searchQuery.isNotEmpty) {
      icon = Icons.search_off;
      title = 'No products found';
      subtitle = 'Try adjusting your search terms';
    } else if (categoryFilter != 'All') {
      icon = Icons.category_outlined;
      title = 'No products in $categoryFilter';
      subtitle = 'Add products to this category or switch to another tab';
    } else {
      icon = Icons.inventory_2_outlined;
      title = 'No products yet';
      subtitle = 'Add your first product to get started';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_searchQuery.isEmpty) ...[
            ElevatedButton.icon(
              onPressed: () => _showAddProductDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Product'),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  List<Product> _getFilteredProducts(AppStateProvider appState, String categoryFilter) {
    List<Product> products = _searchQuery.isEmpty
        ? appState.products
        : _getSearchResults(appState.products);

    if (categoryFilter != 'All') {
      products = products.where((p) =>
      p.category.toLowerCase() == categoryFilter.toLowerCase()
      ).toList();
    }

    products.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'category':
          comparison = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          break;
        case 'price':
          comparison = a.unitPrice.compareTo(b.unitPrice);
          break;
        default:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? comparison : -comparison;
    });

    return products;
  }

  List<Product> _getSearchResults(List<Product> products) {
    final lowerQuery = _searchQuery.toLowerCase();
    return products.where((product) =>
    product.name.toLowerCase().contains(lowerQuery) ||
        (product.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        product.category.toLowerCase().contains(lowerQuery) ||
        (product.sku?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  // Helper methods for styling
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'roofing':
        return Colors.red.shade600;
      case 'materials':
        return Colors.blue.shade600;
      case 'gutters':
        return Colors.teal.shade600;
      case 'labor':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'roofing':
        return Icons.roofing;
      case 'materials':
        return Icons.construction;
      case 'gutters':
        return Icons.water_drop;
      case 'labor':
        return Icons.engineering;
      default:
        return Icons.inventory_2;
    }
  }

  String _getPricingTypeLabel(ProductPricingType type) {
    switch (type) {
      case ProductPricingType.MAIN_DIFFERENTIATOR:
        return 'Main';
      case ProductPricingType.SUB_LEVELED:
        return 'Sub-Level';
      case ProductPricingType.SIMPLE:
        return 'Simple';
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getCategoryColor(product.category).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(product.category),
                      color: _getCategoryColor(product.category),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            product.category,
                            style: TextStyle(
                              color: _getCategoryColor(product.category),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        _buildDetailRow('Description', product.description!, Icons.description),
                        const SizedBox(height: 16),
                      ],

                      _buildDetailRow('Base Price', '\$${product.unitPrice.toStringAsFixed(2)} per ${product.unit}', Icons.attach_money),
                      const SizedBox(height: 16),

                      if (product.sku != null && product.sku!.isNotEmpty) ...[
                        _buildDetailRow('SKU', product.sku!, Icons.qr_code),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusChip('Status', product.isActive ? 'Active' : 'Inactive',
                                product.isActive ? Colors.green : Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatusChip('Type', product.isAddon ? 'Add-on' : 'Standard',
                                product.isAddon ? Colors.orange : Colors.blue),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _buildStatusChip('Pricing', _getPricingTypeLabel(product.pricingType),
                          _getPricingTypeColor(product.pricingType)),

                      if (product.enhancedLevelPrices.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Level Pricing',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...product.enhancedLevelPrices.map((level) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      level.levelName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    if (level.description != null)
                                      Text(
                                        level.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${level.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditProductDialog(context, product);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Product'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPricingTypeColor(ProductPricingType type) {
    switch (type) {
      case ProductPricingType.MAIN_DIFFERENTIATOR:
        return Colors.blue.shade600;
      case ProductPricingType.SUB_LEVELED:
        return Colors.orange.shade600;
      case ProductPricingType.SIMPLE:
        return Colors.green.shade600;
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ModernProductFormDialog(),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Delete Product'),
          ],
        ),
        content: Text('Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} deleted'),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(Product product) {
    product.updateInfo(isActive: !product.isActive);
    context.read<AppStateProvider>().updateProduct(product);
  }
}

// Enhanced Product Form Dialog with 3-Tier System (keeping the existing implementation)
class _ModernProductFormDialog extends StatefulWidget {
  final Product? product;
  const _ModernProductFormDialog({Key? key, this.product}) : super(key: key);

  @override
  State<_ModernProductFormDialog> createState() => _ModernProductFormDialogState();
}

class _ModernProductFormDialogState extends State<_ModernProductFormDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Basic info controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _skuController = TextEditingController();

  // Basic info state
  String _selectedCategory = 'Materials';
  String _selectedUnit = 'each';
  bool _isActive = true;
  bool _isAddon = false;
  bool _isDiscountable = true;

  // NEW: 3-Tier System State
  ProductPricingType _pricingType = ProductPricingType.SIMPLE;
  bool _isMainDifferentiator = false;

  // Level pricing controllers (dynamic)
  final Map<String, TextEditingController> _levelPriceControllers = {};
  final Map<String, TextEditingController> _levelNameControllers = {};
  final Map<String, TextEditingController> _levelDescriptionControllers = {};

  List<String> _currentLevelKeys = [];
  bool _isInitialized = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeFormData();
  }

  void _initializeFormData() {
    if (_isInitialized) return;
    _isInitialized = true;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final categories = appState.appSettings?.productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'];
    final settingsLevels = appState.appSettings?.defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'];

    if (_isEditing && widget.product != null) {
      // EDITING MODE: Load existing product data
      final p = widget.product!;

      // Load basic info
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _basePriceController.text = p.unitPrice.toStringAsFixed(2);
      _skuController.text = p.sku ?? '';
      _selectedCategory = categories.contains(p.category) ? p.category : categories.first;
      _selectedUnit = p.unit;
      _isActive = p.isActive;
      _isAddon = p.isAddon;
      _isDiscountable = p.isDiscountable;

      // NEW: Load 3-tier system data
      _pricingType = p.pricingType;
      _isMainDifferentiator = p.isMainDifferentiator;

      // Build level keys from existing product
      _currentLevelKeys = p.enhancedLevelPrices.map((level) => level.levelId).toList();

      // If no levels exist, set defaults based on pricing type
      if (_currentLevelKeys.isEmpty && _pricingType != ProductPricingType.SIMPLE) {
        if (_pricingType == ProductPricingType.MAIN_DIFFERENTIATOR) {
          _currentLevelKeys = settingsLevels.map((name) => name.toLowerCase().replaceAll(' ', '_')).toList();
        } else {
          _currentLevelKeys = ['option_1', 'option_2']; // Default sub-levels
        }
      }

      // Initialize controllers for all levels
      _initializeLevelControllers();

      // Load existing level data
      for (final levelPrice in p.enhancedLevelPrices) {
        final key = levelPrice.levelId;
        if (_levelPriceControllers.containsKey(key)) {
          _levelPriceControllers[key]!.text = levelPrice.price.toStringAsFixed(2);
          _levelNameControllers[key]!.text = levelPrice.levelName;
          _levelDescriptionControllers[key]!.text = levelPrice.description ?? '';
        }
      }
    } else {
      // NEW PRODUCT MODE
      _selectedCategory = categories.first;
      _pricingType = ProductPricingType.SIMPLE; // Default to simple
    }
  }

  void _initializeLevelControllers() {
    // Clear existing controllers
    _levelPriceControllers.forEach((_, controller) => controller.dispose());
    _levelNameControllers.forEach((_, controller) => controller.dispose());
    _levelDescriptionControllers.forEach((_, controller) => controller.dispose());
    _levelPriceControllers.clear();
    _levelNameControllers.clear();
    _levelDescriptionControllers.clear();

    // Initialize controllers for current level keys
    for (int i = 0; i < _currentLevelKeys.length; i++) {
      final key = _currentLevelKeys[i];
      _levelPriceControllers[key] = TextEditingController();
      _levelNameControllers[key] = TextEditingController();
      _levelDescriptionControllers[key] = TextEditingController();

      // Set default names based on pricing type
      if (_pricingType == ProductPricingType.MAIN_DIFFERENTIATOR) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final settingsLevels = appState.appSettings?.defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'];
        if (i < settingsLevels.length) {
          _levelNameControllers[key]!.text = settingsLevels[i];
        }
      } else if (_pricingType == ProductPricingType.SUB_LEVELED) {
        _levelNameControllers[key]!.text = 'Option ${i + 1}';
      }
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
    _levelNameControllers.forEach((_, controller) => controller.dispose());
    _levelDescriptionControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.90,
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'Basic Info'),
                  Tab(icon: Icon(Icons.tune), text: 'Product Type'),
                  Tab(icon: Icon(Icons.layers_outlined), text: 'Pricing Levels'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildProductTypeTab(),
                    _buildPricingLevelsTab(),
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(_isEditing ? Icons.edit_note : Icons.add_box,
              color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Product' : 'Create New Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getPricingTypeDescription(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final categories = appState.appSettings?.productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'];
        final units = appState.appSettings?.productUnits ?? ['each', 'sq ft', 'lin ft', 'hour', 'day'];

        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = categories.first;
        }
        if (!units.contains(_selectedUnit)) {
          _selectedUnit = units.first;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernTextField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.label_outline,
                validator: (v) => v == null || v.isEmpty ? 'Product name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.notes,
                maxLines: 3,
                hint: 'Describe what this product is and its key features...',
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _basePriceController,
                label: 'Base Unit Price',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || (double.tryParse(v) == null || double.parse(v) < 0) ? 'Enter a valid price' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernDropdown<String>(
                      value: _selectedCategory,
                      label: 'Category',
                      icon: Icons.category,
                      items: categories,
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernDropdown<String>(
                      value: _selectedUnit,
                      label: 'Unit',
                      icon: Icons.straighten,
                      items: units,
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _skuController,
                label: 'SKU (Optional)',
                icon: Icons.qr_code_outlined,
                hint: 'Product identifier for inventory tracking',
              ),
              const SizedBox(height: 24),
              Text(
                'Product Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildModernSwitch(
                title: 'Active Product',
                subtitle: 'Available for use in quotes and estimates',
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                icon: Icons.visibility,
              ),
              const SizedBox(height: 8),
              _buildModernSwitch(
                title: 'Optional Add-on',
                subtitle: 'Typically offered as separate upgrade option',
                value: _isAddon,
                onChanged: (v) => setState(() => _isAddon = v),
                icon: Icons.add_circle_outline,
              ),
              const SizedBox(height: 8),
              _buildModernSwitch(
                title: 'Discountable Product',
                subtitle: 'Can be affected by quote discounts and promotions',
                value: _isDiscountable,
                onChanged: (v) => setState(() => _isDiscountable = v),
                icon: Icons.local_offer_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  // NEW: Product Type Selection Tab
  Widget _buildProductTypeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Choose Product Type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how this product behaves in quotes:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Product Type Cards
          _buildProductTypeCard(
            type: ProductPricingType.MAIN_DIFFERENTIATOR,
            title: '🏠 Main Differentiator',
            subtitle: 'Sets quote column headers',
            description: 'Creates Builder/Homeowner/Platinum columns.\nExample: Roofing Shingles with different quality levels.',
            color: Colors.blue,
            example: 'Builder (\$120) | Homeowner (\$180) | Platinum (\$240)',
          ),

          _buildProductTypeCard(
            type: ProductPricingType.SUB_LEVELED,
            title: '🌧️ Sub-Leveled Options',
            subtitle: 'Independent internal choices',
            description: 'Customer picks ONE option regardless of main product level.\nExample: Gutters with/without mesh.',
            color: Colors.orange,
            example: 'Basic Gutters (\$8) OR Mesh Gutters (\$18)',
          ),

          _buildProductTypeCard(
            type: ProductPricingType.SIMPLE,
            title: '👷 Simple Product',
            subtitle: 'Same price everywhere',
            description: 'One price used across all quote levels.\nExample: Labor, nails, installation.',
            color: Colors.green,
            example: 'Labor: \$85/hour (same for all roof types)',
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeCard({
    required ProductPricingType type,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required String example,
  }) {
    final isSelected = _pricingType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _setPricingType(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withOpacity(0.05) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : Colors.black87,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Example: $example',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingLevelsTab() {
    if (_pricingType == ProductPricingType.SIMPLE) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              'Simple Product Selected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This product uses the base price across all quote levels.\nNo additional configuration needed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPricingTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.layers, color: _getPricingTypeColor(), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR
                          ? 'Main Differentiator Levels'
                          : 'Sub-Level Options',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR
                          ? 'These create the quote column headers'
                          : 'Customer picks ONE of these options',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR
                        ? 'These levels appear as separate columns in quotes for side-by-side comparison.'
                        : 'Customer chooses one option independent of the main product level.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Level configuration cards
          ...List.generate(_currentLevelKeys.length, (index) {
            final levelKey = _currentLevelKeys[index];
            final cardColor = _getLevelCardColor(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: cardColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
                color: cardColor.withOpacity(0.05),
              ),
              child: Column(
                children: [
                  // Card header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR
                                ? 'Level ${index + 1} Configuration'
                                : 'Option ${index + 1} Configuration',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cardColor,
                            ),
                          ),
                        ),
                        if (_currentLevelKeys.length > 1)
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                            onPressed: () => _removeLevel(index),
                            tooltip: 'Remove this level',
                          ),
                      ],
                    ),
                  ),

                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Level name
                        TextFormField(
                          controller: _levelNameControllers[levelKey],
                          decoration: InputDecoration(
                            labelText: _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 'Level Name' : 'Option Name',
                            hintText: _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 'Builder Grade' : 'Basic Version',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label_outline, color: cardColor),
                            helperText: _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR
                                ? 'This name appears as column header'
                                : 'Customer sees this option name',
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 12),

                        // Level description
                        TextFormField(
                          controller: _levelDescriptionControllers[levelKey],
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Describe what makes this different...',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description_outlined, color: cardColor),
                            helperText: 'Explains value differences to customers',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        // Level price
                        TextFormField(
                          controller: _levelPriceControllers[levelKey],
                          decoration: InputDecoration(
                            labelText: 'Price',
                            prefixText: '\$ ',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money, color: cardColor),
                            hintText: _basePriceController.text.isNotEmpty
                                ? 'Defaults to \$${_basePriceController.text}'
                                : 'e.g. 150.00',
                            helperText: 'Leave empty to use base price',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final price = double.tryParse(v);
                              if (price == null || price < 0) {
                                return 'Enter a valid price';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Add/Remove level controls
          const SizedBox(height: 16),
          _buildLevelControls(),
        ],
      ),
    );
  }

  Widget _buildLevelControls() {
    final maxLevels = _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 6 : 4;
    final minLevels = _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 2 : 2;

    return Row(
      children: [
        if (_currentLevelKeys.length > minLevels)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _removeLevel(_currentLevelKeys.length - 1),
              icon: const Icon(Icons.remove),
              label: Text('Remove (${_currentLevelKeys.length} total)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
              ),
            ),
          ),
        if (_currentLevelKeys.length > minLevels) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentLevelKeys.length < maxLevels ? _addLevel : null,
            icon: const Icon(Icons.add),
            label: Text('Add ${_pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 'Level' : 'Option'} (${_currentLevelKeys.length}/$maxLevels)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saveProduct,
            icon: Icon(_isEditing ? Icons.update : Icons.add),
            label: Text(_isEditing ? 'Update Product' : 'Create Product'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _getPricingTypeDescription() {
    switch (_pricingType) {
      case ProductPricingType.MAIN_DIFFERENTIATOR:
        return 'Main differentiator - sets quote column headers';
      case ProductPricingType.SUB_LEVELED:
        return 'Sub-leveled - independent customer choices';
      case ProductPricingType.SIMPLE:
        return 'Simple product - same price everywhere';
    }
  }

  Color _getPricingTypeColor() {
    switch (_pricingType) {
      case ProductPricingType.MAIN_DIFFERENTIATOR:
        return Colors.blue.shade600;
      case ProductPricingType.SUB_LEVELED:
        return Colors.orange.shade600;
      case ProductPricingType.SIMPLE:
        return Colors.green.shade600;
    }
  }

  Color _getLevelCardColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.green.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
    ];
    return colors[index % colors.length];
  }

  void _setPricingType(ProductPricingType type) {
    setState(() {
      _pricingType = type;
      _isMainDifferentiator = (type == ProductPricingType.MAIN_DIFFERENTIATOR);

      if (type == ProductPricingType.SIMPLE) {
        _currentLevelKeys.clear();
      } else {
        // Set default level keys based on type
        if (type == ProductPricingType.MAIN_DIFFERENTIATOR) {
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final settingsLevels = appState.appSettings?.defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'];
          _currentLevelKeys = settingsLevels.map((name) => name.toLowerCase().replaceAll(' ', '_')).toList();
        } else {
          _currentLevelKeys = ['option_1', 'option_2'];
        }
        _initializeLevelControllers();
      }
    });
  }

  void _addLevel() {
    final maxLevels = _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 6 : 4;
    if (_currentLevelKeys.length < maxLevels) {
      setState(() {
        final newKey = '${_pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 'level' : 'option'}_${DateTime.now().millisecondsSinceEpoch}';
        _currentLevelKeys.add(newKey);
        _levelPriceControllers[newKey] = TextEditingController();
        _levelNameControllers[newKey] = TextEditingController(
            text: '${_pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 'Level' : 'Option'} ${_currentLevelKeys.length}'
        );
        _levelDescriptionControllers[newKey] = TextEditingController();
      });
    }
  }

  void _removeLevel(int index) {
    final minLevels = _pricingType == ProductPricingType.MAIN_DIFFERENTIATOR ? 2 : 2;
    if (_currentLevelKeys.length > minLevels && index < _currentLevelKeys.length) {
      setState(() {
        final keyToRemove = _currentLevelKeys[index];
        _currentLevelKeys.removeAt(index);
        _levelPriceControllers[keyToRemove]?.dispose();
        _levelNameControllers[keyToRemove]?.dispose();
        _levelDescriptionControllers[keyToRemove]?.dispose();
        _levelPriceControllers.remove(keyToRemove);
        _levelNameControllers.remove(keyToRemove);
        _levelDescriptionControllers.remove(keyToRemove);
      });
    }
  }

  // Form Field Builders
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString()),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildModernSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      // Switch to appropriate tab if validation fails
      if (_nameController.text.isEmpty || _basePriceController.text.isEmpty) {
        _tabController.animateTo(0);
      } else if (_pricingType != ProductPricingType.SIMPLE && _currentLevelKeys.any((key) => _levelNameControllers[key]?.text.isEmpty ?? true)) {
        _tabController.animateTo(2);
      }
      return;
    }

    final appState = context.read<AppStateProvider>();
    final basePriceText = _basePriceController.text.trim();
    final basePrice = double.tryParse(basePriceText) ?? 0.0;

    // Build enhanced level prices from the form
    List<ProductLevelPrice> enhancedLevelPrices = [];
    if (_pricingType != ProductPricingType.SIMPLE) {
      for (final key in _currentLevelKeys) {
        final name = _levelNameControllers[key]?.text.trim() ?? 'Level';
        final description = _levelDescriptionControllers[key]?.text.trim();
        final priceText = _levelPriceControllers[key]?.text.trim() ?? '';
        final price = double.tryParse(priceText) ?? basePrice;

        if (name.isNotEmpty) {
          enhancedLevelPrices.add(ProductLevelPrice(
            levelId: key,
            levelName: name,
            price: price,
            description: description?.isEmpty ?? true ? null : description,
            isActive: true,
          ));
        }
      }
    }

    if (_isEditing && widget.product != null) {
      // Update existing product
      widget.product!.updateInfo(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: basePrice,
        unit: _selectedUnit,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
        isAddon: _isAddon,
        isDiscountable: _isDiscountable,
        isMainDifferentiator: _isMainDifferentiator,
        enableLevelPricing: _pricingType != ProductPricingType.SIMPLE,
      );

      // Update enhanced level prices and pricing type
      widget.product!.enhancedLevelPrices.clear();
      widget.product!.enhancedLevelPrices.addAll(enhancedLevelPrices);
      widget.product!.pricingType = _pricingType;

      appState.updateProduct(widget.product!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
      );
    } else {
      // Create new product
      final newProduct = Product(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: basePrice,
        unit: _selectedUnit,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
        isAddon: _isAddon,
        isDiscountable: _isDiscountable,
        isMainDifferentiator: _isMainDifferentiator,
        enableLevelPricing: _pricingType != ProductPricingType.SIMPLE,
        pricingType: _pricingType,
        enhancedLevelPrices: enhancedLevelPrices,
      );

      appState.addProduct(newProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully!'), backgroundColor: Colors.green),
      );
    }

    Navigator.pop(context);
  }
}