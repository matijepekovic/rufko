import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class DashboardDataController {
  DashboardDataController(this.context);

  final BuildContext context;

  AppStateProvider get appState => context.read<AppStateProvider>();

  Future<void> refreshDashboard() => appState.loadAllData();

  bool get isLoading => appState.isLoading;
  String get loadingMessage => appState.loadingMessage;

  Map<String, dynamic> getDashboardStats() => appState.getDashboardStats();

  List<Customer> getRecentCustomers() {
    final customers = [...appState.customers];
    customers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return customers;
  }

  List<SimplifiedMultiLevelQuote> getRecentQuotes() {
    final quotes = [...appState.simplifiedQuotes];
    quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return quotes;
  }

  List<SimplifiedMultiLevelQuote> quotesForCustomer(String customerId) {
    return appState.getSimplifiedQuotesForCustomer(customerId);
  }
}
