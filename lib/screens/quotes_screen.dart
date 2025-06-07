// lib/screens/quotes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart'; // Using the new quote model
import '../models/roof_scope_data.dart'; // For creating new quotes

// Import the new screens
import 'simplified_quote_screen.dart';
import 'simplified_quote_detail_screen.dart';
import '../mixins/search_mixin.dart';
import '../mixins/sort_menu_mixin.dart';
import '../mixins/empty_state_mixin.dart';



class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen>
    with TickerProviderStateMixin, SearchMixin, SortMenuMixin, EmptyStateMixin {
  late TabController _tabController;
  // SearchMixin provides searchController, searchQuery and searchVisible
  // String _sortBy = 'date'; // 'date', 'amount', 'customer', 'status' // You can re-add sorting later
  // bool _sortAscending = false;

  final List<String> _statusTabs = ['All', 'Draft', 'Sent', 'Accepted', 'Declined', 'Expired'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
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
        title: const Text('Quotes'), // Simplified title
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(searchVisible ? Icons.search_off : Icons.search),
            onPressed: toggleSearch,
          ),
          // Sorting can be re-added later if needed
          // PopupMenuButton<String>(...),
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
                  tabs: _statusTabs.map((status) => Tab(text: status)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: _statusTabs.map((status) => _buildSimplifiedQuotesList(appState, status)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_quote',
        onPressed: _navigateToCreateQuoteScreen,
        icon: const Icon(Icons.add),
        label: const Text('New Quote'),
      ),
    );
  }

  Widget _buildSearchBar() {
    // ... (your existing _buildSearchBar can likely remain the same)
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
            hintText: 'Search quotes by number or customer...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[600]),
              onPressed: clearSearch,
            ) : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
      ),
    );
  }

  // Sorting logic can be re-added and adapted for SimplifiedMultiLevelQuote
  // Widget _buildSortMenuItem(String label, IconData icon, String value) { ... }

  Widget _buildSimplifiedQuotesList(AppStateProvider appState, String statusFilter) {
    List<SimplifiedMultiLevelQuote> quotes = appState.simplifiedQuotes;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      quotes = quotes.where((quote) {
        final customer = appState.customers.firstWhere(
              (c) => c.id == quote.customerId,
          orElse: () => Customer(name: ''), // Handle case where customer might not be found
        );
        return quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
            customer.name.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply status filter
    if (statusFilter != 'All') {
      if (statusFilter == 'Expired') {
        quotes = quotes.where((q) => q.isExpired).toList();
      } else {
        quotes = quotes.where((q) => q.status.toLowerCase() == statusFilter.toLowerCase()).toList();
      }
    }

    // Apply sorting (can be re-added later)
    // quotes.sort((a,b) => ...);


    if (quotes.isEmpty) {
      return _buildEmptyState(statusFilter);
    }

    return RefreshIndicator(
      onRefresh: () => appState.loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          final customer = appState.customers.firstWhere(
                (c) => c.id == quote.customerId,
            orElse: () => Customer(name: 'Unknown Customer'),
          );
          // You'll need a QuoteCard or similar widget adapted for SimplifiedMultiLevelQuote
          // For now, let's use a simple ListTile as a placeholder
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('Quote #: ${quote.quoteNumber}'),
              subtitle: Text('Customer: ${customer.name}\nStatus: ${quote.status} - Levels: ${quote.levels.length}'),
              trailing: Text(
                // Display a representative total, e.g., from the first level or an average
                quote.levels.isNotEmpty ? NumberFormat.currency(symbol: '\$').format(quote.getDisplayTotalForLevel(quote.levels.first.id)) : '\$0.00',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _navigateToSimplifiedQuoteDetail(quote, customer),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }


  Widget _buildEmptyState(String status) {
    // ... (your existing _buildEmptyState or _buildEmptyStateContent can be adapted)
    // Ensure the buttons in empty state call _navigateToCreateQuoteScreen
    String title = searchQuery.isEmpty ? 'No quotes for "$status"' : 'No quotes found';
    String subtitle = searchQuery.isEmpty ? 'Create a new quote to see it here.' : 'Try a different search or filter.';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildEmptyState(
            icon: Icons.receipt_long_outlined,
            title: title,
            subtitle: subtitle,
          ),
          if (status == 'All' && searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateQuoteScreen,
              icon: const Icon(Icons.add),
              label: const Text('Create New Quote'),
            ),
          ]
        ],
      ),
    );
  }

  // _buildStatusBadge, _getLevelColor can remain if used by an adapted QuoteCard


  void _navigateToSimplifiedQuoteDetail(SimplifiedMultiLevelQuote quote, Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteDetailScreen(quote: quote, customer: customer),
      ),
    );
  }

  void _navigateToCreateQuoteScreen({Customer? customer, RoofScopeData? roofScopeData}) {
    final appState = context.read<AppStateProvider>();
    if (appState.customers.isEmpty && customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a customer first.'), backgroundColor: Colors.orange),
      );
      // Optionally navigate to customer creation screen
      return;
    }

    // If no customer is passed, prompt to select one (or simplify to always require customer context)
    if (customer == null) {
      _showCustomerSelectionForNewQuote(appState, roofScopeData);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimplifiedQuoteScreen(
            customer: customer,
            roofScopeData: roofScopeData, // Pass if available from context
          ),
        ),
      );
    }
  }

  void _showCustomerSelectionForNewQuote(AppStateProvider appState, RoofScopeData? initialRoofScopeData) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Customer for New Quote'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300, // Adjust as needed
          child: ListView.builder(
            itemCount: appState.customers.length,
            itemBuilder: (context, index) {
              final cust = appState.customers[index];
              return ListTile(
                title: Text(cust.name),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // Close dialog
                  _navigateToCreateQuoteScreen(customer: cust, roofScopeData: initialRoofScopeData);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel'))],
      ),
    );
  }


// --- Methods related to OLD quote systems that need to be removed or heavily adapted ---
// _createMultiLevelQuote, _showCreateQuoteDialog (old simple quote), _createNewQuote, etc.
// These are now replaced by _navigateToCreateQuoteScreen which goes to SimplifiedQuoteScreen.
// The _showNoRoofScopeDialog and _MultiLevelQuoteDialog are also for the old system.
// All logic for differentiating between "standard" and "multi-level" quotes at creation
// is now handled within SimplifiedQuoteScreen by how many levels are configured.

// The following methods were for the old system and should be removed or entirely rethought
// for SimplifiedMultiLevelQuote if similar actions are needed.
// For now, commenting them out.

/*
  void _updateQuoteStatus(Quote quote, String newStatus, AppStateProvider appState) { ... }
  void _showDeleteConfirmation(BuildContext context, Quote quote, AppStateProvider appState) { ... }
  void _duplicateQuote(Quote quote, AppStateProvider appState) { ... }
  void _generatePdf(Quote quote, Customer customer, AppStateProvider appState) { ... }
  */

}