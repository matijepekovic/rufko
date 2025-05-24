import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/quote.dart';
import '../models/customer.dart';
import '../widgets/quote_card.dart';
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

  final List<String> _statusTabs = ['All', 'Draft', 'Sent', 'Accepted', 'Declined'];

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
      appBar: AppBar(
        title: const Text('Quotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppStateProvider>().loadAllData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusTabs.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search quotes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusTabs.map((status) => _buildQuotesList(status)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateQuoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuotesList(String status) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        List<Quote> quotes = appState.quotes;

        // Filter by status
        if (status != 'All') {
          quotes = quotes.where((q) => q.status.toLowerCase() == status.toLowerCase()).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          quotes = quotes.where((q) {
            final customer = appState.customers.firstWhere(
                  (c) => c.id == q.customerId,
              orElse: () => Customer(name: 'Unknown'),
            );
            return q.quoteNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Sort by creation date (newest first)
        quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No ${status.toLowerCase()} quotes'
                      : 'No quotes found',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Create your first quote to get started'
                      : 'Try adjusting your search terms',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                if (_searchQuery.isEmpty && status == 'All') ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateQuoteDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Quote'),
                  ),
                ],
              ],
            ),
          );
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
                orElse: () => Customer(name: 'Unknown'),
              );

              return QuoteCard(
                quote: quote,
                customer: customer,
                onTap: () => _navigateToQuoteDetail(quote),
                onStatusChange: (newStatus) => _updateQuoteStatus(quote, newStatus),
                onDelete: () => _showDeleteConfirmation(context, quote),
                onDuplicate: () => _duplicateQuote(quote),
                onGeneratePdf: () => _generatePdf(quote, customer),
              );
            },
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      if (_searchQuery.isNotEmpty) {
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

  void _updateQuoteStatus(Quote quote, String newStatus) {
    quote.updateStatus(newStatus);
    context.read<AppStateProvider>().updateQuote(quote);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote status updated to $newStatus'),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Quote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text(
          'Are you sure you want to delete quote ${quote.quoteNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteQuote(quote.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Quote ${quote.quoteNumber} deleted'),
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

  void _duplicateQuote(Quote quote) {
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
    context.read<AppStateProvider>().addQuote(newQuote);

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

  void _generatePdf(Quote quote, Customer customer) async {
    try {
      final appState = context.read<AppStateProvider>();
      final filePath = await appState.generatePdfQuote(quote, customer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF generated successfully'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // TODO: Open PDF file
            },
          ),
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

  void _showCreateQuoteDialog(BuildContext context) {
    final appState = context.read<AppStateProvider>();

    if (appState.customers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Customers'),
          content: const Text('You need to add customers before creating quotes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Quote'),
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
                      _createNewQuote(customer.id);
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

  void _createNewQuote(String customerId) {
    final newQuote = Quote(customerId: customerId);
    context.read<AppStateProvider>().addQuote(newQuote);

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
}
