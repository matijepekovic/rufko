import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/recent_customers_service.dart';
import '../controllers/customer_selection_controller.dart';
import '../controllers/customer_dialog_manager.dart';
import '../controllers/customer_import_controller.dart';
import '../../../../shared/widgets/buttons/rufko_buttons.dart';

class CustomerSelectionScreen extends StatefulWidget {
  final Function(Customer) onCustomerSelected;

  const CustomerSelectionScreen({
    super.key,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerSelectionScreen> createState() => _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  late CustomerSelectionController _controller;
  late CustomerDialogManager _dialogManager;
  late CustomerImportController _importController;
  final _searchController = TextEditingController();
  List<Customer> _recentCustomers = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    _controller = CustomerSelectionController(appState);
    _importController = CustomerImportController(context, appState);
    _dialogManager = CustomerDialogManager(context, _importController);
    _loadRecentCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentCustomers() async {
    final appState = context.read<AppStateProvider>();
    final recent = await RecentCustomersService.getRecentCustomers(appState.customers);
    setState(() {
      _recentCustomers = recent;
      _isLoadingRecent = false;
    });
  }

  void _onCustomerSelected(Customer customer) async {
    await RecentCustomersService.addRecentCustomer(customer.id);
    widget.onCustomerSelected(customer);
  }

  void _onSearchChanged(String query) {
    _controller.updateSearchQuery(query);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _dialogManager.showAddCustomerDialog(),
            tooltip: 'Add New Customer',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import') {
                _dialogManager.showImportOptions();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Import Customers'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers by name, phone, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _controller.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Results count
          if (_controller.searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_controller.filteredCustomerCount} of ${_controller.totalCustomerCount} customers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Customer List
          Expanded(
            child: _buildCustomerList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    if (!_controller.hasCustomers) {
      return _buildEmptyState();
    }

    if (_controller.searchQuery.isEmpty) {
      return _buildRecentAndAllCustomers();
    } else {
      return _buildSearchResults();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Customers Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first customer to create quotes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          RufkoPrimaryButton(
            onPressed: () => _dialogManager.showAddCustomerDialog(),
            icon: Icons.person_add,
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAndAllCustomers() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Customers Section
          if (!_isLoadingRecent && _recentCustomers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Customers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ..._recentCustomers.map((customer) => _buildCustomerTile(customer)),
            const Divider(height: 32),
          ],

          // All Customers Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'All Customers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildGroupedCustomerList(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final filtered = _controller.getFilteredCustomers();
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildCustomerTile(filtered[index]),
    );
  }

  Widget _buildGroupedCustomerList() {
    final grouped = _controller.getGroupedCustomers();
    final keys = _controller.getGroupKeys();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys.map((letter) {
        final customers = grouped[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              width: double.infinity,
              child: Text(
                letter,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            // Customers in this group
            ...customers.map((customer) => _buildCustomerTile(customer)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        customer.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customer.phone != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(customer.phone!),
              ],
            ),
          ],
          if (customer.city != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(customer.city!),
              ],
            ),
          ],
        ],
      ),
      onTap: () => _onCustomerSelected(customer),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}