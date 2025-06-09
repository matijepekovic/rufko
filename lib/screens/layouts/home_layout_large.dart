// lib/screens/layouts/home_layout_large.dart

import 'package:flutter/material.dart';

class HomeLargeLayout extends StatelessWidget {
  final int selectedIndex;
  final List<BottomNavigationBarItem> navItems;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<int> onPageChanged;
  final PageController pageController;
  final List<Widget> pages;
  final Widget? floatingActionButton;

  const HomeLargeLayout({
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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onItemSelected,
            labelType: NavigationRailLabelType.all,
            destinations: navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: item.icon,
                    label: Text(item.label ?? ''),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: onPageChanged,
              children: pages,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
