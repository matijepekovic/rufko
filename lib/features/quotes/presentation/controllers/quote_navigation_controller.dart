import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/roof_scope_data.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/simplified_quote_detail_screen.dart';
import '../screens/simplified_quote_screen.dart';

/// Manages navigation related to quote actions and creation.
class QuoteNavigationController {
  QuoteNavigationController(this.context);

  final BuildContext context;

  void navigateToSimplifiedQuoteDetail(
      SimplifiedMultiLevelQuote quote, Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SimplifiedQuoteDetailScreen(quote: quote, customer: customer),
      ),
    );
  }

  void navigateToCreateQuote(
      {Customer? customer, RoofScopeData? roofScopeData}) {
    final appState = context.read<AppStateProvider>();
    if (appState.customers.isEmpty && customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a customer first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (customer == null) {
      _showCustomerSelection(appState, roofScopeData);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimplifiedQuoteScreen(
            customer: customer,
            roofScopeData: roofScopeData,
          ),
        ),
      );
    }
  }

  void _showCustomerSelection(AppStateProvider appState, RoofScopeData? data) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Customer for New Quote'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: appState.customers.length,
            itemBuilder: (context, index) {
              final cust = appState.customers[index];
              return ListTile(
                title: Text(cust.name),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  navigateToCreateQuote(customer: cust, roofScopeData: data);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
