// lib/screens/layouts/home_layout_small.dart

import 'package:flutter/material.dart';

class HomeSmallLayout extends StatelessWidget {
  final int selectedIndex;
  final List<BottomNavigationBarItem> navItems;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<int> onPageChanged;
  final PageController pageController;
  final List<Widget> pages;
  final Widget? floatingActionButton;

  const HomeSmallLayout({
    super.key,
    required this.selectedIndex,
    required this.navItems,
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: onItemSelected,
          items: navItems,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
