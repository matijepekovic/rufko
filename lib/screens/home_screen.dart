// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart'; // Use the new quote model
// import '../models/quote.dart'; // Keep if QuoteItem is needed directly, or if simplified_quote.dart imports it

import '../widgets/dashboard_card.dart';
import 'customers_screen.dart';
import 'quotes_screen.dart'; // This screen will display SimplifiedMultiLevelQuotes
import 'products_screen.dart';
import 'settings_screen.dart';

// Import the detail screens for navigation
import 'customer_detail_screen.dart'; // Assuming this exists
import 'simplified_quote_detail_screen.dart'; // Use the new detail screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PageController _pageController = PageController();

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
    const BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Quotes'),
    const BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
    const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // initializeApp is now called in main.dart before AppStateProvider is created/provided
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<AppStateProvider>().initializeApp(); // REMOVE THIS if called in main
    //   _animationController.forward();
    // });
    _animationController.forward(); // Start animation
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildEnhancedDashboard(),
          const CustomersScreen(),
          const QuotesScreen(), // This screen now handles SimplifiedMultiLevelQuotes
          const ProductsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        items: _navItems,
        selectedItemColor: Theme.of(context).primaryColor,
        // backgroundColor: Colors.white, // Set in theme
        // elevation: 8,
      ),
      floatingActionButton: _selectedIndex == 0 ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildEnhancedDashboard() {
    return Scaffold( // Added Scaffold for the dashboard page itself
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.isLoading && appState.simplifiedQuotes.isEmpty) { // Show loading if quotes are empty
            return _buildLoadingState(appState.loadingMessage);
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(appState),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildStatsOverview(appState),
                        const SizedBox(height: 24),
                        _buildRecentActivity(appState),
                        const SizedBox(height: 24),
                        // _buildQuickInsights(appState), // You can re-add this
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(AppStateProvider appState) {
    final stats = appState.getDashboardStats(); // This now uses simplifiedQuotes
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16).copyWith(top: kToolbarHeight / 2), // Adjust for appbar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.roofing, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rufko Professional', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Roofing Estimation & Management', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => appState.loadAllData(),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildHeaderStat('Revenue', NumberFormat.compactCurrency(symbol: '\$').format(stats['totalRevenue'] ?? 0.0), Icons.attach_money),
                      const SizedBox(width: 24),
                      _buildHeaderStat('Active Quotes', '${stats['activeQuotes'] ?? 0}', Icons.description),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    // ... (This method is likely fine)
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(String message) {
    // ... (This method is fine)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message.isNotEmpty ? message : 'Loading Dashboard...', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    // ... (This method mostly calls navigation or shows snackbars, should be mostly fine)
    // Update _showMultiLevelQuoteDialog to navigate to SimplifiedQuoteScreen or remove it
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildActionCard('New Customer', Icons.person_add, Colors.blue, () => _navigateToTab(1)), // Navigate to CustomersScreen
              _buildActionCard('Create Quote', Icons.note_add, Colors.green, () => _navigateToTab(2)), // Navigate to QuotesScreen (which then opens SimplifiedQuoteScreen)
              // _buildActionCard('Multi-Level Quote', Icons.layers, Colors.purple, () => _navigateToTab(2)), // Redundant, handled by "Create Quote" now
              _buildActionCard('Add Product', Icons.inventory_2, Colors.indigo, () => _navigateToTab(3)),
              // _buildActionCard('Import RoofScope', Icons.file_upload, Colors.orange, _importRoofScope), // Defer this
              // _buildActionCard('Take Photo', Icons.camera_alt, Colors.teal, _takePhoto), // Defer this
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    // ... (This method is likely fine for styling)
    return Container( /* ... your existing card code ... */ );
  }

  Widget _buildStatsOverview(AppStateProvider appState) {
    // ... (This method uses getDashboardStats, which now uses simplifiedQuotes, so it should be fine)
    final stats = appState.getDashboardStats();
    return Column( /* ... your existing stats grid ... */);
  }

  Widget _buildRecentActivity(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Quotes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => _navigateToTab(2), child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 10),
        _buildRecentSimplifiedQuotesList(appState), // Changed to new method
      ],
    );
  }

  Widget _buildRecentSimplifiedQuotesList(AppStateProvider appState) {
    // Now only uses SimplifiedMultiLevelQuote
    final recentSimplifiedQuotes = [...appState.simplifiedQuotes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (recentSimplifiedQuotes.isEmpty) {
      return _buildEmptyRecentState(); // New empty state for recent items
    }

    return Card(
      elevation: 1,
      child: Column(
        children: recentSimplifiedQuotes.take(5).map((quote) { // Take 5 most recent
          return _buildSimplifiedQuoteListItem(quote, appState);
        }).toList(),
      ),
    );
  }

  Widget _buildSimplifiedQuoteListItem(SimplifiedMultiLevelQuote quote, AppStateProvider appState) {
    final customer = appState.customers.firstWhere(
          (c) => c.id == quote.customerId,
      orElse: () => Customer(name: 'Unknown Customer'),
    );

    // Determine a representative total (e.g., first level or average)
    double representativeTotal = 0;
    if (quote.levels.isNotEmpty) {
      representativeTotal = quote.getDisplayTotalForLevel(quote.levels.first.id);
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getStatusColor(quote.status).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getQuoteStatusIcon(quote.status), color: _getStatusColor(quote.status), size: 20),
      ),
      title: Text('Quote ${quote.quoteNumber} (${quote.levels.length} level${quote.levels.length == 1 ? "" : "s"})'),
      subtitle: Text(customer.name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(NumberFormat.currency(symbol: '\$').format(representativeTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_formatDate(quote.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SimplifiedQuoteDetailScreen(quote: quote, customer: customer)),
      ),
    );
  }


  Widget _buildEmptyRecentState() {
    // ... (Similar to _buildEmptyState but for recent items section)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No recent activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // _buildQuickInsights can be re-added if needed, using stats from appState.getDashboardStats()

  Widget _buildFloatingActionButton() {
    // ... (FAB logic is fine)
    return FloatingActionButton.extended(
      onPressed: _showQuickCreateDialog, // This will need to be adapted
      icon: const Icon(Icons.add),
      label: const Text('Quick Create'),
    );
  }

  // Helper Methods
  Color _getStatusColor(String status) { /* ... same ... */ return Colors.grey; }
  IconData _getQuoteStatusIcon(String status) { /* ... same ... */ return Icons.description_outlined;}
  String _formatDate(DateTime date) { return DateFormat('MMM dd, yyyy').format(date); } // Changed format slightly
  void _navigateToTab(int index) { /* ... same ... */ }

  // Action Methods
  // void _showAddCustomerDialog() { /* ... same ... */ }

  // This now just navigates to the QuotesScreen where user can create a new quote
  void _showNewQuoteDialog() => _navigateToTab(2);

  // This is now obsolete as SimplifiedQuoteScreen handles multi-level
  // void _showMultiLevelQuoteDialog() { ... }

  // _importRoofScope, _takePhoto can be re-implemented later.

  void _showQuickCreateDialog() {
    // Adapt this to navigate to appropriate screens or trigger actions
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quick Create', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('New Customer'),
              onTap: () { Navigator.pop(context); _navigateToTab(1); },
            ),
            ListTile(
              leading: const Icon(Icons.note_add, color: Colors.green),
              title: const Text('New Quote'), // This will now use SimplifiedQuoteScreen
              onTap: () { Navigator.pop(context); _navigateToTab(2); },
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.orange),
              title: const Text('New Product'),
              onTap: () { Navigator.pop(context); _navigateToTab(3); },
            ),
          ],
        ),
      ),
    );
  }
}