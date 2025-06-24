// lib/screens/quotes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/widgets/search_chip_ui_components.dart';

import '../controllers/quote_navigation_controller.dart';
import '../controllers/quote_list_builder.dart';
import '../controllers/quote_filter_controller.dart';
// Import the new screens

import '../../../../core/mixins/ui/sort_menu_mixin.dart';
import '../../../../core/mixins/ui/empty_state_mixin.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen>
    with SortMenuMixin, EmptyStateMixin {
  late QuoteNavigationController _navigationController;
  late QuoteListBuilder _listBuilder;
  late QuoteFilterController _filterController;
  
  // UI-only search controller (no business logic)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _navigationController = QuoteNavigationController(context);
    _listBuilder = QuoteListBuilder(context, _navigationController);
    _filterController = QuoteFilterController(context.read<AppStateProvider>());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ALWAYS VISIBLE SEARCH BAR (using new UI component)
        AlwaysVisibleSearchBar(
          controller: _searchController,
          hintText: 'Search quotes ...',
          showBottomBorder: false, // Remove border since ChipFilterRow follows
          onChanged: (value) {
            _filterController.updateSearch(value);
            setState(() {}); // Only trigger UI rebuild
          },
          actionButtons: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort quotes',
              onSelected: (value) {
                _filterController.setSortBy(value);
                setState(() {});
              },
              itemBuilder: (context) => [
                buildSortMenuItem(
                  label: 'Date',
                  icon: Icons.access_time,
                  value: 'date',
                  currentSortBy: _filterController.sortBy,
                  sortAscending: _filterController.sortAscending,
                ),
                buildSortMenuItem(
                  label: 'Amount',
                  icon: Icons.attach_money,
                  value: 'amount',
                  currentSortBy: _filterController.sortBy,
                  sortAscending: _filterController.sortAscending,
                ),
                buildSortMenuItem(
                  label: 'Customer',
                  icon: Icons.person,
                  value: 'customer',
                  currentSortBy: _filterController.sortBy,
                  sortAscending: _filterController.sortAscending,
                ),
                buildSortMenuItem(
                  label: 'Status',
                  icon: Icons.flag,
                  value: 'status',
                  currentSortBy: _filterController.sortBy,
                  sortAscending: _filterController.sortAscending,
                ),
              ],
            ),
          ],
        ),
        
        // CHIP FILTERS SECTION (using reusable UI component)
        ChipFilterRow(
          filterOptions: _filterController.getStatusOptions(),
          selectedFilter: _filterController.selectedStatus,
          onFilterSelected: (filter) {
            _filterController.selectStatus(filter);
            setState(() {}); // Only trigger UI rebuild
          },
        ),
        
        // QUOTES LIST CONTENT (using filter controller)
        Expanded(
          child: Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              if (appState.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildSimplifiedQuotesList(appState);
            },
          ),
        ),
      ],
    );
  }


  // Sorting logic can be re-added and adapted for SimplifiedMultiLevelQuote
  // Widget _buildSortMenuItem(String label, IconData icon, String value) { ... }

  Widget _buildSimplifiedQuotesList(AppStateProvider appState) {
    return _listBuilder.buildQuotesList(
      appState: appState,
      filter: _filterController,
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
