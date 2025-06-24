// lib/screens/home_screen.dart - PROPERLY RESPONSIVE WITH MIXINS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

import '../../../sales/presentation/screens/sales_screen.dart';
import '../../../jobs/presentation/screens/jobs_screen.dart';
import '../../../vault/presentation/screens/vault_screen.dart';
import '../../../tools/presentation/screens/tools_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/home_layout_small.dart';
import '../widgets/home_layout_large.dart';
import '../../../../core/widgets/custom_header.dart';

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

  // Navigation items no longer needed with custom navigation
  // final List<BottomNavigationBarItem> _navItems = [
  //   const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
  //   const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sales'),
  //   const BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Jobs'),
  //   const BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Vault'),
  //   const BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: 'Tools'),
  // ];

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
      const SalesScreen(),
      const JobsScreen(),
      const VaultScreen(),
      const ToolsScreen(),
    ];

    final fab = _selectedIndex == 0 ? _buildFloatingActionButton() : null;

    return responsiveBuilder(
      context: context,
      mobile: HomeSmallLayout(
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavItemTapped,
        onPageChanged: _onPageChanged,
        pageController: _navController.pageController,
        pages: pages,
        floatingActionButton: fab,
      ),
      tablet: HomeSmallLayout(
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavItemTapped,
        onPageChanged: _onPageChanged,
        pageController: _navController.pageController,
        pages: pages,
        floatingActionButton: fab,
      ),
      desktop: HomeLargeLayout(
        selectedIndex: _selectedIndex,
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
    return SliverToBoxAdapter(
      child: CustomHeader(
        title: 'Dashboard',
        leadingIcon: Icons.dashboard_rounded,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded),
            color: Colors.grey[700],
          ),
        ],
      ),
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