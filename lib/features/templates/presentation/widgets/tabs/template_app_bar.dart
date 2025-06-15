import 'package:flutter/material.dart';
import '../../../../../app/theme/rufko_theme.dart';

class TemplateAppBar extends StatelessWidget {
  final TabController controller;
  final VoidCallback onSettings;

  const TemplateAppBar({
    super.key,
    required this.controller,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: const FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RufkoTheme.primaryColor,
                RufkoTheme.primaryDarkColor,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettings,
          tooltip: 'Template Settings',
          color: Colors.white,
        ),
      ],
      bottom: TabBar(
        controller: controller,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        labelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
        unselectedLabelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
        tabs: const [
          Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF'),
          Tab(icon: Icon(Icons.sms), text: 'Messages'),
          Tab(icon: Icon(Icons.email), text: 'Emails'),
          Tab(icon: Icon(Icons.data_object), text: 'Fields'),
        ],
      ),
    );
  }
}
