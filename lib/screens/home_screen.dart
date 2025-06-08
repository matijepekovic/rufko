// lib/screens/home_screen.dart - CLEAN VERSION WITH BLUE THEME

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart';
import '../theme/rufko_theme.dart';

import 'customers_screen.dart';
import 'quotes_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';
import 'customer_detail_screen.dart';
import 'simplified_quote_detail_screen.dart';
import 'templates_screen.dart';
import 'layouts/home_layout_small.dart';
import 'layouts/home_layout_large.dart';

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
    const BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: 'Templates'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
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
    final pages = [
      _buildModernDashboard(),
      const CustomersScreen(),
      const QuotesScreen(),
      const ProductsScreen(),
      const TemplatesScreen(),
    ];

    final fab = _selectedIndex == 0 ? _buildFloatingActionButton() : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 900;
        if (isLargeScreen) {
          return HomeLargeLayout(
            selectedIndex: _selectedIndex,
            navItems: _navItems,
            onItemSelected: _onNavItemTapped,
            pageController: _pageController,
            pages: pages,
            floatingActionButton: fab,
          );
        }

        return HomeSmallLayout(
          selectedIndex: _selectedIndex,
          navItems: _navItems,
          onItemSelected: _onNavItemTapped,
          pageController: _pageController,
          pages: pages,
          floatingActionButton: fab,
        );
      },
    );
  }

  Widget _buildModernDashboard() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (appState.isLoading && appState.simplifiedQuotes.isEmpty) {
          return _buildLoadingState(appState.loadingMessage);
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () => appState.loadAllData(),
            child: CustomScrollView(
              slivers: [
                _buildModernSliverAppBar(appState),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsOverview(appState),
                        const SizedBox(height: 16),
                        _buildRecentCustomers(appState),
                        const SizedBox(height: 16),
                        _buildRecentActivity(appState),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernSliverAppBar(AppStateProvider appState) {
    final stats = appState.getDashboardStats();
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RufkoTheme.primaryColor, // Blue from your roof
                RufkoTheme.primaryDarkColor, // Darker blue
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        // Large prominent logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo/rufko_full_logo.png',
                              fit: BoxFit.cover,
                              cacheWidth: 315,
                              cacheHeight: 315,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Logo load error: $error');
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.roofing, color: RufkoTheme.primaryColor, size: 60),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Stats positioned to the right of logo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total Revenue',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                NumberFormat.compactCurrency(symbol: r'$').format(stats['totalRevenue'] ?? 0.0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Active Quotes',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${stats['activeQuotes'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings),
          color: Colors.white,
        ),
      ],
    );
  }


  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 24),
          Text(
            message.isNotEmpty ? message : 'Loading Dashboard...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(AppStateProvider appState) {
    final stats = appState.getDashboardStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 2;
            final aspectRatio = cardWidth > 160 ? 1.8 : 2.2;
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              padding: EdgeInsets.zero,
              children: [
                _buildStatsCard(
                  'Total Customers',
                  '${stats['totalCustomers'] ?? 0}',
                  Icons.people,
                  Colors.blue.shade600,
                      () => _navigateToTab(1),
                ),
                _buildStatsCard(
                  'Total Quotes',
                  '${stats['totalQuotes'] ?? 0}',
                  Icons.description,
                  Colors.green.shade600,
                      () => _navigateToTab(2),
                ),
                _buildStatsCard(
                  'Active Products',
                  '${stats['totalProducts'] ?? 0}',
                  Icons.inventory,
                  Colors.purple.shade600,
                      () => _navigateToTab(3),
                ),
                _buildStatsCard(
                  'Monthly Revenue',
                  NumberFormat.compactCurrency(symbol: r'$').format(stats['monthlyRevenue'] ?? 0.0),
                  Icons.trending_up,
                  Colors.orange.shade600,
                  null,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color, VoidCallback? onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (onTap != null)
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRecentCustomers(AppStateProvider appState) {
    final recentCustomers = [...appState.customers]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Customers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTab(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (recentCustomers.isEmpty)
          _buildEmptyCustomersState()
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: recentCustomers.take(5).map((customer) {
                final quoteCount = appState.getSimplifiedQuotesForCustomer(customer.id).length;
                return _buildCustomerListItem(customer, quoteCount);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomerListItem(Customer customer, int quoteCount) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: RufkoTheme.primaryColor.withValues(alpha: 0.1),
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: RufkoTheme.primaryColor,
          ),
        ),
      ),
      title: Text(
        customer.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          if (customer.phone != null) ...[
            Icon(Icons.phone, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(customer.phone!, style: TextStyle(color: Colors.grey[600])),
          ] else if (customer.email != null) ...[
            Icon(Icons.email, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                customer.email!,
                style: TextStyle(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Text(
              'Added ${_formatDate(customer.createdAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
      trailing: quoteCount > 0
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$quoteCount quote${quoteCount == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
        ),
      )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerDetailScreen(customer: customer),
        ),
      ),
    );
  }

  Widget _buildEmptyCustomersState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline, size: 48, color: Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'No customers yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first customer to get started',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToTab(1),
              icon: const Icon(Icons.add),
              label: const Text('Add Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AppStateProvider appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Quotes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTab(2),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRecentQuotesList(appState),
      ],
    );
  }

  Widget _buildRecentQuotesList(AppStateProvider appState) {
    final recentQuotes = [...appState.simplifiedQuotes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (recentQuotes.isEmpty) {
      return _buildEmptyQuotesState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: recentQuotes.take(5).map((quote) {
          return _buildQuoteListItem(quote, appState);
        }).toList(),
      ),
    );
  }

  Widget _buildQuoteListItem(SimplifiedMultiLevelQuote quote, AppStateProvider appState) {
    final customer = appState.customers.firstWhere(
          (c) => c.id == quote.customerId,
      orElse: () => Customer(name: 'Unknown Customer'),
    );

    double representativeTotal = 0;
    if (quote.levels.isNotEmpty) {
      representativeTotal = quote.getDisplayTotalForLevel(quote.levels.first.id);
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getStatusColor(quote.status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getQuoteStatusIcon(quote.status),
          color: _getStatusColor(quote.status),
          size: 20,
        ),
      ),
      title: Text(
        'Quote ${quote.quoteNumber}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.name,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${quote.levels.length} level${quote.levels.length == 1 ? "" : "s"}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(quote.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            NumberFormat.compactCurrency(symbol: r'$').format(representativeTotal),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimplifiedQuoteDetailScreen(
            quote: quote,
            customer: customer,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQuotesState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined, size: 48, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'No quotes yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first quote to get started',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToTab(2),
              icon: const Icon(Icons.add),
              label: const Text('Create Quote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
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
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Quick Create'),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade600;
      case 'sent':
        return Colors.blue.shade600;
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getQuoteStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit_outlined;
      case 'sent':
        return Icons.send_outlined;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
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

  void _showQuickCreateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: Colors.blue.shade600),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Create',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildQuickActionTile(
              'New Customer',
              'Add a new customer to your database',
              Icons.person_add,
              Colors.blue.shade600,
                  () {
                Navigator.pop(context);
                _navigateToTab(1);
              },
            ),
            _buildQuickActionTile(
              'New Quote',
              'Create a professional roofing estimate',
              Icons.note_add,
              Colors.green.shade600,
                  () {
                Navigator.pop(context);
                _navigateToTab(2);
              },
            ),
            _buildQuickActionTile(
              'New Product',
              'Add products to your inventory',
              Icons.add_box,
              Colors.orange.shade600,
                  () {
                Navigator.pop(context);
                _navigateToTab(3);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}