// lib/screens/layouts/home_layout_large.dart

import 'package:flutter/material.dart';

class HomeLargeLayout extends StatelessWidget {
  final int selectedIndex;
  // navItems no longer needed with custom navigation
  final ValueChanged<int> onItemSelected;
  final ValueChanged<int> onPageChanged;
  final PageController pageController;
  final List<Widget> pages;
  final Widget? floatingActionButton;

  const HomeLargeLayout({
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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onItemSelected,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: Text('Dash'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.handshake_rounded),
                label: Text('Sales'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_rounded),
                label: Text('Jobs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.archive_rounded),
                label: Text('Vault'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_rounded),
                label: Text('Tools'),
              ),
            ],
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
