import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/business/inventory_item.dart';
import '../../../../data/models/business/product.dart';
import '../../../../core/mixins/ui/search_mixin.dart';
import '../../../../core/mixins/ui/sort_menu_mixin.dart';
import '../../../../core/mixins/ui/empty_state_mixin.dart';
import '../../../../core/widgets/search_chip_ui_components.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/inventory_card.dart';
import '../dialogs/inventory_form_dialog.dart';
import '../dialogs/quick_adjust_dialog.dart';
import '../dialogs/inventory_details_dialog.dart';

/// Inventory management screen
/// Follows the same pattern as ProductsScreen with search, filters, and list
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SearchMixin, SortMenuMixin, EmptyStateMixin {
  
  late InventoryController _inventoryController;
  String _sortBy = 'name';
  bool _sortAscending = true;
  final List<String> _filterTabs = ['All', 'Inventory', 'Low Stock', 'Out of Stock'];
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventoryController = InventoryController();
    _loadInventoryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inventoryController.dispose();
    disposeSearch();
    super.dispose();
  }

  Future<void> _loadInventoryData() async {
    await _inventoryController.loadInventoryItems();
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
                    hintText: 'Search inventory...',
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
                    label: 'Product Name',
                    icon: Icons.sort_by_alpha,
                    value: 'name',
                    currentSortBy: _sortBy,
                    sortAscending: _sortAscending,
                  ),
                  buildSortMenuItem(
                    label: 'Quantity',
                    icon: Icons.numbers,
                    value: 'quantity',
                    currentSortBy: _sortBy,
                    sortAscending: _sortAscending,
                  ),
                  buildSortMenuItem(
                    label: 'Last Updated',
                    icon: Icons.access_time,
                    value: 'lastUpdated',
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
                onPressed: _loadInventoryData,
              ),
            ],
          ),
        ),
        
        // CHIP FILTERS ROW
        ChipFilterRow(
          filterOptions: _filterTabs,
          selectedFilter: _selectedFilter,
          onFilterSelected: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
        ),
        
        // INVENTORY LIST
        Expanded(
          child: Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              return ListenableBuilder(
                listenable: _inventoryController,
                builder: (context, child) {
                  if (_inventoryController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (_inventoryController.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading inventory',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _inventoryController.error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          RufkoPrimaryButton(
                            onPressed: _loadInventoryData,
                            icon: Icons.refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return _buildInventoryList(appState);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryList(AppStateProvider appState) {
    List<InventoryItem> inventoryToDisplay = _getFilteredAndSortedInventory(appState);

    if (inventoryToDisplay.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInventoryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inventoryToDisplay.length,
        itemBuilder: (context, index) {
          final inventoryItem = inventoryToDisplay[index];
          final product = appState.products.firstWhere(
            (p) => p.id == inventoryItem.productId,
            orElse: () => Product(
              name: 'Unknown Product',
              unitPrice: 0.0,
              id: inventoryItem.productId,
            ),
          );
          
          return InventoryCard(
            inventoryItem: inventoryItem,
            product: product,
            onTap: () => _showInventoryDetails(inventoryItem, product),
            onQuickAdd: () => _showQuickAdjustDialog(inventoryItem, product, isAdd: true),
            onQuickRemove: () => _showQuickAdjustDialog(inventoryItem, product, isAdd: false),
          );
        },
      ),
    );
  }

  List<InventoryItem> _getFilteredAndSortedInventory(AppStateProvider appState) {
    List<InventoryItem> items = List.from(_inventoryController.inventoryItems);

    // Apply filters
    switch (_selectedFilter) {
      case 'Inventory':
        items = items.where((item) => item.quantity > 0).toList();
        break;
      case 'Low Stock':
        items = items.where((item) => item.isLowStock).toList();
        break;
      case 'Out of Stock':
        items = items.where((item) => item.isOutOfStock).toList();
        break;
      case 'All':
      default:
        // No additional filtering
        break;
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      items = items.where((item) {
        final product = appState.products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(name: 'Unknown', unitPrice: 0.0),
        );
        return product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               (item.location?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
               (item.notes?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply sorting
    items.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          final productA = appState.products.firstWhere(
            (p) => p.id == a.productId,
            orElse: () => Product(name: 'Unknown', unitPrice: 0.0),
          );
          final productB = appState.products.firstWhere(
            (p) => p.id == b.productId,
            orElse: () => Product(name: 'Unknown', unitPrice: 0.0),
          );
          comparison = productA.name.compareTo(productB.name);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'lastUpdated':
          comparison = a.lastUpdated.compareTo(b.lastUpdated);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    return items;
  }

  Widget _buildEmptyState() {
    IconData icon;
    String title, subtitle;

    if (searchQuery.isNotEmpty) {
      icon = Icons.search_off;
      title = 'No inventory found';
      subtitle = 'Try adjusting your search terms';
    } else if (_selectedFilter != 'All') {
      icon = Icons.inventory_2_outlined;
      title = 'No ${_selectedFilter.toLowerCase()} items';
      subtitle = 'Add inventory or switch to another filter';
    } else {
      icon = Icons.inventory_2_outlined;
      title = 'No inventory yet';
      subtitle = 'Add inventory for your products to get started';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildEmptyState(icon: icon, title: title, subtitle: subtitle),
          const SizedBox(height: 32),
          if (searchQuery.isEmpty)
            RufkoPrimaryButton(
              onPressed: _showAddInventoryDialog,
              icon: Icons.add,
              child: const Text('Add Inventory'),
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

  void _showInventoryDetails(InventoryItem inventoryItem, Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InventoryDetailsDialog(
        inventoryItem: inventoryItem,
        product: product,
      ),
    );

    if (result == true) {
      // Refresh inventory data if changes were made
      await _loadInventoryData();
    }
  }

  void _showQuickAdjustDialog(InventoryItem inventoryItem, Product product, {required bool isAdd}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuickAdjustDialog(
        inventoryItem: inventoryItem,
        product: product,
        isAdd: isAdd,
      ),
    );

    if (result == true) {
      // Refresh inventory data if changes were made
      await _loadInventoryData();
    }
  }

  void _showAddInventoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const InventoryFormDialog(),
    );

    if (result == true) {
      // Refresh inventory data if new inventory was added
      await _loadInventoryData();
    }
  }
}