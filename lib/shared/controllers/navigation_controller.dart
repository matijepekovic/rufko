import 'package:flutter/material.dart';

import '../../data/models/business/customer.dart';
import '../../data/models/business/simplified_quote.dart';
import '../../features/quotes/presentation/screens/simplified_quote_screen.dart';
import '../../features/quotes/presentation/screens/simplified_quote_detail_screen.dart';

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
