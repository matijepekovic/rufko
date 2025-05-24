import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../models/quote.dart';
import '../models/multi_level_quote.dart';
import '../widgets/dashboard_card.dart';
import 'customers_screen.dart';
import 'quotes_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';
import 'customer_detail_screen.dart';
import 'quote_detail_screen.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().initializeApp();
      _animationController.forward();
    });
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
          const QuotesScreen(),
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
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      floatingActionButton: _selectedIndex == 0 ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildEnhancedDashboard() {
    return Scaffold(
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
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
                        _buildQuickInsights(appState),
                        const SizedBox(height: 100), // Bottom padding for FAB
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
    final stats = appState.getDashboardStats();
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
              padding: const EdgeInsets.all(16),
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
                        child: const Icon(
                          Icons.roofing,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rufko Professional',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Roofing Estimation & Management',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
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
                      _buildHeaderStat(
                        'Revenue',
                        NumberFormat.compactCurrency(symbol: '\$')
                            .format(stats['totalRevenue'] ?? 0),
                        Icons.attach_money,
                      ),
                      const SizedBox(width: 24),
                      _buildHeaderStat(
                        'Active Quotes',
                        '${stats['activeQuotes'] ?? 0}',
                        Icons.description,
                      ),
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
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message.isNotEmpty ? message : 'Loading...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 4),
            children: [
              _buildActionCard(
                'New Customer',
                Icons.person_add,
                Colors.blue,
                    () => _showAddCustomerDialog(),
              ),
              _buildActionCard(
                'Create Quote',
                Icons.note_add,
                Colors.green,
                    () => _showNewQuoteDialog(),
              ),
              _buildActionCard(
                'Multi-Level Quote',
                Icons.layers,
                Colors.purple,
                    () => _showMultiLevelQuoteDialog(),
              ),
              _buildActionCard(
                'Import RoofScope',
                Icons.file_upload,
                Colors.orange,
                    () => _importRoofScope(),
              ),
              _buildActionCard(
                'Take Photo',
                Icons.camera_alt,
                Colors.teal,
                    () => _takePhoto(),
              ),
              _buildActionCard(
                'Add Product',
                Icons.inventory_2,
                Colors.indigo,
                    () => _navigateToTab(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(AppStateProvider appState) {
    final stats = appState.getDashboardStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            DashboardCard(
              title: 'Total Customers',
              value: '${stats['totalCustomers'] ?? 0}',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => _navigateToTab(1),
            ),
            DashboardCard(
              title: 'Active Quotes',
              value: '${stats['activeQuotes'] ?? 0}',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => _navigateToTab(2),
            ),
            DashboardCard(
              title: 'Products',
              value: '${stats['totalProducts'] ?? 0}',
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () => _navigateToTab(3),
            ),
            DashboardCard(
              title: 'Revenue',
              value: NumberFormat.compactCurrency(symbol: '\$')
                  .format(stats['totalRevenue'] ?? 0),
              icon: Icons.attach_money,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _navigateToTab(2),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecentQuotes(appState),
      ],
    );
  }

  Widget _buildRecentQuotes(AppStateProvider appState) {
    final recentQuotes = [...appState.quotes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentMultiQuotes = [...appState.multiLevelQuotes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Combine and sort all quotes by date
    final allRecentItems = <dynamic>[];
    allRecentItems.addAll(recentQuotes.take(3));
    allRecentItems.addAll(recentMultiQuotes.take(2));
    allRecentItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allRecentItems.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      child: Column(
        children: allRecentItems.take(5).map((item) {
          if (item is Quote) {
            return _buildQuoteListItem(item, appState);
          } else if (item is MultiLevelQuote) {
            return _buildMultiLevelQuoteListItem(item, appState);
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }

  Widget _buildQuoteListItem(Quote quote, AppStateProvider appState) {
    final customer = appState.customers.firstWhere(
          (c) => c.id == quote.customerId,
      orElse: () => Customer(name: 'Unknown Customer'),
    );

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getStatusColor(quote.status).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getQuoteStatusIcon(quote.status),
          color: _getStatusColor(quote.status),
          size: 20,
        ),
      ),
      title: Text('Quote ${quote.quoteNumber}'),
      subtitle: Text(customer.name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            NumberFormat.currency(symbol: '\$').format(quote.total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatDate(quote.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuoteDetailScreen(quote: quote),
        ),
      ),
    );
  }

  Widget _buildMultiLevelQuoteListItem(MultiLevelQuote quote, AppStateProvider appState) {
    final customer = appState.customers.firstWhere(
          (c) => c.id == quote.customerId,
      orElse: () => Customer(name: 'Unknown Customer'),
    );

    // Get highest level total
    double highestTotal = 0;
    if (quote.levels.isNotEmpty) {
      final sortedLevels = quote.levels.values.toList()
        ..sort((a, b) => b.levelNumber.compareTo(a.levelNumber));
      highestTotal = quote.getLevelTotal(sortedLevels.first.levelId);
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.layers,
          color: Colors.purple,
          size: 20,
        ),
      ),
      title: Text('MLQ ${quote.quoteNumber}'),
      subtitle: Text('${customer.name} • ${quote.levels.length} levels'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            NumberFormat.currency(symbol: '\$').format(highestTotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatDate(quote.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening MLQ ${quote.quoteNumber}')),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No quotes yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first quote to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights(AppStateProvider appState) {
    final stats = appState.getDashboardStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Insights',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Pending',
                '${stats['pendingQuotes'] ?? 0}',
                'quotes awaiting response',
                Colors.orange,
                Icons.schedule,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard(
                'Accepted',
                '${stats['acceptedQuotes'] ?? 0}',
                'quotes won this month',
                Colors.green,
                Icons.check_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showQuickCreateDialog,
      icon: const Icon(Icons.add),
      label: const Text('Quick Create'),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.grey;
      case 'sent': return Colors.blue;
      case 'accepted': return Colors.green;
      case 'declined': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getQuoteStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Icons.edit_outlined;
      case 'sent': return Icons.send_outlined;
      case 'accepted': return Icons.check_circle_outline;
      case 'declined': return Icons.cancel_outlined;
      default: return Icons.description_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Action Methods
  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Customer'),
        content: const Text('Navigate to Customers tab to add a new customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToTab(1);
            },
            child: const Text('Go to Customers'),
          ),
        ],
      ),
    );
  }

  void _showNewQuoteDialog() {
    final appState = context.read<AppStateProvider>();
    if (appState.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add customers first to create quotes')),
      );
      return;
    }
    _navigateToTab(2);
  }

  void _showMultiLevelQuoteDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Multi-level quotes require RoofScope data. Import RoofScope PDF first.')),
    );
  }

  void _importRoofScope() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RoofScope import: Go to Customers → Select Customer → Import RoofScope')),
    );
  }

  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo capture: Go to Customers → Customer Details → Add Media')),
    );
  }

  void _showQuickCreateDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Create',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('New Customer'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add, color: Colors.green),
              title: const Text('New Quote'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers, color: Colors.purple),
              title: const Text('Multi-Level Quote'),
              onTap: () {
                Navigator.pop(context);
                _showMultiLevelQuoteDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.orange),
              title: const Text('New Product'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(3);
              },
            ),
          ],
        ),
      ),
    );
  }
}