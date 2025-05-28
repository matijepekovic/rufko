// lib/main.dart - UPDATED WITH NEW ADAPTERS + ENUM ADAPTER

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Your Core Models
import 'models/customer.dart';
import 'models/product.dart';
import 'models/quote.dart'; // Contains QuoteItem
import 'models/roof_scope_data.dart';
import 'models/project_media.dart';
import 'models/app_settings.dart';
import 'models/simplified_quote.dart'; // NEW primary quote model with discounts
import 'models/pdf_template.dart';
// Your Services and Providers
import 'providers/app_state_provider.dart';
import 'services/database_service.dart';

// Your Screens
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters - UPDATED WITH NEW ADAPTERS
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductLevelPriceAdapter()); // NEW - Enhanced level pricing
  Hive.registerAdapter(ProductPricingTypeAdapter()); // NEW - Enum adapter
  Hive.registerAdapter(QuoteItemAdapter());
  Hive.registerAdapter(RoofScopeDataAdapter());
  Hive.registerAdapter(ProjectMediaAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(FieldMappingAdapter()); // NEW - typeId: 20
  Hive.registerAdapter(PDFTemplateAdapter());  // NEW - typeId: 21
  // NEW Adapters for the Enhanced Quote System with Discounts
  Hive.registerAdapter(QuoteDiscountAdapter()); // NEW - Discount/Voucher support
  Hive.registerAdapter(QuoteLevelAdapter());
  Hive.registerAdapter(SimplifiedMultiLevelQuoteAdapter());

  // Initialize database service (this will open the boxes)
  await DatabaseService.instance.init();

  // Initialize AppStateProvider with data loading
  final appStateProvider = AppStateProvider();
  await appStateProvider.initializeApp();

  runApp(
    ChangeNotifierProvider.value(
      value: appStateProvider,
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
        cardTheme: CardTheme(
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

// Manual Hive Adapter for ProductPricingType enum (since build_runner might not generate it automatically)
class ProductPricingTypeAdapter extends TypeAdapter<ProductPricingType> {
  @override
  final int typeId = 19; // Make sure this is unique

  @override
  ProductPricingType read(BinaryReader reader) {
    final index = reader.readByte();
    return ProductPricingType.values[index];
  }

  @override
  void write(BinaryWriter writer, ProductPricingType obj) {
    writer.writeByte(obj.index);
  }
}