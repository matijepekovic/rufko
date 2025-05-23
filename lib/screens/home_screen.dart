import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/recent_quotes_list.dart';
import '../widgets/quick_actions.dart';
import 'customers_screen.dart';
import 'quotes_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Customers',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.description),
      label: 'Quotes',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.inventory),
      label: 'Products',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().initializeApp();
    });
  }

  @override
  void dispose() {
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
          _buildDashboard(),
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
      ),
    );
  }

  Widget _buildDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rufko Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppStateProvider>().loadAllData();
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(appState.loadingMessage),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => appState.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
                    'Welcome to Rufko',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional Roofing Estimation & Management',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const QuickActions(),
                  const SizedBox(height: 32),

                  // Dashboard Stats
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsGrid(appState),
                  const SizedBox(height: 32),

                  // Recent Quotes
                  Text(
                    'Recent Quotes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RecentQuotesList(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsGrid(AppStateProvider appState) {
    final stats = [
      {
        'title': 'Total Customers',
        'value': appState.customers.length.toString(),
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Active Quotes',
        'value': appState.quotes.where((q) => q.status != 'declined').length.toString(),
        'icon': Icons.description,
        'color': Colors.green,
      },
      {
        'title': 'Products',
        'value': appState.products.length.toString(),
        'icon': Icons.inventory,
        'color': Colors.orange,
      },
      {
        'title': 'Total Revenue',
        'value': '\$${_calculateTotalRevenue(appState.quotes).toStringAsFixed(0)}',
        'icon': Icons.attach_money,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return DashboardCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
        );
      },
    );
  }

  double _calculateTotalRevenue(List quotes) {
    return quotes
        .where((q) => q.status == 'accepted')
        .fold(0.0, (sum, quote) => sum + quote.total);
  }

  void _showQuickCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Create'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('New Customer'),
              onTap: () {
                Navigator.pop(context);
                _onNavItemTapped(1); // Navigate to customers
                // TODO: Add customer creation logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('New Quote'),
              onTap: () {
                Navigator.pop(context);
                _onNavItemTapped(2); // Navigate to quotes
                // TODO: Add quote creation logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('New Product'),
              onTap: () {
                Navigator.pop(context);
                _onNavItemTapped(3); // Navigate to products
                // TODO: Add product creation logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import RoofScope'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add RoofScope import logic
              },
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
}