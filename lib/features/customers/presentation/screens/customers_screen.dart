// lib/screens/customers_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/business/customer.dart';
import '../widgets/customer_card.dart'; // Assuming this will be adapted
import 'customer_detail_screen.dart';
import '../../../../core/mixins/ui/search_mixin.dart';
import '../../../../core/mixins/ui/sort_menu_mixin.dart';
import '../../../../core/mixins/ui/empty_state_mixin.dart';

import '../controllers/customer_filter_controller.dart';
import '../controllers/customer_dialog_manager.dart';
import '../controllers/customer_import_controller.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with TickerProviderStateMixin, SearchMixin, SortMenuMixin, EmptyStateMixin {
  late TabController _tabController;
  // SearchMixin provides searchController, searchQuery and searchVisible
  late CustomerDialogManager _dialogManager;
  late CustomerImportController _importController;
  String _sortBy = 'name';
  bool _sortAscending = true;

  final List<String> _filterTabs = ['All', 'Recent', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _importController = CustomerImportController(context);
    _dialogManager = CustomerDialogManager(context, _importController);
    _tabController = TabController(length: _filterTabs.length, vsync: this);
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
        title: const Text('Customers'),
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
                  tabs: _filterTabs.map((filter) => Tab(text: filter)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.isLoading && appState.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: _filterTabs
                .map((filter) => _buildCustomersList(appState, filter))
                .toList(),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag:
                'import_customers_fab_customers_screen', // Ensure unique heroTag
            onPressed: _showImportOptions,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.file_upload),
            label: const Text('Import'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag:
                'add_customer_fab_customers_screen', // Ensure unique heroTag
            onPressed: () => _showAddCustomerDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
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
            hintText: 'Search customers by name, phone, email...',
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

  Widget _buildCustomersList(AppStateProvider appState, String filter) {
    final controller = CustomerFilterController(appState);
    List<Customer> customers = controller.getFilteredCustomers(
        filter: filter,
        searchQuery: searchQuery,
        sortBy: _sortBy,
        sortAscending: _sortAscending);
    if (customers.isEmpty) return _buildEmptyState(filter);

    return RefreshIndicator(
      onRefresh: () => appState.loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          final quoteCount =
              appState.getSimplifiedQuotesForCustomer(customer.id).length;
          return CustomerCard(
            customer: customer,
            quoteCount: quoteCount,
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

  void _showAddCustomerDialog(BuildContext context) {
    _dialogManager.showAddCustomerDialog();
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    _dialogManager.showEditCustomerDialog(customer);
  }

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    _dialogManager.showDeleteConfirmation(customer);
  }

  void _showImportOptions() {
    _dialogManager.showImportOptions();
  }

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(customer: customer)));
  }
}
