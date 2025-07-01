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
import '../../../../core/services/product/product_list_service.dart';
import '../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../../../core/widgets/search_chip_ui_components.dart';
import '../../../../app/theme/rufko_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SearchMixin, SortMenuMixin, EmptyStateMixin {
  late ProductDialogManager _dialogManager;
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<String> _categoryTabs = ['All'];
  late ProductCategoryManager _categoryManager;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dialogManager = ProductDialogManager(context);
    _categoryManager = ProductCategoryManager(context.read<AppStateProvider>());
    _categoryTabs = _categoryManager.getCategoryTabs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    disposeSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ALWAYS VISIBLE SEARCH BAR
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: RufkoTheme.strokeColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: RufkoTheme.strokeColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Sort PopupMenu
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => ProductListService.refreshProductData(context.read<AppStateProvider>()),
              ),
            ],
          ),
        ),
        
        // CHIP FILTERS ROW
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            // Update category tabs if products changed
            final newCategoryTabs = _categoryManager.getCategoryTabs();
            if (newCategoryTabs.length != _categoryTabs.length) {
              _categoryTabs = newCategoryTabs;
              if (!_categoryTabs.contains(_selectedCategory)) {
                _selectedCategory = 'All';
              }
            }
            return ChipFilterRow(
              filterOptions: _categoryTabs,
              selectedFilter: _selectedCategory,
              onFilterSelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            );
          },
        ),
        
        // PRODUCTS LIST
        Expanded(
          child: Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              if (appState.isLoading && appState.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildProductsList(appState, _selectedCategory);
            },
          ),
        ),
      ],
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
      onRefresh: () => ProductListService.refreshProductData(appState),
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
            RufkoPrimaryButton(
              onPressed: _dialogManager.showAddProductDialog,
              icon: Icons.add,
              child: const Text('Add First Product'),
            )
          else
            RufkoSecondaryButton(
              onPressed: clearSearch,
              icon: Icons.clear,
              child: const Text('Clear Search'),
            ),
        ],
      ),
    );
  }
}
