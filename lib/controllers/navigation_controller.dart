import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/simplified_quote.dart';
import '../screens/simplified_quote_screen.dart';
import '../screens/simplified_quote_detail_screen.dart';

class NavigationController {
  NavigationController({required this.context, required this.customer});

  final BuildContext context;
  final Customer customer;

  void navigateToCreateQuoteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteScreen(customer: customer),
      ),
    );
  }

  void navigateToSimplifiedQuoteDetail(SimplifiedMultiLevelQuote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SimplifiedQuoteDetailScreen(quote: quote, customer: customer),
      ),
    );
  }
}
