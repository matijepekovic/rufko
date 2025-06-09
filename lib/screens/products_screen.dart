// lib/screens/products_screen.dart - MODERN UI VERSION (NO IMPORT BUTTONS)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/app_state_provider.dart';
import '../models/product.dart';
import 'products/product_form_dialog.dart';
import '../mixins/search_mixin.dart';
import '../mixins/sort_menu_mixin.dart';
import '../mixins/empty_state_mixin.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin, SearchMixin, SortMenuMixin, EmptyStateMixin {
  late TabController _tabController;
  // SearchMixin provides searchController, searchQuery and searchVisible
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
    final appState = context.read<AppStateProvider>();
    if (appState.appSettings != null && appState.appSettings!.productCategories.isNotEmpty) {
      _categoryTabs = ['All', ...appState.appSettings!.productCategories];
    } else {
      _categoryTabs = ['All', 'Materials', 'Roofing', 'Gutters', 'Labor', 'Other'];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    disposeSearch();
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
            icon: Icon(searchVisible ? Icons.search_off : Icons.search),
            onPressed: toggleSearch,
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
              buildSortMenuItem(
                label: 'Name',
                icon: Icons.sort_by_alpha,
                value: 'name',
                currentSortBy: _sortBy,
                sortAscending: _sortAscending,
              ),
              buildSortMenuItem(
                label: 'Category',
                icon: Icons.category,
                value: 'category',
                currentSortBy: _sortBy,
                sortAscending: _sortAscending,
              ),
              buildSortMenuItem(
                label: 'Price',
                icon: Icons.attach_money,
                value: 'price',
                currentSortBy: _sortBy,
                sortAscending: _sortAscending,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppStateProvider>().loadAllData(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(searchVisible ? 120 : 60),
          child: Column(
            children: [
              if (searchVisible) _buildSearchBar(),
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
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search products by name, category, SKU...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600]),
              onPressed: clearSearch,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
      ),
    );
  }


  Widget _buildProductsList(AppStateProvider appState, String categoryFilter) {
    List<Product> productsToDisplay = _getFilteredProducts(appState, categoryFilter);

    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    if (productsToDisplay.isEmpty) {
      return _buildEmptyState(categoryFilter);
    }

    return RefreshIndicator(
      onRefresh: () => appState.loadAllData(),
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
        itemCount: productsToDisplay.length,
        itemBuilder: (context, index) {
          final product = productsToDisplay[index];
          return _buildProductCard(product, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSmall) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmall ? 8 : 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showProductDetails(product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Product Icon or Image
                    if (product.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(product.imagePath!),
                          width: isSmall ? 40 : 48,
                          height: isSmall ? 40 : 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: isSmall ? 40 : 48,
                        height: isSmall ? 40 : 48,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(product.category),
                          color: _getCategoryColor(product.category),
                          size: isSmall ? 20 : 24,
                        ),
                      ),
                    SizedBox(width: isSmall ? 12 : 16),

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
                                  style: TextStyle(
                                    fontSize: isSmall ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: product.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  product.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: isSmall ? 10 : 12,
                                    fontWeight: FontWeight.w500,
                                    color: product.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                            SizedBox(height: isSmall ? 2 : 4),

                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: isSmall ? 4 : 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.category,
                                  style: TextStyle(
                                    fontSize: isSmall ? 10 : 11,
                                    fontWeight: FontWeight.w500,
                                    color: _getCategoryColor(product.category),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmall ? 6 : 8),
                              Text(
                                '\$${product.unitPrice.toStringAsFixed(2)}/${product.unit}',
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),

                          if (product.description != null && product.description!.isNotEmpty) ...[
                            SizedBox(height: isSmall ? 2 : 4),
                            Text(
                              product.description!,
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 13,
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

                  SizedBox(height: isSmall ? 8 : 12),

                // Action buttons
                Row(
                  children: [
                    if (product.pricingType != ProductPricingType.simple)
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
                        SizedBox(width: isSmall ? 4 : 8),
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
        );
      },
    );
  }

  Widget _buildEmptyState(String categoryFilter) {
    IconData icon;
    String title, subtitle;

    if (searchQuery.isNotEmpty) {
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

    final isSmall = MediaQuery.of(context).size.width < 360;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildEmptyState(icon: icon, title: title, subtitle: subtitle),
          SizedBox(height: isSmall ? 16 : 32),
          if (searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () => _showAddProductDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Product'),
            )
          else
            OutlinedButton.icon(
              onPressed: clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
            ),
        ],
      ),
    );
  }

  List<Product> _getFilteredProducts(AppStateProvider appState, String categoryFilter) {
    List<Product> products = searchQuery.isEmpty
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
    final lowerQuery = searchQuery.toLowerCase();
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
      case ProductPricingType.mainDifferentiator:
        return 'Main';
      case ProductPricingType.subLeveled:
        return 'Sub-Level';
      case ProductPricingType.simple:
        return 'Simple';
    }
  }


  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        final isSmall = MediaQuery.of(context).size.width < 360;
        return Dialog(
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
                  color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    if (product.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(product.imagePath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Icon(
                        _getCategoryIcon(product.category),
                        color: _getCategoryColor(product.category),
                        size: 28,
                      ),
                      SizedBox(width: isSmall ? 8 : 12),
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
                          SizedBox(height: isSmall ? 10 : 16),
                      ],

                      _buildDetailRow('Base Price', '\$${product.unitPrice.toStringAsFixed(2)} per ${product.unit}', Icons.attach_money),
                      SizedBox(height: isSmall ? 10 : 16),

                      if (product.sku != null && product.sku!.isNotEmpty) ...[
                        _buildDetailRow('SKU', product.sku!, Icons.qr_code),
                        SizedBox(height: isSmall ? 10 : 16),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusChip('Status', product.isActive ? 'Active' : 'Inactive',
                                product.isActive ? Colors.green : Colors.grey),
                          ),
                      SizedBox(width: isSmall ? 8 : 12),
                          Expanded(
                            child: _buildStatusChip('Type', product.isAddon ? 'Add-on' : 'Standard',
                                product.isAddon ? Colors.orange : Colors.blue),
                          ),
                        ],
                      ),

                          SizedBox(height: isSmall ? 10 : 16),
                      _buildStatusChip('Pricing', _getPricingTypeLabel(product.pricingType),
                          _getPricingTypeColor(product.pricingType)),

                        if (product.enhancedLevelPrices.isNotEmpty) ...[
                          SizedBox(height: isSmall ? 12 : 20),
                        Text(
                          'Level Pricing',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                          SizedBox(height: isSmall ? 8 : 12),
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
                      SizedBox(width: isSmall ? 8 : 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: isSmall ? 8 : 12),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
      case ProductPricingType.mainDifferentiator:
        return Colors.blue.shade600;
      case ProductPricingType.subLeveled:
        return Colors.orange.shade600;
      case ProductPricingType.simple:
        return Colors.green.shade600;
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ProductFormDialog(),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) {
        final isSmall = MediaQuery.of(context).size.width < 360;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
      SizedBox(width: isSmall ? 8 : 12),
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
      );
    },
    );
  }

  void _toggleProductStatus(Product product) {
    product.updateInfo(isActive: !product.isActive);
    context.read<AppStateProvider>().updateProduct(product);
  }
}

// Enhanced Product Form Dialog with 3-Tier System (keeping the existing implementation)
