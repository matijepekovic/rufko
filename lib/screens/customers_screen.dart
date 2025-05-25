// lib/screens/customers_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart'; // For type hinting in AppStateProvider calls
import '../widgets/customer_card.dart';   // Assuming this will be adapted
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  String _sortBy = 'name';
  bool _sortAscending = true;

  final List<String> _filterTabs = ['All', 'Recent', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
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
        title: const Text('Customers'),
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
              _buildSortMenuItem('Date Added', Icons.calendar_today, 'date'),
              _buildSortMenuItem('Last Activity', Icons.access_time, 'activity'),
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
            children: _filterTabs.map((filter) => _buildCustomersList(appState, filter)).toList(),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_customers_fab_customers_screen', // Ensure unique heroTag
            onPressed: _showImportOptions,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.file_upload),
            label: const Text('Import'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_customer_fab_customers_screen', // Ensure unique heroTag
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
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search customers by name, phone, email...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600]),
              onPressed: _clearSearch,
            ) : null,
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

  Widget _buildCustomersList(AppStateProvider appState, String filter) {
    List<Customer> customers = _getFilteredCustomers(appState, filter);
    if (customers.isEmpty) return _buildEmptyState(filter);

    return RefreshIndicator(
      onRefresh: () => appState.loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          final quoteCount = appState.getSimplifiedQuotesForCustomer(customer.id).length;
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
    // ... (Content from previous correct version) ...
    String title, subtitle; IconData icon;
    switch (filter) { /* ... */ default: icon = Icons.people_outline; title = _searchQuery.isEmpty ? 'No customers yet' : 'No customers found'; subtitle = _searchQuery.isEmpty ? 'Add your first customer' : 'Try adjusting search'; }
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ /* Icon, Title, Subtitle, Buttons */ ]));
  }


  List<Customer> _getFilteredCustomers(AppStateProvider appState, String filter) {
    List<Customer> customers = _searchQuery.isEmpty
        ? appState.customers
        : appState.searchCustomers(_searchQuery);

    switch (filter) {
      case 'Recent':
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        customers = customers.where((c) => c.createdAt.isAfter(thirtyDaysAgo)).toList();
        break;
      case 'Active':
        customers = customers.where((c) {
          final hasRecentQuotes = appState.simplifiedQuotes.any((q) =>
          q.customerId == c.id && q.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 90))));
          final hasRecentCommunication = c.communicationHistory.isNotEmpty && c.updatedAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));
          return hasRecentQuotes || hasRecentCommunication;
        }).toList();
        break;
      case 'Inactive':
        customers = customers.where((c) {
          final hasRecentQuotes = appState.simplifiedQuotes.any((q) =>
          q.customerId == c.id && q.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 90))));
          final hasRecentCommunication = c.updatedAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));
          return !hasRecentQuotes && !hasRecentCommunication;
        }).toList();
        break;
    }

    customers.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'date': comparison = a.createdAt.compareTo(b.createdAt); break;
        case 'activity':
          DateTime aActivity = a.updatedAt;
          var quotesA = appState.getSimplifiedQuotesForCustomer(a.id);
          if (quotesA.isNotEmpty) {
            quotesA.sort((q1, q2) => q2.createdAt.compareTo(q1.createdAt));
            if (quotesA.first.createdAt.isAfter(aActivity)) aActivity = quotesA.first.createdAt;
          }
          DateTime bActivity = b.updatedAt;
          var quotesB = appState.getSimplifiedQuotesForCustomer(b.id);
          if (quotesB.isNotEmpty) {
            quotesB.sort((q1, q2) => q2.createdAt.compareTo(q1.createdAt));
            if (quotesB.first.createdAt.isAfter(bActivity)) bActivity = quotesB.first.createdAt;
          }
          comparison = aActivity.compareTo(bActivity);
          break;
        default: comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? comparison : -comparison;
    });
    return customers;
  }

  void _toggleSearch() {
    setState(() { _showSearch = !_showSearch; if (!_showSearch) _clearSearch(); });
  }
  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerDetailScreen(customer: customer)));
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const _CustomerFormDialog());
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    showDialog(context: context, builder: (context) => _CustomerFormDialog(customer: customer));
  }

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    // ... (Content from previous correct version, ensuring appState.deleteCustomer is called)
    showDialog(context: context, builder: (dialogContext) => AlertDialog( /* ... content ... */ actions: [ /* ... */ TextButton(onPressed: () { context.read<AppStateProvider>().deleteCustomer(customer.id); Navigator.pop(dialogContext); /* SnackBar */}, child: const Text('Delete'))]));
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import Customers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.table_chart, color: Colors.green.shade700)),
              title: const Text('Import from Excel'),
              subtitle: const Text('Load customer data from .xlsx or .xls file'),
              onTap: () { Navigator.pop(context); _importFromExcel(); },
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.contacts, color: Colors.blue.shade700)),
              title: const Text('Import from Device Contacts'),
              subtitle: const Text('Select customers from your phone contacts'),
              onTap: () { Navigator.pop(context); _importFromContacts(); },
            ),
            // ListTile( // Example for backup restore, if implemented
            //   leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.restore, color: Colors.orange.shade700)),
            //   title: const Text('Restore from Backup'),
            //   subtitle: const Text('Restore customers from a Rufko backup file'),
            //   onTap: () { Navigator.pop(context); _importFromBackup(); },
            // ),
          ],
        ),
      ),
    );
  }

  void _importFromExcel() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Excel import: Navigate to Settings -> Data Management (coming soon)')));
  }
  void _importFromContacts() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts import functionality coming soon')));
  }
  void _importFromBackup() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data import/restore: Navigate to Settings -> Data Management')));
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  const _CustomerFormDialog({Key? key, this.customer}) : super(key: key);

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _notesController.text = widget.customer!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 650), // Adjusted for better scroll
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important for scrollable content
          children: [
            Container( // Header
              padding: const EdgeInsets.all(20), // Adjusted padding
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(_isEditing ? Icons.edit_note : Icons.person_add_alt_1, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(_isEditing ? 'Edit Customer' : 'Add New Customer', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible( // Use Flexible for the scrollable part
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(controller: _nameController, label: 'Full Name*', icon: Icons.person, validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null),
                      const SizedBox(height: 16), // Adjusted spacing
                      _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _emailController, label: 'Email Address', icon: Icons.email, keyboardType: TextInputType.emailAddress, validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                        }
                        return null;
                      }),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _addressController, label: 'Address', icon: Icons.location_on, maxLines: 2),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _notesController, label: 'Notes', icon: Icons.note_alt_outlined, maxLines: 3, hint: 'Additional information...'),
                    ],
                  ),
                ),
              ),
            ),
            Container( // Actions Footer
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _saveCustomer, child: Text(_isEditing ? 'Update Customer' : 'Add Customer')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({ required TextEditingController controller, required String label, required IconData icon, String? hint, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator,}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Adjusted padding
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppStateProvider>();
    if (_isEditing && widget.customer != null) {
      widget.customer!.updateInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      appState.updateCustomer(widget.customer!);
    } else {
      final customer = Customer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      appState.addCustomer(customer);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Customer updated!' : 'Customer added!'), backgroundColor: Colors.green),
    );
  }
}