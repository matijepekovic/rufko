// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/tax_service.dart';
// Your Core Models
import 'models/customer.dart';
import 'models/product.dart';
import 'models/quote.dart'; // Contains QuoteItem
import 'models/roof_scope_data.dart';
import 'models/project_media.dart';
import 'models/app_settings.dart';
import 'models/simplified_quote.dart';
import 'models/pdf_template.dart'; // Crucial: Import this to get PdfFormFieldTypeAdapter etc.
import 'models/custom_app_data.dart';
import 'models/message_template.dart';
// Your Services and Providers
import 'providers/app_state_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/template_provider.dart';
import 'services/database_service.dart';
import 'models/email_template.dart';
import 'models/inspection_document.dart';
// Your Screens
import 'screens/home_screen.dart';
import 'models/template_category.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductLevelPriceAdapter());
  Hive.registerAdapter(ProductPricingTypeAdapter()); // Your manual adapter for the enum
  Hive.registerAdapter(QuoteItemAdapter());
  Hive.registerAdapter(RoofScopeDataAdapter());
  Hive.registerAdapter(ProjectMediaAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(QuoteDiscountAdapter());
  Hive.registerAdapter(QuoteLevelAdapter());
  Hive.registerAdapter(SimplifiedMultiLevelQuoteAdapter());
  Hive.registerAdapter(CustomAppDataFieldAdapter());
  // PDF Template related adapters
  Hive.registerAdapter(PdfFormFieldTypeAdapter()); // REGISTER THE NEW ENUM ADAPTER
  Hive.registerAdapter(FieldMappingAdapter());     // From pdf_template.g.dart (or will be)
  Hive.registerAdapter(PDFTemplateAdapter());     // From pdf_template.g.dart (or will be)
  Hive.registerAdapter(MessageTemplateAdapter());
  Hive.registerAdapter(EmailTemplateAdapter());
  Hive.registerAdapter(TemplateCategoryAdapter());
  Hive.registerAdapter(InspectionDocumentAdapter());
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        primaryColor: const Color(0xFF1565C0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}