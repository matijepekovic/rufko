import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'core/services/external/tax_service.dart';
// Core Models now use SQLite
// Your Services and Providers
import 'data/providers/state/app_state_provider.dart';
import 'data/providers/customer_provider.dart';
import 'data/providers/product_provider.dart';
import 'data/providers/quote_provider.dart';
import 'data/providers/template_provider.dart';
import 'core/services/database/database_service.dart';
import 'core/services/database/calculator_database_service.dart';
import 'app/theme/rufko_theme.dart';
// Your Screens
import 'features/dashboard/presentation/screens/home_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Hive completely removed - using SQLite only
  await DatabaseService.instance.init();
  await TaxService.initializeTaxDatabase();
  final customerProvider = CustomerProvider();
  final productProvider = ProductProvider();
  final quoteProvider = QuoteProvider();
  final templateProvider = TemplateProvider();
  final appStateProvider = AppStateProvider();

  await Future.wait([
    customerProvider.loadCustomers(),
    productProvider.loadProducts(),
    quoteProvider.loadQuotes(),
    templateProvider.loadTemplates(),
    appStateProvider.initializeApp(),
  ]);

  // Initialize calculator database separately to handle failures gracefully
  try {
    await CalculatorDatabaseService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Calculator features not available: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appStateProvider),
        ChangeNotifierProvider.value(value: customerProvider),
        ChangeNotifierProvider.value(value: productProvider),
        ChangeNotifierProvider.value(value: quoteProvider),
        ChangeNotifierProvider.value(value: templateProvider),
      ],
      child: const RufkoApp(),
    ),
  );
}

class RufkoApp extends StatelessWidget {
  const RufkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rufko - Professional Roofing Estimator',
      debugShowCheckedModeBanner: false,
      theme: RufkoTheme.phoneTheme,
      home: const HomeScreen(),
    );
  }
}