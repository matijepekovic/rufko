import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/roof_scope_data.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/simplified_quote_detail_screen.dart';
import '../screens/simplified_quote_screen.dart';
import '../../../customers/presentation/screens/customer_selection_screen.dart';

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
      _showCustomerSelection(roofScopeData);
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

  void _showCustomerSelection(RoofScopeData? data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerSelectionScreen(
          onCustomerSelected: (customer) {
            Navigator.pop(context); // Close customer selection
            navigateToCreateQuote(customer: customer, roofScopeData: data);
          },
        ),
      ),
    );
  }
}
