// lib/screens/products_screen.dart - ORIGINAL OPTIMIZED VERSION WITH EXTERNAL PRODUCTCARD

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/product.dart';
import 'products/product_form_dialog.dart';
import '../widgets/product_card.dart'; // Use our clean ProductCard
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
          // Use our clean external ProductCard widget
          return ProductCard(
            product: product,
            onTap: null, // Do nothing on tap
            onEdit: () => _showEditProductDialog(context, product),
            onDelete: () => _showDeleteConfirmation(context, product),
            onToggleActive: () => _toggleProductStatus(product),
          );
        },
      ),
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildEmptyState(icon: icon, title: title, subtitle: subtitle),
          const SizedBox(height: 32),
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

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final isPhone = constraints.maxWidth < 600;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: isPhone ? constraints.maxWidth * 0.95 : 500,
              constraints: BoxConstraints(
                maxHeight: isPhone ? constraints.maxHeight * 0.8 : 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean Header
                  Container(
                    padding: EdgeInsets.all(isPhone ? 16 : 20),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isPhone ? 40 : 48,
                          height: isPhone ? 40 : 48,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(product.category).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(product.category),
                            color: _getCategoryColor(product.category),
                            size: isPhone ? 20 : 24,
                          ),
                        ),
                        SizedBox(width: isPhone ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: isPhone ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                product.category,
                                style: TextStyle(
                                  fontSize: isPhone ? 13 : 14,
                                  color: _getCategoryColor(product.category),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: isPhone ? 20 : 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Clean Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isPhone ? 16 : 20),
                      child: Column(
                        children: [
                          // Price Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isPhone ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '\${product.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isPhone ? 24 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'per ${product.unit}',
                                  style: TextStyle(
                                    fontSize: isPhone ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (product.description != null && product.description!.isNotEmpty) ...[
                            SizedBox(height: isPhone ? 16 : 20),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isPhone ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                product.description!,
                                style: TextStyle(
                                  fontSize: isPhone ? 14 : 15,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: isPhone ? 16 : 20),

                          // Status Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: product.isActive ? Colors.green[50] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: product.isActive ? Colors.green[200]! : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        product.isActive ? Icons.check_circle : Icons.cancel,
                                        color: product.isActive ? Colors.green[600] : Colors.grey[600],
                                        size: isPhone ? 20 : 24,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        product.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: isPhone ? 12 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: product.isActive ? Colors.green[600] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: isPhone ? 8 : 12),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: product.isDiscountable ? Colors.blue[50] : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: product.isDiscountable ? Colors.blue[200]! : Colors.orange[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        product.isDiscountable ? Icons.local_offer : Icons.block,
                                        color: product.isDiscountable ? Colors.blue[600] : Colors.orange[600],
                                        size: isPhone ? 20 : 24,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        product.isDiscountable ? 'Discountable' : 'No Discount',
                                        style: TextStyle(
                                          fontSize: isPhone ? 12 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: product.isDiscountable ? Colors.blue[600] : Colors.orange[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Level Pricing (if exists)
                          if (product.enhancedLevelPrices.isNotEmpty) ...[
                            SizedBox(height: isPhone ? 16 : 20),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isPhone ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.layers, color: Colors.blue[700], size: isPhone ? 16 : 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Pricing Levels',
                                        style: TextStyle(
                                          fontSize: isPhone ? 14 : 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isPhone ? 8 : 12),
                                  ...product.enhancedLevelPrices.map((level) => Padding(
                                    padding: EdgeInsets.only(bottom: isPhone ? 6 : 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          level.levelName,
                                          style: TextStyle(
                                            fontSize: isPhone ? 13 : 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '\${level.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: isPhone ? 13 : 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Clean Footer
                  Container(
                    padding: EdgeInsets.all(isPhone ? 16 : 20),
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
                            icon: Icon(Icons.edit, size: isPhone ? 16 : 18),
                            label: Text(
                              'Edit',
                              style: TextStyle(fontSize: isPhone ? 14 : 15),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isPhone ? 12 : 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isPhone ? 8 : 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isPhone ? 12 : 16,
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: TextStyle(fontSize: isPhone ? 14 : 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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