// lib/screens/customers_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../core/services/customer/customer_list_service.dart';
import '../widgets/customer_card.dart'; // Assuming this will be adapted
import 'customer_detail_screen.dart';
import '../../../../core/mixins/ui/search_mixin.dart';
import '../../../../core/mixins/ui/sort_menu_mixin.dart';
import '../../../../core/mixins/ui/empty_state_mixin.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../../core/widgets/search_chip_ui_components.dart';

import '../controllers/customer_filter_controller.dart';
import '../controllers/customer_dialog_manager.dart';
import '../controllers/customer_import_controller.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with SearchMixin, SortMenuMixin, EmptyStateMixin {
  // SearchMixin provides searchController, searchQuery and searchVisible
  late CustomerDialogManager _dialogManager;
  late CustomerImportController _importController;
  CustomerFilterController? _filterController;
  String _sortBy = 'name';
  bool _sortAscending = true;

  final List<String> _filterTabs = ['All', 'Recent', 'Active', 'Inactive'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    _importController = CustomerImportController(context, appState);
    _dialogManager = CustomerDialogManager(context, _importController);
    // Initialize _filterController in build method when we have appState
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
                    hintText: 'Search leads...',
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
              // Sort PopupMenu (moved to filter area)
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
                    label: 'Date Added',
                    icon: Icons.calendar_today,
                    value: 'date',
                    currentSortBy: _sortBy,
                    sortAscending: _sortAscending,
                  ),
                  buildSortMenuItem(
                    label: 'Last Activity',
                    icon: Icons.access_time,
                    value: 'activity',
                    currentSortBy: _sortBy,
                    sortAscending: _sortAscending,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // CHIP FILTERS ROW
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            _filterController ??= CustomerFilterController(appState);
            return ChipFilterRow(
              filterOptions: _filterTabs,
              selectedFilter: _filterController!.selectedFilter,
              onFilterSelected: (filter) {
                _filterController!.selectFilter(filter);
                setState(() {}); // Only trigger UI rebuild
              },
            );
          },
        ),
        
        // CUSTOMER LIST
        Expanded(
          child: Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              if (appState.isLoading && appState.customers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              // Initialize filter controller if not already done
              _filterController ??= CustomerFilterController(appState);
              return _buildCustomersList(appState);
            },
          ),
        ),
      ],
    );
  }


  Widget _buildCustomersList(AppStateProvider appState) {
    List<Customer> customers = _filterController!.getFilteredCustomers(
        filter: _filterController!.selectedFilter,
        searchQuery: searchQuery,
        sortBy: _sortBy,
        sortAscending: _sortAscending);
    if (customers.isEmpty) return _buildEmptyState(_filterController!.selectedFilter);

    return RefreshIndicator(
      onRefresh: () => CustomerListService.refreshCustomerData(appState),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          final quoteCount = CustomerListService.getCustomerQuoteCount(
            appState: appState,
            customerId: customer.id,
          );
          return CustomerCard(
            customer: customer,
            quoteCount: quoteCount,
            customerMedia: appState.getProjectMediaForCustomer(customer.id),
            onTap: () => _navigateToCustomerDetail(customer),
            onEdit: () => _showEditCustomerDialog(context, customer),
            onDelete: () => _showDeleteConfirmation(context, customer),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    final bool noQuery = searchQuery.isEmpty;
    String title = noQuery ? 'No customers yet' : 'No customers found';
    String subtitle =
        noQuery ? 'Add your first customer' : 'Try adjusting search';
    IconData icon = noQuery ? Icons.people_outline : Icons.search_off;

    return buildEmptyState(icon: icon, title: title, subtitle: subtitle);
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    _dialogManager.showEditCustomerDialog(customer);
  }

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    _dialogManager.showDeleteConfirmation(customer);
  }

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(customer: customer)));
  }
}
