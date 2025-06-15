// lib/screens/home_screen.dart - PROPERLY RESPONSIVE WITH MIXINS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../core/mixins/ui/responsive_text_mixin.dart';
import '../../../../core/mixins/ui/responsive_widget_mixin.dart';
import '../controllers/dashboard_data_controller.dart';
import '../controllers/dashboard_navigation_controller.dart';
import '../controllers/dashboard_ui_builder.dart';
import '../controllers/quick_actions_controller.dart';

import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../quotes/presentation/screens/quotes_screen.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../templates/presentation/screens/templates_screen.dart';
import '../widgets/home_layout_small.dart';
import '../widgets/home_layout_large.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin,
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin {

  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late DashboardNavigationController _navController;
  late DashboardDataController _dataController;
  late DashboardUIBuilder _uiBuilder;
  late QuickActionsController _quickActions;

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

    _navController = DashboardNavigationController(
      onIndexChanged: (i) => setState(() => _selectedIndex = i),
    );
    _dataController = DashboardDataController(context);
    _uiBuilder = DashboardUIBuilder(
      context,
      dataController: _dataController,
      navigationController: _navController,
    );
    _quickActions = QuickActionsController(
      context,
      navigateToTab: _navController.navigateToTab,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    _navController.onNavItemTapped(index);
  }

  void _onPageChanged(int index) {
    _navController.onPageChanged(index);
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

    return responsiveBuilder(
      context: context,
      mobile: HomeSmallLayout(
        selectedIndex: _selectedIndex,
        navItems: _navItems,
        onItemSelected: _onNavItemTapped,
        onPageChanged: _onPageChanged,
        pageController: _navController.pageController,
        pages: pages,
        floatingActionButton: fab,
      ),
      tablet: HomeSmallLayout(
        selectedIndex: _selectedIndex,
        navItems: _navItems,
        onItemSelected: _onNavItemTapped,
        onPageChanged: _onPageChanged,
        pageController: _navController.pageController,
        pages: pages,
        floatingActionButton: fab,
      ),
      desktop: HomeLargeLayout(
        selectedIndex: _selectedIndex,
        navItems: _navItems,
        onItemSelected: _onNavItemTapped,
        onPageChanged: _onPageChanged,
        pageController: _navController.pageController,
        pages: pages,
        floatingActionButton: fab,
      ),
    );
  }

  Widget _buildModernDashboard() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (appState.isLoading && appState.simplifiedQuotes.isEmpty) {
          return _buildLoadingState(appState.loadingMessage);
        }

        return responsiveSafeArea(
          context: context,
          top: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () => appState.loadAllData(),
              child: CustomScrollView(
                slivers: [
                  _buildModernSliverAppBar(appState),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: screenPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _uiBuilder.buildStatsOverview(),
                          SizedBox(height: spacingMD(context)),
                          _uiBuilder.buildRecentCustomers(),
                          SizedBox(height: spacingMD(context)),
                          _uiBuilder.buildRecentActivity(),
                          SizedBox(height: spacingLG(context)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernSliverAppBar(AppStateProvider appState) {
    final stats = _dataController.getDashboardStats();

    final expandedHeight = responsiveValue(
      context,
      mobile: 160.0,
      tablet: 180.0,
      desktop: 200.0,
    );

    final logoSize = responsiveValue(
      context,
      mobile: isXS(context) ? 60.0 : 80.0,
      tablet: 100.0,
      desktop: 120.0,
    );

    Widget buildLogo() {
      return Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(logoSize * 0.17),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(logoSize * 0.17),
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
                  borderRadius: BorderRadius.circular(logoSize * 0.17),
                ),
                child: Icon(
                  Icons.roofing,
                  color: RufkoTheme.primaryColor,
                  size: logoSize * 0.5,
                ),
              );
            },
          ),
        ),
      );
    }

    Widget buildStats() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Revenue',
            style: bodySmall(context).copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              NumberFormat.compactCurrency(symbol: r'$').format(stats['totalRevenue'] ?? 0.0),
              style: titleLarge(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: spacingSM(context)),
          Text(
            'Active Quotes',
            style: bodySmall(context).copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${stats['activeQuotes'] ?? 0}',
            style: titleLarge(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return SliverAppBar(
      expandedHeight: expandedHeight,
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
                RufkoTheme.primaryColor,
                RufkoTheme.primaryDarkColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: responsivePadding(context, horizontal: 2.5, vertical: 2),
              child: orientationBuilder(
                context: context,
                portrait: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildLogo(),
                    SizedBox(height: spacingMD(context)),
                    Flexible(child: buildStats()),
                  ],
                ),
                landscape: Row(
                  children: [
                    buildLogo(),
                    SizedBox(width: spacingLG(context)),
                    Expanded(child: buildStats()),
                  ],
                ),
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
          SizedBox(height: spacingLG(context)),
          Text(
            message.isNotEmpty ? message : 'Loading Dashboard...',
            style: titleMedium(context).copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _quickActions.showQuickCreateDialog,
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(
        'Quick Create',
        style: labelLarge(context),
      ),
    );
  }


}