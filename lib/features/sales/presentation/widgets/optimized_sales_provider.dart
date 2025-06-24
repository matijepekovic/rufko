import 'package:flutter/material.dart';

/// Optimized provider for caching responsive data to avoid repeated MediaQuery lookups
class OptimizedSalesProvider extends InheritedWidget {
  final MediaQueryData mediaQuery;
  final ThemeData theme;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final double screenWidth;
  final double screenHeight;
  
  const OptimizedSalesProvider({
    super.key,
    required this.mediaQuery,
    required this.theme,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.screenWidth,
    required this.screenHeight,
    required super.child,
  });

  factory OptimizedSalesProvider.create({
    required BuildContext context,
    required Widget child,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final width = mediaQuery.size.width;
    
    return OptimizedSalesProvider(
      mediaQuery: mediaQuery,
      theme: theme,
      isMobile: width < 600,
      isTablet: width >= 600 && width < 900,
      isDesktop: width >= 900,
      screenWidth: width,
      screenHeight: mediaQuery.size.height,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(OptimizedSalesProvider oldWidget) {
    return mediaQuery.size != oldWidget.mediaQuery.size ||
           theme != oldWidget.theme;
  }

  static OptimizedSalesProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OptimizedSalesProvider>();
  }
}

/// Widget that provides optimized responsive data
class OptimizedResponsiveWidget extends StatelessWidget {
  final Widget child;
  
  const OptimizedResponsiveWidget({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return OptimizedSalesProvider.create(
      context: context,
      child: child,
    );
  }
}

/// Mixin for accessing cached responsive data
mixin OptimizedResponsiveMixin {
  OptimizedSalesProvider? _getProvider(BuildContext context) {
    return OptimizedSalesProvider.of(context);
  }
  
  bool isMobileOptimized(BuildContext context) {
    return _getProvider(context)?.isMobile ?? 
           MediaQuery.sizeOf(context).width < 600;
  }
  
  bool isTabletOptimized(BuildContext context) {
    return _getProvider(context)?.isTablet ?? 
           (MediaQuery.sizeOf(context).width >= 600 && 
            MediaQuery.sizeOf(context).width < 900);
  }
  
  bool isDesktopOptimized(BuildContext context) {
    return _getProvider(context)?.isDesktop ?? 
           MediaQuery.sizeOf(context).width >= 900;
  }
  
  double screenWidthOptimized(BuildContext context) {
    return _getProvider(context)?.screenWidth ?? 
           MediaQuery.sizeOf(context).width;
  }
  
  double screenHeightOptimized(BuildContext context) {
    return _getProvider(context)?.screenHeight ?? 
           MediaQuery.sizeOf(context).height;
  }
}

/// Performance-optimized breakpoint checker
class BreakpointBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, String breakpoint, bool isMobile, bool isTablet, bool isDesktop) builder;
  
  const BreakpointBuilder({super.key, required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 900;
        final isDesktop = width >= 900;
        
        String breakpoint;
        if (width < 360) {
          breakpoint = 'xs';
        } else if (width < 600) {
          breakpoint = 'sm';
        } else if (width < 900) {
          breakpoint = 'md';
        } else if (width < 1200) {
          breakpoint = 'lg';
        } else {
          breakpoint = 'xl';
        }
        
        return builder(context, breakpoint, isMobile, isTablet, isDesktop);
      },
    );
  }
}