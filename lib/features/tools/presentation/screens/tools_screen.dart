import 'package:flutter/material.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'tools_list_screen.dart';
import '../../../../core/widgets/custom_header.dart';
import '../../../../core/widgets/custom_tab_bar.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Tools',
        leadingIcon: Icons.settings_rounded,
        bottom: CustomTabBar(
          controller: _tabController,
          tabs: const ['Tools', 'Settings'],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ToolsListScreen(),
          const SettingsScreen(),
        ],
      ),
    );
  }
}