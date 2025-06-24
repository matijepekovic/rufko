import 'package:flutter/material.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../quotes/presentation/screens/quotes_screen.dart';
import '../../../../core/widgets/custom_header.dart';
import '../../../../core/widgets/custom_tab_bar.dart';
import '../../../customers/presentation/controllers/customer_dialog_manager.dart';
import '../../../customers/presentation/controllers/customer_import_controller.dart';
import '../../../quotes/presentation/controllers/quote_navigation_controller.dart';
import '../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../widgets/optimized_sales_provider.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> 
    with SingleTickerProviderStateMixin, 
         ResponsiveBreakpointsMixin, 
         ResponsiveDimensionsMixin,
         ResponsiveSpacingMixin,
         OptimizedResponsiveMixin {
  
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
    return OptimizedResponsiveWidget(
      child: BreakpointBuilder(
        builder: (context, breakpoint, isMobile, isTablet, isDesktop) {
          return Scaffold(
            appBar: CustomHeader(
              title: 'Sales',
              leadingIcon: Icons.handshake_rounded,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<AppStateProvider>().loadAllData(),
                  tooltip: 'Refresh Data',
                  color: Colors.grey[800],
                ),
              ],
              bottom: CustomTabBar(
                controller: _tabController,
                tabs: const ['Leads', 'Kanban', 'Quotes'],
              ),
            ),
            body: _buildResponsiveBody(context, isMobile, isTablet, isDesktop),
            floatingActionButton: _buildResponsiveFloatingActionButton(isMobile, isTablet, isDesktop),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveBody(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    Widget tabContent = TabBarView(
      controller: _tabController,
      children: [
        const CustomersScreen(),
        _buildKanbanPlaceholder(),
        const QuotesScreen(),
      ],
    );

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: screenPadding(context),
            child: tabContent,
          ),
        ),
      );
    } else if (isTablet) {
      return Padding(
        padding: responsivePadding(context, all: 3),
        child: tabContent,
      );
    } else {
      return tabContent;
    }
  }

  Widget _buildKanbanPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_kanban_outlined,
            size: responsiveValue(
              context,
              mobile: 64.0,
              tablet: 80.0,
              desktop: 96.0,
            ),
            color: Colors.grey[400],
          ),
          SizedBox(height: spacingXL(context)),
          Text(
            'Kanban Board',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: responsiveValue(
                context,
                mobile: 24.0,
                tablet: 28.0,
                desktop: 32.0,
              ),
            ),
          ),
          SizedBox(height: spacingMD(context)),
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

  Widget? _buildResponsiveFloatingActionButton(bool isMobile, bool isTablet, bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopFAB();
    } else if (isTablet) {
      return _buildTabletFAB();
    } else {
      return _buildMobileFAB();
    }
  }

  Widget? _buildMobileFAB() {
    switch (_tabController.index) {
      case 0:
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: "import_customer_mobile",
              onPressed: () => _customerDialogManager.showImportOptions(),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.file_upload, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: "add_customer_mobile",
              onPressed: () => _customerDialogManager.showAddCustomerDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        );
      case 2:
        return FloatingActionButton(
          heroTag: "add_quote_mobile",
          onPressed: () => _quoteNavigationController.navigateToCreateQuote(),
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return null;
    }
  }

  Widget? _buildTabletFAB() {
    switch (_tabController.index) {
      case 0:
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: "import_customer_tablet",
              onPressed: () => _customerDialogManager.showImportOptions(),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.file_upload, color: Colors.white),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "add_customer_tablet",
              onPressed: () => _customerDialogManager.showAddCustomerDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Lead', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: "add_quote_tablet",
          onPressed: () => _quoteNavigationController.navigateToCreateQuote(),
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Quote', style: TextStyle(color: Colors.white)),
        );
      default:
        return null;
    }
  }

  Widget? _buildDesktopFAB() {
    switch (_tabController.index) {
      case 0:
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: "import_customer_desktop",
              onPressed: () => _customerDialogManager.showImportOptions(),
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.file_upload, color: Colors.white),
              label: const Text('Import Leads', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: "add_customer_desktop",
              onPressed: () => _customerDialogManager.showAddCustomerDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Lead', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: "add_quote_desktop",
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