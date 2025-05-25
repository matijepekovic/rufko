// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
// path_provider is not directly used here but Hive might need it implicitly.
// import 'package:path_provider/path_provider.dart'; // Keep if Hive complains later
import 'package:path_provider/path_provider.dart';
// Your Core Models
import 'models/customer.dart';
import 'models/product.dart';
import 'models/quote.dart'; // Contains QuoteItem
import 'models/roof_scope_data.dart';
import 'models/project_media.dart';
import 'models/app_settings.dart';
import 'models/simplified_quote.dart'; // NEW primary quote model

// Your Services and Providers
import 'providers/app_state_provider.dart';
import 'services/database_service.dart';

// Your Screens
import 'screens/home_screen.dart'; // Or your initial screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  // Register Hive adapters
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(QuoteItemAdapter());
  // Hive.registerAdapter(QuoteAdapter()); // Keep ONLY if you kept the old Quote class in quote.dart, otherwise REMOVE
  Hive.registerAdapter(RoofScopeDataAdapter());
  Hive.registerAdapter(ProjectMediaAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  // NEW Adapters for the Simplified Quote System
  Hive.registerAdapter(QuoteLevelAdapter());
  Hive.registerAdapter(SimplifiedMultiLevelQuoteAdapter());

  // REMOVED Adapters for the old multi_level_quote.dart
  // Hive.registerAdapter(LevelQuoteAdapter()); // This was for the old system's LevelQuote
  // Hive.registerAdapter(MultiLevelQuoteAdapter()); // This was for the old system's MultiLevelQuote

  // Initialize database service (this will open the boxes)
  await DatabaseService.instance.init();

  // It's generally good practice to initialize AppStateProvider *after*
  // critical services like DatabaseService are ready.
  final appStateProvider = AppStateProvider();
  await appStateProvider.initializeApp(); // Load initial data

  runApp(
    ChangeNotifierProvider.value(
      value: appStateProvider, // Use .value constructor when instance is already created
      child: const RufkoApp(),
    ),
  );
}

class RufkoApp extends StatelessWidget {
  const RufkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No need for MultiProvider here if AppStateProvider is the only root provider
    return MaterialApp(
      title: 'Rufko - Roofing Estimator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue, // You can use colorScheme.fromSeed for modern themes
        // colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true, // Recommended for new apps
        primaryColor: const Color(0xFF1565C0), // Still useful for some direct styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0), // Consider using theme.colorScheme.primary
          foregroundColor: Colors.white,      // Consider using theme.colorScheme.onPrimary
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0), // theme.colorScheme.primary
            foregroundColor: Colors.white,            // theme.colorScheme.onPrimary
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2, // Slightly reduced elevation for a cleaner look
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Adjusted margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            // borderSide: BorderSide.none, // For a flatter look if desired
          ),
          // filled: true, // If you want filled text fields
          // fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Adjusted padding
        ),
        // Add other theme properties as needed
      ),
      home: const HomeScreen(), // Make sure HomeScreen exists and is your intended entry point
    );
  }
}