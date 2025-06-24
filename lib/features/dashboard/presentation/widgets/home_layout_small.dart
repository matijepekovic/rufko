// lib/screens/layouts/home_layout_small.dart

import 'package:flutter/material.dart';
import 'custom_bottom_navigation.dart';

class HomeSmallLayout extends StatelessWidget {
  final int selectedIndex;
  // navItems no longer needed with custom navigation
  final ValueChanged<int> onItemSelected;
  final ValueChanged<int> onPageChanged;
  final PageController pageController;
  final List<Widget> pages;
  final Widget? floatingActionButton;

  const HomeSmallLayout({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.pageController,
    required this.pages,
    required this.onPageChanged,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: selectedIndex,
        onTap: onItemSelected,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
