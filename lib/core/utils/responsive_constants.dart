import 'package:flutter/material.dart';

/// Responsive design constants and utilities for the calculator interface
class ResponsiveConstants {
  ResponsiveConstants._();
  
  // Screen size breakpoints
  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 1200;
  static const double desktopMinWidth = 1200;
  
  // Calculator modal height percentages
  static const double mobilePortraitHeight = 0.75;
  static const double mobileLandscapeHeight = 0.90;
  static const double tabletPortraitHeight = 0.60;
  static const double tabletLandscapeHeight = 0.70;
  static const double desktopFixedHeight = 600.0;
  static const double minimumModalHeight = 350.0; // Reasonable minimum for calculator content
  
  // Component heights
  static const double mobileExpressionBarHeight = 45.0;
  static const double tabletExpressionBarHeight = 50.0;
  static const double desktopExpressionBarHeight = 55.0;
  
  static const double mobileQuickChipsHeight = 45.0;
  static const double tabletQuickChipsHeight = 50.0;
  static const double desktopQuickChipsHeight = 55.0;
  
  static const double mobileKeyHeight = 48.0;
  static const double tabletKeyHeight = 56.0;
  static const double desktopKeyHeight = 64.0;
  
  // Spacing values
  static const double mobileKeySpacing = 2.0;
  static const double tabletKeySpacing = 4.0;
  static const double desktopKeySpacing = 6.0;
  
  static const double mobileContentPadding = 4.0;
  static const double tabletContentPadding = 6.0;
  static const double desktopContentPadding = 8.0;
}

/// Utility extension for responsive design calculations
extension ResponsiveUtils on BuildContext {
  
  /// Screen size classifications
  bool get isPhone => MediaQuery.of(this).size.width < ResponsiveConstants.phoneMaxWidth;
  bool get isTablet => MediaQuery.of(this).size.width >= ResponsiveConstants.phoneMaxWidth && 
                      MediaQuery.of(this).size.width < ResponsiveConstants.tabletMaxWidth;
  bool get isDesktop => MediaQuery.of(this).size.width >= ResponsiveConstants.desktopMinWidth;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  
  /// Get responsive calculator modal height based on content
  double get calculatorModalHeight {
    final screenHeight = MediaQuery.of(this).size.height;
    
    // Calculate content-based height
    final dragHandleHeight = 20.0; // drag handle + margins
    final expressionBarHeight = this.expressionBarHeight;
    final quickChipsHeight = this.quickChipsHeight;
    final keypadHeight = calculatorKeyHeight * 4; // 4 rows
    final keypadSpacing = keySpacing * 3; // 3 gaps between rows
    final contentSpacing = (isPhone ? 4 : 6) * 3; // spacing between sections
    final bottomPadding = isPhone ? 12.0 : 16.0; // Prevent overflow
    
    final contentHeight = dragHandleHeight + 
                         expressionBarHeight + 
                         quickChipsHeight + 
                         keypadHeight + 
                         keypadSpacing + 
                         contentSpacing +
                         bottomPadding;
    
    // Set maximum height based on screen size to prevent overflow
    double maxHeight;
    if (isDesktop) {
      maxHeight = ResponsiveConstants.desktopFixedHeight;
    } else if (isPhone) {
      maxHeight = screenHeight * (isLandscape ? 0.90 : 0.75);
    } else {
      maxHeight = screenHeight * (isLandscape ? 0.70 : 0.60);
    }
    
    // Use the smaller of content height or max height
    final finalHeight = contentHeight < maxHeight ? contentHeight : maxHeight;
    
    // Ensure minimum usable height
    return finalHeight < ResponsiveConstants.minimumModalHeight 
        ? ResponsiveConstants.minimumModalHeight 
        : finalHeight;
  }
  
  /// Get responsive expression bar height
  double get expressionBarHeight {
    if (isDesktop) return ResponsiveConstants.desktopExpressionBarHeight;
    if (isTablet) return ResponsiveConstants.tabletExpressionBarHeight;
    return ResponsiveConstants.mobileExpressionBarHeight;
  }
  
  /// Get responsive quick chips height
  double get quickChipsHeight {
    if (isDesktop) return ResponsiveConstants.desktopQuickChipsHeight;
    if (isTablet) return ResponsiveConstants.tabletQuickChipsHeight;
    return ResponsiveConstants.mobileQuickChipsHeight;
  }
  
  /// Get responsive calculator key height
  double get calculatorKeyHeight {
    if (isDesktop) return ResponsiveConstants.desktopKeyHeight;
    if (isTablet) return ResponsiveConstants.tabletKeyHeight;
    return ResponsiveConstants.mobileKeyHeight;
  }
  
  /// Get responsive key spacing
  double get keySpacing {
    if (isDesktop) return ResponsiveConstants.desktopKeySpacing;
    if (isTablet) return ResponsiveConstants.tabletKeySpacing;
    return ResponsiveConstants.mobileKeySpacing;
  }
  
  /// Get responsive content padding
  double get contentPadding {
    if (isDesktop) return ResponsiveConstants.desktopContentPadding;
    if (isTablet) return ResponsiveConstants.tabletContentPadding;
    return ResponsiveConstants.mobileContentPadding;
  }
  
  /// Get responsive done button width
  double get doneButtonWidth {
    if (isLandscape && isPhone) return 60.0; // Narrower in landscape
    if (isDesktop) return 100.0;
    return 80.0;
  }
}