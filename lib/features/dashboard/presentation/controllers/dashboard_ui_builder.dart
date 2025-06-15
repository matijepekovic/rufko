import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../core/mixins/ui/responsive_text_mixin.dart';
import '../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../core/mixins/ui/responsive_widget_mixin.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../customers/presentation/screens/customer_detail_screen.dart';
import '../../../quotes/presentation/screens/simplified_quote_detail_screen.dart';
import '../../../../core/utils/helpers/dashboard_status_helper.dart';
import 'dashboard_data_controller.dart';
import 'dashboard_navigation_controller.dart';

class DashboardUIBuilder
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin {
  DashboardUIBuilder(this.context,
      {required this.dataController, required this.navigationController});

  final BuildContext context;
  final DashboardDataController dataController;
  final DashboardNavigationController navigationController;

  Widget buildStatsOverview() {
    final stats = dataController.getDashboardStats();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildStatsCard(
                'Customers',
                stats['totalCustomers'].toString(),
                Colors.blue,
                () => navigationController.navigateToTab(1),
              ),
            ),
            SizedBox(width: spacingSM(context)),
            Expanded(
              child: _buildStatsCard(
                'Quotes',
                stats['totalQuotes'].toString(),
                Colors.green,
                () => navigationController.navigateToTab(2),
              ),
            ),
          ],
        ),
        SizedBox(height: spacingSM(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildStatsCard(
                'Products',
                stats['totalProducts'].toString(),
                Colors.orange,
                () => navigationController.navigateToTab(3),
              ),
            ),
            SizedBox(width: spacingSM(context)),
            Expanded(
              child: _buildStatsCard(
                'Revenue',
                NumberFormat.compactCurrency(symbol: r'$')
                    .format(stats['totalRevenue']),
                Colors.purple,
                null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildRecentCustomers() {
    final customers = dataController.getRecentCustomers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Customers',
                style: headlineSmall(context).copyWith(color: Colors.grey[800]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => navigationController.navigateToTab(1),
              child: Text('View All', style: labelLarge(context)),
            ),
          ],
        ),
        SizedBox(height: spacingSM(context)),
        if (customers.isEmpty)
          _buildEmptyCustomersState()
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacingSM(context) * 1.5),
            ),
            child: Column(
              children: customers.take(5).map((customer) {
                final quoteCount =
                    dataController.quotesForCustomer(customer.id).length;
                return _buildCustomerListItem(customer, quoteCount);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget buildRecentActivity() {
    final quotes = dataController.getRecentQuotes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Quotes',
                style: headlineSmall(context).copyWith(color: Colors.grey[800]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => navigationController.navigateToTab(2),
              child: Text('View All', style: labelLarge(context)),
            ),
          ],
        ),
        SizedBox(height: spacingSM(context)),
        _buildRecentQuotesList(quotes),
      ],
    );
  }

  // --- Private Helpers ---
  Widget _buildStatsCard(
    String title,
    String value,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: responsivePadding(context, all: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(spacingSM(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: labelMedium(context)),
            SizedBox(height: spacingXS(context)),
            Text(
              value,
              style: headlineMedium(context).copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              widthFactor:
                  responsiveValue(context, mobile: 0.8, tablet: 0.6, desktop: 0.5),
              child: ElevatedButton.icon(
                onPressed: () => navigationController.navigateToTab(1),
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
                'Added ${DashboardStatusHelper.formatDate(customer.createdAt)}',
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

  Widget _buildRecentQuotesList(List<SimplifiedMultiLevelQuote> quotes) {
    if (quotes.isEmpty) {
      return _buildEmptyQuotesState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacingSM(context) * 1.5),
      ),
      child: Column(
        children: quotes.take(5).map((quote) {
          return _buildQuoteListItem(quote);
        }).toList(),
      ),
    );
  }

  Widget _buildQuoteListItem(SimplifiedMultiLevelQuote quote) {
    final customer = dataController.appState.customers.firstWhere(
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
          color: DashboardStatusHelper.statusColor(quote.status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(spacingSM(context)),
        ),
        child: Icon(
          DashboardStatusHelper.statusIcon(quote.status),
          color: DashboardStatusHelper.statusColor(quote.status),
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
                  padding:
                      responsivePadding(context, horizontal: 0.75, vertical: 0.25),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(spacingSM(context) * 0.5),
                  ),
                  child: Text(
                    '${quote.levels.length} level${quote.levels.length == 1 ? '' : 's'}',
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
                  DashboardStatusHelper.formatDate(quote.createdAt),
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
          style: titleMedium(context).copyWith(fontWeight: FontWeight.bold),
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
              widthFactor:
                  responsiveValue(context, mobile: 0.8, tablet: 0.6, desktop: 0.5),
              child: ElevatedButton.icon(
                onPressed: () => navigationController.navigateToTab(2),
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
}
