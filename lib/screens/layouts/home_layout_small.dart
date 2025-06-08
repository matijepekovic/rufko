// lib/screens/layouts/home_layout_small.dart

import 'package:flutter/material.dart';

class HomeSmallLayout extends StatelessWidget {
  final int selectedIndex;
  final List<BottomNavigationBarItem> navItems;
  final ValueChanged<int> onItemSelected;
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
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: PageView(
        controller: pageController,
        onPageChanged: onItemSelected,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
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
