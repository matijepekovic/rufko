// lib/screens/home_screen.dart - PROPERLY RESPONSIVE WITH MIXINS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart';
import '../theme/rufko_theme.dart';
import '../mixins/responsive_breakpoints_mixin.dart';
import '../mixins/responsive_dimensions_mixin.dart';
import '../mixins/responsive_spacing_mixin.dart';
import '../mixins/responsive_text_mixin.dart';
import '../mixins/responsive_widget_mixin.dart';

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
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        pageController: _pageController,
        pages: pages,
        floatingActionButton: fab,
      ),
      tablet: HomeSmallLayout(
        selectedIndex: _selectedIndex,
        navItems: _navItems,
        onItemSelected: _onNavItemTapped,
        onPageChanged: _onPageChanged,
        pageController: _pageController,
        pages: pages,
        floatingActionButton: fab,
      ),
      desktop: HomeLargeLayout(
        selectedIndex: _selectedIndex,
        navItems: _navItems,
        onItemSelected: _onNavItemTapped,
        onPageChanged: _onPageChanged,
        pageController: _pageController,
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
                          _buildStatsOverview(appState),
                          SizedBox(height: spacingMD(context)),
                          _buildRecentCustomers(appState),
                          SizedBox(height: spacingMD(context)),
                          _buildRecentActivity(appState),
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
    final stats = appState.getDashboardStats();

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
              color: Colors.white.withOpacity(0.9),
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
              color: Colors.white.withOpacity(0.9),
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

  Widget _buildStatsOverview(AppStateProvider appState) {
    final stats = appState.getDashboardStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: headlineSmall(context).copyWith(
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: spacingMD(context)),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = getGridColumns(
              context,
              xs: 2,
              sm: 2,
              md: 2,
              lg: 2,
              xl: 2,
            );

            final cardWidth = (constraints.maxWidth - (spacingMD(context) * (columns - 1))) / columns;

            return Wrap(
              spacing: spacingMD(context),
              runSpacing: spacingMD(context),
              children: [
                _buildStatsCard(
                  'Total Customers',
                  '${stats['totalCustomers'] ?? 0}',
                  Icons.people,
                  Colors.blue.shade600,
                      () => _navigateToTab(1),
                  cardWidth,
                ),
                _buildStatsCard(
                  'Total Quotes',
                  '${stats['totalQuotes'] ?? 0}',
                  Icons.description,
                  Colors.green.shade600,
                      () => _navigateToTab(2),
                  cardWidth,
                ),
                _buildStatsCard(
                  'Active Products',
                  '${stats['totalProducts'] ?? 0}',
                  Icons.inventory,
                  Colors.purple.shade600,
                      () => _navigateToTab(3),
                  cardWidth,
                ),
                _buildStatsCard(
                  'Monthly Revenue',
                  NumberFormat.compactCurrency(symbol: r'$').format(stats['monthlyRevenue'] ?? 0.0),
                  Icons.trending_up,
                  Colors.orange.shade600,
                  null,
                  cardWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsCard(
      String title,
      String value,
      IconData icon,
      Color color,
      VoidCallback? onTap,
      double width,
      ) {
    final orientationScale = isLandscape(context) ? 1.5 : 1.0;
    final iconSize = responsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    ) * orientationScale;
    final basePadding = cardPadding(context);
    final scaledPadding = EdgeInsets.fromLTRB(
      basePadding.left * orientationScale,
      basePadding.top * orientationScale,
      basePadding.right * orientationScale,
      basePadding.bottom * orientationScale,
    );

    Widget cardContent = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(spacingMD(context) * orientationScale),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(spacingMD(context) * orientationScale),
        child: Padding(
          padding: scaledPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: responsiveFlex(context, mobile: 1, tablet: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(
                          spacingSM(context) * orientationScale,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            spacingSM(context) * 1.5 * orientationScale,
                          ),
                        ),
                        child: Icon(icon, color: color, size: iconSize),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: iconSize * 0.6,
                        color: Colors.grey[400],
                      ),
                  ],
                ),
              ),
              SizedBox(height: spacingSM(context) * orientationScale),
              Flexible(
                flex: responsiveFlex(context, mobile: 2, tablet: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: headlineSmall(context).copyWith(
                            fontSize: headlineSmall(context).fontSize! * orientationScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacingXS(context) * orientationScale),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: labelMedium(context).copyWith(
                            fontSize: labelMedium(context).fontSize! * orientationScale,
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

    return SizedBox(
      width: width,
      child: responsiveAspectRatio(
        context: context,
        child: cardContent,
        mobileRatio: 2.2,
        tabletRatio: 2.5,
        desktopRatio: 2.8,
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
            Expanded(
              child: Text(
                'Recent Customers',
                style: headlineSmall(context).copyWith(
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTab(1),
              child: Text('View All', style: labelLarge(context)),
            ),
          ],
        ),
        SizedBox(height: spacingSM(context)),

        if (recentCustomers.isEmpty)
          _buildEmptyCustomersState()
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacingSM(context) * 1.5),
            ),
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
      contentPadding: responsivePadding(context, horizontal: 2, vertical: 1),
      leading: CircleAvatar(
        radius: responsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
        backgroundColor: RufkoTheme.primaryColor.withValues(alpha: 0.1),
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
          style: titleSmall(context).copyWith(
            fontWeight: FontWeight.bold,
            color: RufkoTheme.primaryColor,
          ),
        ),
      ),
      title: Text(
        customer.name,
        style: titleSmall(context).copyWith(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (customer.phone != null) ...[
            Icon(Icons.phone, size: labelSmall(context).fontSize, color: Colors.grey[500]),
            SizedBox(width: spacingXS(context)),
            Expanded(
              child: Text(
                customer.phone!,
                style: bodySmall(context).copyWith(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else if (customer.email != null) ...[
            Icon(Icons.email, size: labelSmall(context).fontSize, color: Colors.grey[500]),
            SizedBox(width: spacingXS(context)),
            Expanded(
              child: Text(
                customer.email!,
                style: bodySmall(context).copyWith(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                'Added ${_formatDate(customer.createdAt)}',
                style: bodySmall(context).copyWith(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: quoteCount > 0
          ? Container(
        padding: responsivePadding(context, horizontal: 1, vertical: 0.5),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(spacingSM(context)),
        ),
        child: Text(
          '$quoteCount quote${quoteCount == 1 ? '' : 's'}',
          style: labelSmall(context).copyWith(
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacingSM(context) * 1.5),
      ),
      child: Padding(
        padding: responsivePadding(context, all: 4),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(spacingMD(context)),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: responsiveValue(context, mobile: 36.0, tablet: 42.0, desktop: 48.0),
                color: Colors.blue.shade600,
              ),
            ),
            SizedBox(height: spacingMD(context)),
            Text(
              'No customers yet',
              style: titleMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: spacingSM(context)),
            Text(
              'Add your first customer to get started',
              style: bodyMedium(context).copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingMD(context)),
            FractionallySizedBox(
              widthFactor: responsiveValue(context, mobile: 0.8, tablet: 0.6, desktop: 0.5),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToTab(1),
                icon: const Icon(Icons.add),
                label: Text('Add Customer', style: labelLarge(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: responsivePadding(context, horizontal: 2, vertical: 1.5),
                ),
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
            Expanded(
              child: Text(
                'Recent Quotes',
                style: headlineSmall(context).copyWith(
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTab(2),
              child: Text('View All', style: labelLarge(context)),
            ),
          ],
        ),
        SizedBox(height: spacingSM(context)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacingSM(context) * 1.5),
      ),
      child: Column(
        children: recentQuotes.take(5).map((quote) {
          return _buildQuoteListItem(quote, appState);
        }).toList(),
      ),
    );
  }

  Widget _buildQuoteListItem(
      SimplifiedMultiLevelQuote quote, AppStateProvider appState) {
    final customer = appState.customers.firstWhere(
          (c) => c.id == quote.customerId,
      orElse: () => Customer(name: 'Unknown Customer'),
    );

    double representativeTotal = 0;
    if (quote.levels.isNotEmpty) {
      representativeTotal = quote.getDisplayTotalForLevel(quote.levels.first.id);
    }

    return ListTile(
      contentPadding: responsivePadding(context, horizontal: 2, vertical: 1),
      leading: Container(
        width: responsiveValue(context, mobile: 36.0, tablet: 40.0, desktop: 44.0),
        height: responsiveValue(context, mobile: 36.0, tablet: 40.0, desktop: 44.0),
        decoration: BoxDecoration(
          color: _getStatusColor(quote.status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(spacingSM(context)),
        ),
        child: Icon(
          _getQuoteStatusIcon(quote.status),
          color: _getStatusColor(quote.status),
          size: responsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
        ),
      ),
      title: Text(
        'Quote ${quote.quoteNumber}',
        style: titleSmall(context).copyWith(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.name,
            style: bodySmall(context),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacingXS(context)),
          Row(
            children: [
              Flexible(
                flex: responsiveFlex(context, mobile: 1),
                child: Container(
                  padding: responsivePadding(context, horizontal: 0.75, vertical: 0.25),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(spacingSM(context) * 0.5),
                  ),
                  child: Text(
                    '${quote.levels.length} level${quote.levels.length == 1 ? "" : "s"}',
                    style: labelSmall(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: spacingSM(context)),
              Expanded(
                flex: responsiveFlex(context, mobile: 2),
                child: Text(
                  _formatDate(quote.createdAt),
                  style: labelSmall(context).copyWith(color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          NumberFormat.compactCurrency(symbol: r'$').format(representativeTotal),
          style: titleMedium(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacingSM(context) * 1.5),
      ),
      child: Padding(
        padding: responsivePadding(context, all: 4),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(spacingMD(context)),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: responsiveValue(context, mobile: 36.0, tablet: 42.0, desktop: 48.0),
                color: Colors.green.shade600,
              ),
            ),
            SizedBox(height: spacingMD(context)),
            Text(
              'No quotes yet',
              style: titleMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: spacingSM(context)),
            Text(
              'Create your first quote to get started',
              style: bodyMedium(context).copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacingMD(context)),
            FractionallySizedBox(
              widthFactor: responsiveValue(context, mobile: 0.8, tablet: 0.6, desktop: 0.5),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToTab(2),
                icon: const Icon(Icons.add),
                label: Text('Create Quote', style: labelLarge(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: responsivePadding(context, horizontal: 2, vertical: 1.5),
                ),
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
      label: Text(
        'Quick Create',
        style: labelLarge(context),
      ),
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
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.all(spacingMD(context)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(spacingLG(context)),
        ),
        child: responsiveSafeArea(
          context: context,
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: responsivePadding(context, all: 2.5),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacingSM(context)),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(spacingSM(context)),
                        ),
                        child: Icon(Icons.add, color: Colors.blue.shade600),
                      ),
                      SizedBox(width: spacingSM(context)),
                      Text(
                        'Quick Create',
                        style: titleLarge(context).copyWith(
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
                SizedBox(height: spacingLG(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: responsivePadding(context, horizontal: 2.5, vertical: 1),
      leading: Container(
        padding: EdgeInsets.all(spacingSM(context)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(spacingSM(context)),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: titleSmall(context).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: bodySmall(context)),
      onTap: onTap,
    );
  }
}