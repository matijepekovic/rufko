import 'package:flutter/material.dart';

/// Central place for Rufko UI settings.
/// In the future, more variations (desktop, phone) can be added here.
mixin RufkoTheme {
  // Mockup Color Scheme
  static const Color primaryColor = Color(0xFF1E88E5);           // #1E88E5 Material Blue
  static const Color primaryDarkColor = Color(0xFF1565C0);       // Darker variant
  static const Color backgroundColor = Color(0xFFFFFFFF);        // #FFFFFF
  static const Color surfaceColor = Color(0xFFFFFFFF);          // #FFFFFF  
  static const Color strokeColor = Color(0xFFE0E0E0);           // #E0E0E0 Border color
  static const Color cardBackgroundColor = Color(0xFFF7F8FA);   // #F7F8FA Grey card background

  // Status Colors (for future kanban/job status)
  static const Color statusBlue = Color(0xFF246BFD);            // #246BFD Board blue
  static const Color statusGreen = Color(0xFF00A876);           // #00A876 Board green  
  static const Color statusPurple = Color(0xFF725BFF);          // #725BFF Board purple
  static const Color statusYellow = Color(0xFFFFF4D0);          // #FFF4D0 Idle yellow
  static const Color statusOrange = Color(0xFFFFE3B0);          // #FFE3B0 Risk orange
  static const Color statusRed = Color(0xFFFFD1CF);             // #FFD1CF Hot red
  
  // Button sizing standards
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightSmall = 32.0;
  
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets buttonPaddingMedium = EdgeInsets.symmetric(horizontal: 20, vertical: 10);
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(horizontal: 16, vertical: 6);
  
  // Standard border radius
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(8));

  static ThemeData get phoneTheme => _baseTheme();
  static ThemeData get desktopTheme => _baseTheme();

  static ThemeData _baseTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: buttonPaddingMedium,
          minimumSize: const Size(88, buttonHeightMedium),
          shape: const RoundedRectangleBorder(
            borderRadius: buttonBorderRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: buttonPaddingMedium,
          minimumSize: const Size(88, buttonHeightMedium),
          side: const BorderSide(color: primaryColor, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: buttonBorderRadius,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: buttonPaddingMedium,
          minimumSize: const Size(88, buttonHeightMedium),
          shape: const RoundedRectangleBorder(
            borderRadius: buttonBorderRadius,
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
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
