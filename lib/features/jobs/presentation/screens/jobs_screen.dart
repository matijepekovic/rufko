import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_header.dart';
import '../../../../core/widgets/custom_tab_bar.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: 'Jobs',
        leadingIcon: Icons.calendar_today_rounded,
        bottom: CustomTabBar(
          controller: _tabController,
          tabs: const ['Active', 'Scheduled', 'Complete', 'Routes', 'Door Knocking'],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text('Active Jobs - TODO: Implement', style: TextStyle(fontSize: 18))),
          const Center(child: Text('Scheduled Jobs - TODO: Implement', style: TextStyle(fontSize: 18))),
          const Center(child: Text('Complete Jobs - TODO: Implement', style: TextStyle(fontSize: 18))),
          const Center(child: Text('Job Routes - TODO: Implement', style: TextStyle(fontSize: 18))),
          const Center(child: Text('Door Knocking - TODO: Implement', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}