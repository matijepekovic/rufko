import 'package:flutter/material.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../controllers/category_data_controller.dart';
import '../controllers/category_dialog_manager.dart';
import '../controllers/category_operations_controller.dart';
import '../controllers/category_ui_builder.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CategoryDataController _dataController;
  late CategoryOperationsController _opsController;
  late CategoryDialogManager _dialogManager;
  late CategoryUIBuilder _uiBuilder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dataController = CategoryDataController(context);
    _opsController = CategoryOperationsController(context, _dataController);
    _dialogManager = CategoryDialogManager(context, _opsController);
    _uiBuilder = CategoryUIBuilder(context, _dataController, _dialogManager);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Category Management'),
            backgroundColor: RufkoTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              isScrollable: false,
              labelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
              unselectedLabelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
              padding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF'),
                Tab(icon: Icon(Icons.sms), text: 'Messages'),
                Tab(icon: Icon(Icons.email), text: 'Emails'),
                Tab(icon: Icon(Icons.data_object), text: 'Fields'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _uiBuilder.buildCategoryTab('PDF', isPhone),
              _uiBuilder.buildCategoryTab('Message Templates', isPhone),
              _uiBuilder.buildCategoryTab('Email Templates', isPhone),
              _uiBuilder.buildCategoryTab('Fields', isPhone),
            ],
          ),
        );
      },
    );
  }
}
