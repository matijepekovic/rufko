import 'package:flutter/material.dart';

class DashboardNavigationController {
  DashboardNavigationController({required this.onIndexChanged});

  final ValueChanged<int> onIndexChanged;

  int selectedIndex = 0;
  final PageController pageController = PageController();

  void dispose() {
    pageController.dispose();
  }

  void onNavItemTapped(int index) {
    selectedIndex = index;
    onIndexChanged(index);
    pageController.jumpToPage(index);
  }

  void onPageChanged(int index) {
    selectedIndex = index;
    onIndexChanged(index);
  }

  void navigateToTab(int index) {
    selectedIndex = index;
    onIndexChanged(index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
