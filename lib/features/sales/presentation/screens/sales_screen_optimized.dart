import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../quotes/presentation/screens/quotes_screen.dart';
import '../../../../core/widgets/custom_header.dart';
import '../../../../core/widgets/custom_tab_bar.dart';
import '../../../customers/presentation/controllers/customer_dialog_manager.dart';
import '../../../customers/presentation/controllers/customer_import_controller.dart';
import '../../../quotes/presentation/controllers/quote_navigation_controller.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class SalesScreenOptimized extends StatefulWidget {
  const SalesScreenOptimized({super.key});

  @override
  State<SalesScreenOptimized> createState() => _SalesScreenOptimizedState();
}

class _SalesScreenOptimizedState extends State<SalesScreenOptimized> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  late CustomerDialogManager _customerDialogManager;
  late CustomerImportController _customerImportController;
  late QuoteNavigationController _quoteNavigationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final appState = context.read<AppStateProvider>();
    _customerImportController = CustomerImportController(context, appState);
    _customerDialogManager = CustomerDialogManager(context, _customerImportController);
    _quoteNavigationController = QuoteNavigationController(context);
    
    // Listen to tab changes to update FAB
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ResponsiveLayoutBuilder(
      compact: _buildCompactLayout(),
      medium: _buildMediumLayout(),
      expanded: _buildExpandedLayout(),
    );
  }

  Widget _buildCompactLayout() {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Sales',
        leadingIcon: Icons.handshake_rounded,
        bottom: CustomTabBar(
          controller: _tabController,
          tabs: const ['Leads', 'Kanban', 'Quotes'],
        ),
      ),
      body: _buildTabBarView(),
      floatingActionButton: _buildResponsiveFloatingActionButton(),
    );
  }

  Widget _buildMediumLayout() {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Sales',
        leadingIcon: Icons.handshake_rounded,
        bottom: CustomTabBar(
          controller: _tabController,
          tabs: const ['Leads', 'Kanban', 'Quotes'],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildTabBarView(),
      ),
      floatingActionButton: _buildResponsiveFloatingActionButton(),
    );
  }

  Widget _buildExpandedLayout() {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Sales',
        leadingIcon: Icons.handshake_rounded,
        bottom: CustomTabBar(
          controller: _tabController,
          tabs: const ['Leads', 'Kanban', 'Quotes'],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildTabBarView(),
          ),
        ),
      ),
      floatingActionButton: _buildResponsiveFloatingActionButton(),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        const CustomersScreen(),
        _buildKanbanPlaceholder(),
        const QuotesScreen(),
      ],
    );
  }

  Widget _buildKanbanPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_kanban_outlined,
            size: 80.0,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.0),
          Text(
            'Kanban Board',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: 28.0,
            ),
          ),
          SizedBox(height: 16.0),
          Text(
            'Coming Soon - Visual project management',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget? _buildResponsiveFloatingActionButton() {
    // Use MediaQuery to determine screen size instead of responsive methods
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return _buildExpandedFAB();
    } else if (screenWidth > 600) {
      return _buildMediumFAB();
    } else {
      return _buildCompactFAB();
    }
  }

  Widget? _buildCompactFAB() {
    switch (_tabController.index) {
      case 0:
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: "import_customer_compact",
              onPressed: () => _customerDialogManager.showImportOptions(),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.file_upload, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: "add_customer_compact",
              onPressed: () => _customerDialogManager.showAddCustomerDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        );
      case 2:
        return FloatingActionButton(
          heroTag: "add_quote_compact",
          onPressed: () => _quoteNavigationController.navigateToCreateQuote(),
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return null;
    }
  }

  Widget? _buildMediumFAB() {
    switch (_tabController.index) {
      case 0:
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: "import_customer_medium",
              onPressed: () => _customerDialogManager.showImportOptions(),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.file_upload, color: Colors.white),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "add_customer_medium",
              onPressed: () => _customerDialogManager.showAddCustomerDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Lead', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: "add_quote_medium",
          onPressed: () => _quoteNavigationController.navigateToCreateQuote(),
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Quote', style: TextStyle(color: Colors.white)),
        );
      default:
        return null;
    }
  }

  Widget? _buildExpandedFAB() {
    switch (_tabController.index) {
      case 0:
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: "import_customer_expanded",
              onPressed: () => _customerDialogManager.showImportOptions(),
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.file_upload, color: Colors.white),
              label: const Text('Import Leads', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "add_customer_expanded",
              onPressed: () => _customerDialogManager.showAddCustomerDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Lead', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: "add_quote_expanded",
          onPressed: () => _quoteNavigationController.navigateToCreateQuote(),
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Create Quote', style: TextStyle(color: Colors.white)),
        );
      default:
        return null;
    }
  }
}

class _ResponsiveLayoutBuilder extends StatelessWidget {
  
  final Widget compact;
  final Widget medium;
  final Widget expanded;

  const _ResponsiveLayoutBuilder({
    required this.compact,
    required this.medium,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        
        if (width < 600) {
          return compact;
        } else if (width < 1240) {
          return medium;
        } else {
          return expanded;
        }
      },
    );
  }
}