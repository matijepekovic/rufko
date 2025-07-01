import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_header.dart';
import '../../../../core/widgets/custom_tab_bar.dart';
import '../widgets/tabs/job_list_tab.dart';
import '../widgets/tabs/job_calendar_tab.dart';
import 'job_form_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
          tabs: const ['List', 'Calendar', 'Routes', 'Doors'],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          JobListTab(),
          JobCalendarTab(),
          Center(child: Text('Job Routes - TODO: Implement', style: TextStyle(fontSize: 18))),
          Center(child: Text('Door Management - TODO: Implement', style: TextStyle(fontSize: 18))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewJob,
        tooltip: 'Create New Job',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNewJob() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const JobFormScreen(),
        fullscreenDialog: true,
      ),
    );
    
    if (result == true) {
      // Job was created successfully, refresh the current tab
      setState(() {});
    }
  }
}