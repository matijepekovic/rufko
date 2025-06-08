import 'package:flutter/material.dart';

/// Central place for Rufko UI settings.
/// In the future, more variations (desktop, phone) can be added here.
mixin RufkoTheme {
  static const Color primaryColor = Color(0xFF2E86AB);
  static const Color primaryDarkColor = Color(0xFF1B5E7F);

  static ThemeData get phoneTheme => _baseTheme();
  static ThemeData get desktopTheme => _baseTheme();

  static ThemeData _baseTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      useMaterial3: true,
      primaryColor: primaryColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
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
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: primaryColor),
        selectedLabelTextStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
        unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
