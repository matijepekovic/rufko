import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/quote.dart';
import '../models/customer.dart';
import '../models/multi_level_quote.dart';
import '../widgets/quote_card.dart';
import '../widgets/multi_level_quotes_list.dart';
import 'create_multi_level_quote_screen.dart';
import 'quote_detail_screen.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  bool _showMultiLevel = false;
  String _sortBy = 'date'; // 'date', 'amount', 'customer', 'status'
  bool _sortAscending = false; // Default newest first

  final List<String> _statusTabs = ['All', 'Draft', 'Sent', 'Accepted', 'Declined', 'Expired'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
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
        title: Row(
          children: [
            Text(_showMultiLevel ? 'Multi-Level Quotes' : 'Standard Quotes'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _showMultiLevel ? Colors.purple.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _showMultiLevel ? 'ML' : 'STD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _showMultiLevel ? Colors.purple.shade700 : Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(_showMultiLevel ? Icons.view_list : Icons.layers),
            tooltip: _showMultiLevel ? 'Switch to Standard Quotes' : 'Switch to Multi-Level Quotes',
            onPressed: () {
              setState(() {
                _showMultiLevel = !_showMultiLevel;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (value == _sortBy) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = value == 'customer';
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: _buildSortMenuItem('Date', Icons.calendar_today, 'date'),
              ),
              PopupMenuItem(
                value: 'amount',
                child: _buildSortMenuItem('Amount', Icons.attach_money, 'amount'),
              ),
              PopupMenuItem(
                value: 'customer',
                child: _buildSortMenuItem('Customer', Icons.person, 'customer'),
              ),
              PopupMenuItem(
                value: 'status',
                child: _buildSortMenuItem('Status', Icons.info, 'status'),
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
            children: _statusTabs.map((status) => _buildQuotesList(appState, status)).toList(),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!_showMultiLevel) ...[
            FloatingActionButton.extended(
              heroTag: 'multi_level',
              onPressed: _createMultiLevelQuote,
              backgroundColor: Colors.purple,
              icon: const Icon(Icons.layers),
              label: const Text('Multi-Level'),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton.extended(
            heroTag: 'standard',
            onPressed: _showCreateQuoteDialog,
            backgroundColor: _showMultiLevel ? Colors.blue : null,
            icon: const Icon(Icons.add),
            label: Text(_showMultiLevel ? 'Standard' : 'New Quote'),
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
            hintText: 'Search quotes by number, customer, or amount...',
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

  Widget _buildSortMenuItem(String label, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text('Sort by $label'),
        if (_sortBy == value) ...[
          const Spacer(),
          Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
        ],
      ],
    );
  }

  Widget _buildQuotesList(AppStateProvider appState, String status) {
    if (_showMultiLevel) {
      return _buildMultiLevelQuotesList(appState, status);
    }

    List<Quote> quotes = _getFilteredQuotes(appState, status);

    if (quotes.isEmpty) {
      return _buildEmptyState(status);
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

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: QuoteCard(
              quote: quote,
              customer: customer,
              onTap: () => _navigateToQuoteDetail(quote),
              onStatusChange: (newStatus) => _updateQuoteStatus(quote, newStatus, appState),
              onDelete: () => _showDeleteConfirmation(context, quote, appState),
              onDuplicate: () => _duplicateQuote(quote, appState),
              onGeneratePdf: () => _generatePdf(quote, customer, appState),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMultiLevelQuotesList(AppStateProvider appState, String status) {
    List<MultiLevelQuote> quotes = _getFilteredMultiLevelQuotes(appState, status);

    if (quotes.isEmpty) {
      return _buildMultiLevelEmptyState(status);
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

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildMultiLevelQuoteCard(quote, customer, appState),
          );
        },
      ),
    );
  }

  Widget _buildMultiLevelQuoteCard(MultiLevelQuote quote, Customer customer, AppStateProvider appState) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final sortedLevels = quote.levels.values.toList()
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

    double highestTotal = 0;
    String? highestLevelName;

    if (sortedLevels.isNotEmpty) {
      final highestLevel = sortedLevels.last;
      highestTotal = quote.getLevelTotal(highestLevel.levelId);
      highestLevelName = highestLevel.levelName;
    }

    return Card(
      child: InkWell(
        onTap: () => _navigateToMultiLevelQuoteDetail(quote, customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.layers,
                          color: Colors.purple.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quote ${quote.quoteNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            customer.name,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(quote.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Levels: ${quote.levels.length}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: sortedLevels.take(3).map((level) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getLevelColor(level.levelNumber).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              level.levelName,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getLevelColor(level.levelNumber),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (highestLevelName != null)
                        Text(
                          highestLevelName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        currencyFormat.format(highestTotal),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(quote.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  if (quote.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title, subtitle;
    IconData icon;

    switch (status) {
      case 'Draft':
        icon = Icons.edit_outlined;
        title = 'No draft quotes';
        subtitle = 'Create a new quote to get started';
        break;
      case 'Sent':
        icon = Icons.send_outlined;
        title = 'No sent quotes';
        subtitle = 'Quotes sent to customers will appear here';
        break;
      case 'Accepted':
        icon = Icons.check_circle_outline;
        title = 'No accepted quotes';
        subtitle = 'Quotes accepted by customers will appear here';
        break;
      case 'Declined':
        icon = Icons.cancel_outlined;
        title = 'No declined quotes';
        subtitle = 'Quotes declined by customers will appear here';
        break;
      case 'Expired':
        icon = Icons.schedule;
        title = 'No expired quotes';
        subtitle = 'Expired quotes will appear here';
        break;
      default:
        icon = Icons.description_outlined;
        title = _searchQuery.isEmpty ? 'No quotes yet' : 'No quotes found';
        subtitle = _searchQuery.isEmpty
            ? 'Create your first quote to get started'
            : 'Try adjusting your search terms';
    }

    return _buildEmptyStateContent(icon, title, subtitle, status == 'All' && _searchQuery.isEmpty);
  }

  Widget _buildMultiLevelEmptyState(String status) {
    return _buildEmptyStateContent(
      Icons.layers_outlined,
      'No multi-level quotes yet',
      'Create professional good-better-best quotes',
      status == 'All' && _searchQuery.isEmpty,
      isMultiLevel: true,
    );
  }

  Widget _buildEmptyStateContent(IconData icon, String title, String subtitle, bool showActions, {bool isMultiLevel = false}) {
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
            child: Icon(icon, size: 64, color: Colors.grey[400]),
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
          if (showActions) ...[
            const SizedBox(height: 32),
            if (isMultiLevel) ...[
              ElevatedButton.icon(
                onPressed: _createMultiLevelQuote,
                icon: const Icon(Icons.layers),
                label: const Text('Create Multi-Level Quote'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCreateQuoteDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Quote'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _createMultiLevelQuote,
                    icon: const Icon(Icons.layers),
                    label: const Text('Multi-Level'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  List<Quote> _getFilteredQuotes(AppStateProvider appState, String status) {
    List<Quote> quotes = appState.quotes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      quotes = quotes.where((quote) {
        final customer = appState.customers.firstWhere(
              (c) => c.id == quote.customerId,
          orElse: () => Customer(name: ''),
        );
        return quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
            customer.name.toLowerCase().contains(lowerQuery) ||
            quote.total.toString().contains(lowerQuery);
      }).toList();
    }

    // Apply status filter
    if (status != 'All') {
      if (status == 'Expired') {
        quotes = quotes.where((q) => q.isExpired).toList();
      } else {
        quotes = quotes.where((q) => q.status.toLowerCase() == status.toLowerCase()).toList();
      }
    }

    // Apply sorting
    quotes.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'amount':
          comparison = a.total.compareTo(b.total);
          break;
        case 'customer':
          final customerA = appState.customers.firstWhere(
                (c) => c.id == a.customerId,
            orElse: () => Customer(name: ''),
          );
          final customerB = appState.customers.firstWhere(
                (c) => c.id == b.customerId,
            orElse: () => Customer(name: ''),
          );
          comparison = customerA.name.toLowerCase().compareTo(customerB.name.toLowerCase());
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'date':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return quotes;
  }

  List<MultiLevelQuote> _getFilteredMultiLevelQuotes(AppStateProvider appState, String status) {
    List<MultiLevelQuote> quotes = appState.multiLevelQuotes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      quotes = quotes.where((quote) {
        final customer = appState.customers.firstWhere(
              (c) => c.id == quote.customerId,
          orElse: () => Customer(name: ''),
        );
        return quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
            customer.name.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply status filter
    if (status != 'All') {
      if (status == 'Expired') {
        quotes = quotes.where((q) => q.isExpired).toList();
      } else {
        quotes = quotes.where((q) => q.status.toLowerCase() == status.toLowerCase()).toList();
      }
    }

    // Apply sorting
    quotes.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'amount':
          final totalA = a.levels.isEmpty ? 0.0 : a.levels.values.map((l) => a.getLevelTotal(l.levelId)).reduce((a, b) => a > b ? a : b);
          final totalB = b.levels.isEmpty ? 0.0 : b.levels.values.map((l) => b.getLevelTotal(l.levelId)).reduce((a, b) => a > b ? a : b);
          comparison = totalA.compareTo(totalB);
          break;
        case 'customer':
          final customerA = appState.customers.firstWhere(
                (c) => c.id == a.customerId,
            orElse: () => Customer(name: ''),
          );
          final customerB = appState.customers.firstWhere(
                (c) => c.id == b.customerId,
            orElse: () => Customer(name: ''),
          );
          comparison = customerA.name.toLowerCase().compareTo(customerB.name.toLowerCase());
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'date':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return quotes;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getLevelColor(int levelNumber) {
    switch (levelNumber % 3) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.purple;
    }
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

  void _navigateToQuoteDetail(Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteDetailScreen(quote: quote),
      ),
    );
  }

  void _navigateToMultiLevelQuoteDetail(MultiLevelQuote quote, Customer customer) {
    // TODO: Navigate to multi-level quote detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening multi-level quote ${quote.quoteNumber}')),
    );
  }

  void _updateQuoteStatus(Quote quote, String newStatus, AppStateProvider appState) {
    quote.updateStatus(newStatus);
    appState.updateQuote(quote);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quote status updated to $newStatus')),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Quote quote, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text('Are you sure you want to delete quote ${quote.quoteNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.deleteQuote(quote.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Quote ${quote.quoteNumber} deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateQuote(Quote quote, AppStateProvider appState) {
    final newQuote = Quote(
      customerId: quote.customerId,
      roofScopeDataId: quote.roofScopeDataId,
      items: quote.items.map((item) => QuoteItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        unit: item.unit,
        description: item.description,
      )).toList(),
      taxRate: quote.taxRate,
      discount: quote.discount,
      notes: quote.notes,
    );

    newQuote.calculateTotals();
    appState.addQuote(newQuote);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote duplicated as ${newQuote.quoteNumber}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateToQuoteDetail(newQuote),
        ),
      ),
    );
  }

  void _generatePdf(Quote quote, Customer customer, AppStateProvider appState) async {
    try {
      await appState.generatePdfQuote(quote, customer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateQuoteDialog() {
    final appState = context.read<AppStateProvider>();
    if (appState.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add customers first before creating quotes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a customer to create a quote for:'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: appState.customers.length,
                itemBuilder: (context, index) {
                  final customer = appState.customers[index];
                  return ListTile(
                    title: Text(customer.name),
                    subtitle: Text(customer.phone ?? customer.email ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      _createNewQuote(customer.id, appState);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _createNewQuote(String customerId, AppStateProvider appState) {
    final newQuote = Quote(customerId: customerId);
    appState.addQuote(newQuote);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote ${newQuote.quoteNumber} created'),
        action: SnackBarAction(
          label: 'Edit',
          onPressed: () => _navigateToQuoteDetail(newQuote),
        ),
      ),
    );
  }

  void _createMultiLevelQuote() {
    final appState = context.read<AppStateProvider>();

    // Check if we have customers
    if (appState.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add customers first before creating quotes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if we have RoofScope data
    final customersWithRoofScope = appState.customers.where((customer) {
      final roofScopeData = appState.getRoofScopeDataForCustomer(customer.id);
      return roofScopeData.isNotEmpty;
    }).toList();

    if (customersWithRoofScope.isEmpty) {
      _showNoRoofScopeDialog();
      return;
    }

    // Show customer selection for multi-level quote
    showDialog(
      context: context,
      builder: (context) => _MultiLevelQuoteDialog(customersWithRoofScope: customersWithRoofScope),
    );
  }

  void _showNoRoofScopeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('RoofScope Data Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Multi-level quotes require RoofScope measurement data to calculate accurate material quantities for different quality levels.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To create multi-level quotes:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Import RoofScope PDF for a customer\n'
                        '2. Return here to create multi-level quotes\n'
                        '3. Generate professional Good-Better-Best options',
                    style: TextStyle(fontSize: 14),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to customers screen to import RoofScope
              DefaultTabController.of(context)?.animateTo(1);
            },
            icon: const Icon(Icons.file_upload),
            label: const Text('Import RoofScope'),
          ),
        ],
      ),
    );
  }
}

class _MultiLevelQuoteDialog extends StatefulWidget {
  final List<Customer> customersWithRoofScope;

  const _MultiLevelQuoteDialog({required this.customersWithRoofScope});

  @override
  State<_MultiLevelQuoteDialog> createState() => _MultiLevelQuoteDialogState();
}

class _MultiLevelQuoteDialogState extends State<_MultiLevelQuoteDialog> {
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.layers, color: Colors.purple.shade700),
          ),
          const SizedBox(width: 12),
          const Text('Create Multi-Level Quote'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a customer with RoofScope data:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: widget.customersWithRoofScope.length,
                itemBuilder: (context, index) {
                  final customer = widget.customersWithRoofScope[index];
                  final isSelected = _selectedCustomer?.id == customer.id;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple.shade50 : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.purple.shade200)
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.purple.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.person,
                          color: isSelected
                              ? Colors.purple.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            Icons.roofing,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'RoofScope data available',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.purple.shade700)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCustomer = customer;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.purple.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Multi-level quotes automatically create Good-Better-Best options based on RoofScope measurements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _selectedCustomer == null ? null : _createMultiLevelQuote,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          icon: const Icon(Icons.layers),
          label: const Text('Create Quote'),
        ),
      ],
    );
  }

  void _createMultiLevelQuote() {
    if (_selectedCustomer == null) return;

    final appState = context.read<AppStateProvider>();
    final roofScopeData = appState.getRoofScopeDataForCustomer(_selectedCustomer!.id);

    if (roofScopeData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No RoofScope data found for this customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);

    // Navigate to the multi-level quote creation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMultiLevelQuoteScreen(
          customer: _selectedCustomer!,
          roofScopeData: roofScopeData.first,
        ),
      ),
    );
  }
}