import 'package:flutter/material.dart';
import '../../app/theme/rufko_theme.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;
  final bool isScrollable;

  const CustomTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RufkoTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: RufkoTheme.strokeColor,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: RufkoTheme.primaryColor,
              width: 2,
            ),
          ),
        ),
        indicatorColor: Colors.transparent, // Hide default indicator
        labelColor: RufkoTheme.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: tabs.map((tabText) => Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(tabText),
          ),
        )).toList(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}