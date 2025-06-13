// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/external/tax_service.dart';
// Your Core Models
import 'data/models/business/customer.dart';
import 'data/models/business/product.dart';
import 'data/models/business/quote.dart'; // Contains QuoteItem
import 'data/models/business/roof_scope_data.dart';
import 'data/models/media/project_media.dart';
import 'data/models/settings/app_settings.dart';
import 'data/models/business/simplified_quote.dart';
import 'data/models/templates/pdf_template.dart'; // Crucial: Import this to get PdfFormFieldTypeAdapter etc.
import 'data/models/settings/custom_app_data.dart';
import 'data/models/templates/message_template.dart';
// Your Services and Providers
import 'data/providers/state/app_state_provider.dart';
import 'data/providers/customer_provider.dart';
import 'data/providers/product_provider.dart';
import 'data/providers/quote_provider.dart';
import 'data/providers/template_provider.dart';
import 'core/services/database/database_service.dart';
import 'data/models/templates/email_template.dart';
import 'data/models/media/inspection_document.dart';
import 'app/theme/rufko_theme.dart';
// Your Screens
import 'features/dashboard/presentation/screens/home_screen.dart';
import 'data/models/templates/template_category.dart';
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
      theme: RufkoTheme.phoneTheme,
      home: const HomeScreen(),
    );
  }
}