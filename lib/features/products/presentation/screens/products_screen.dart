// lib/screens/products_screen.dart - ORIGINAL OPTIMIZED VERSION WITH EXTERNAL PRODUCTCARD

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/business/product.dart';
import '../widgets/product_card.dart'; // Use our clean ProductCard
import '../../../../core/mixins/ui/search_mixin.dart';
import '../../../../core/mixins/ui/sort_menu_mixin.dart';
import '../../../../core/mixins/ui/empty_state_mixin.dart';
import '../controllers/product_dialog_manager.dart';
import '../controllers/product_filter_controller.dart';
import '../controllers/product_category_manager.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin, SearchMixin, SortMenuMixin, EmptyStateMixin {
  late TabController _tabController;
  // SearchMixin provides searchController, searchQuery and searchVisible
  late ProductDialogManager _dialogManager;
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<String> _categoryTabs = ['All'];
  late ProductCategoryManager _categoryManager;

  @override
  void initState() {
    super.initState();
    _dialogManager = ProductDialogManager(context);
    _categoryManager = ProductCategoryManager(context.read<AppStateProvider>());
    _categoryTabs = _categoryManager.getCategoryTabs();
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
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
                  tabs: _categoryTabs
                      .map((category) => Tab(text: category))
                      .toList(),
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
            children: _categoryTabs
                .map((category) => _buildProductsList(appState, category))
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _dialogManager.showAddProductDialog,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildProductsList(AppStateProvider appState, String categoryFilter) {
    final controller = ProductFilterController(appState);
    List<Product> productsToDisplay = controller.getFilteredProducts(
      category: categoryFilter,
      searchQuery: searchQuery,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
    );

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
            onEdit: () => _dialogManager.showEditProductDialog(product),
            onDelete: () => _dialogManager.showDeleteConfirmation(product),
            onToggleActive: () => _dialogManager.toggleProductStatus(product),
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
              onPressed: _dialogManager.showAddProductDialog,
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
}
