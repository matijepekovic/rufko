import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../widgets/customer_card.dart';
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
  String _sortBy = 'name'; // 'name', 'date', 'activity'
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
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 18),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                    if (_sortBy == 'name') ...[
                      Spacer(),
                      Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18),
                    SizedBox(width: 8),
                    Text('Sort by Date'),
                    if (_sortBy == 'date') ...[
                      Spacer(),
                      Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'activity',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 8),
                    Text('Sort by Activity'),
                    if (_sortBy == 'activity') ...[
                      Spacer(),
                      Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppStateProvider>().loadAllData();
            },
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
          if (appState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
            heroTag: 'import',
            onPressed: _showImportOptions,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.file_upload),
            label: const Text('Import'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
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
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCustomersList(AppStateProvider appState, String filter) {
    List<Customer> customers = _getFilteredCustomers(appState, filter);

    if (customers.isEmpty) {
      return _buildEmptyState(filter);
    }

    return RefreshIndicator(
      onRefresh: () => appState.loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return CustomerCard(
            customer: customer,
            onTap: () => _navigateToCustomerDetail(customer),
            onEdit: () => _showEditCustomerDialog(context, customer),
            onDelete: () => _showDeleteConfirmation(context, customer),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String title, subtitle;
    IconData icon;

    switch (filter) {
      case 'Recent':
        icon = Icons.schedule;
        title = 'No recent customers';
        subtitle = 'Customers added in the last 30 days will appear here';
        break;
      case 'Active':
        icon = Icons.trending_up;
        title = 'No active customers';
        subtitle = 'Customers with recent quotes or activity will appear here';
        break;
      case 'Inactive':
        icon = Icons.trending_down;
        title = 'No inactive customers';
        subtitle = 'Customers without recent activity will appear here';
        break;
      default:
        icon = Icons.people_outline;
        title = _searchQuery.isEmpty ? 'No customers yet' : 'No customers found';
        subtitle = _searchQuery.isEmpty
            ? 'Add your first customer to get started'
            : 'Try adjusting your search terms';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && filter == 'All') ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddCustomerDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Customer'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _showImportOptions,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Customer> _getFilteredCustomers(AppStateProvider appState, String filter) {
    List<Customer> customers = _searchQuery.isEmpty
        ? appState.customers
        : appState.searchCustomers(_searchQuery);

    // Apply filter
    switch (filter) {
      case 'Recent':
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        customers = customers.where((c) => c.createdAt.isAfter(thirtyDaysAgo)).toList();
        break;
      case 'Active':
      // Customers with quotes or recent communication
        customers = customers.where((c) {
          final hasRecentQuotes = appState.quotes.any((q) =>
          q.customerId == c.id &&
              q.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 90))));
          final hasRecentCommunication = c.communicationHistory.isNotEmpty &&
              c.updatedAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));
          return hasRecentQuotes || hasRecentCommunication;
        }).toList();
        break;
      case 'Inactive':
      // Customers without recent activity
        customers = customers.where((c) {
          final hasRecentQuotes = appState.quotes.any((q) =>
          q.customerId == c.id &&
              q.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 90))));
          final hasRecentCommunication = c.updatedAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));
          return !hasRecentQuotes && !hasRecentCommunication;
        }).toList();
        break;
    }

    // Apply sorting
    customers.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'activity':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'name':
        default:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return customers;
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(),
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(customer: customer),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${customer.name}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also delete all associated quotes, RoofScope data, and media files.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteCustomer(customer.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${customer.name} deleted'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // TODO: Implement undo functionality
                    },
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Import Customers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.table_chart, color: Colors.green.shade700),
              ),
              title: const Text('Import from Excel'),
              subtitle: const Text('Import customer data from Excel spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                _importFromExcel();
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.contacts, color: Colors.blue.shade700),
              ),
              title: const Text('Import from Contacts'),
              subtitle: const Text('Import customers from device contacts'),
              onTap: () {
                Navigator.pop(context);
                _importFromContacts();
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.restore, color: Colors.orange.shade700),
              ),
              title: const Text('Restore from Backup'),
              subtitle: const Text('Restore customers from backup file'),
              onTap: () {
                Navigator.pop(context);
                _importFromBackup();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _importFromExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel import functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _importFromContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contacts import functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _importFromBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup restore functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;

  const _CustomerFormDialog({this.customer});

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
    if (_isEditing) {
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
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit : Icons.person_add,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Customer' : 'Add New Customer',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEditing ? 'Update customer information' : 'Enter customer details',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes',
                        icon: Icons.note,
                        maxLines: 3,
                        hint: 'Additional information about the customer...',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_isEditing ? 'Update Customer' : 'Add Customer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppStateProvider>();

    if (_isEditing) {
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
      SnackBar(
        content: Text(_isEditing ? 'Customer updated successfully!' : 'Customer added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}