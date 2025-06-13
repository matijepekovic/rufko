// lib/screens/quotes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';

import '../controllers/quote_navigation_controller.dart';
import '../controllers/quote_list_builder.dart';
// Import the new screens

import '../../../../core/mixins/ui/search_mixin.dart';
import '../../../../core/mixins/ui/sort_menu_mixin.dart';
import '../../../../core/mixins/ui/empty_state_mixin.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen>
    with TickerProviderStateMixin, SearchMixin, SortMenuMixin, EmptyStateMixin {
  late TabController _tabController;
  late QuoteNavigationController _navigationController;
  late QuoteListBuilder _listBuilder;

  final List<String> _statusTabs = [
    'All',
    'Draft',
    'Sent',
    'Accepted',
    'Declined',
    'Expired'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _navigationController = QuoteNavigationController(context);
    _listBuilder = QuoteListBuilder(context, _navigationController);
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
            children: _statusTabs
                .map((status) => _buildSimplifiedQuotesList(appState, status))
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_quote',
        onPressed: _navigationController.navigateToCreateQuote,
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

  // Sorting logic can be re-added and adapted for SimplifiedMultiLevelQuote
  // Widget _buildSortMenuItem(String label, IconData icon, String value) { ... }

  Widget _buildSimplifiedQuotesList(
      AppStateProvider appState, String statusFilter) {
    return _listBuilder.buildQuotesList(
      appState: appState,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );
  }

  // _buildStatusBadge, _getLevelColor can remain if used by an adapted QuoteCard

// --- Methods related to OLD quote systems that need to be removed or heavily adapted ---
// _createMultiLevelQuote, _showCreateQuoteDialog (old simple quote), _createNewQuote, etc.
// These are now replaced by QuoteNavigationController which goes to SimplifiedQuoteScreen.
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
