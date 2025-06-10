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