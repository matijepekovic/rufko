import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/templates/pdf_templates_tab.dart';
import '../widgets/templates/message_templates_tab.dart';
import '../widgets/templates/email_templates_tab.dart';
import '../widgets/templates/custom_app_data_tab.dart';
import '../theme/rufko_theme.dart';
import 'template_editor_screen.dart';
import 'message_template_editor_screen.dart';
import 'email_template_editor_screen.dart';
import 'category_management_screen.dart';
import '../widgets/add_custom_field_dialog.dart';
import '../models/custom_app_data.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

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
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverAppBar()],
        body: TabBarView(
          controller: _tabController,
          children: const [
            PdfTemplatesTab(),
            MessageTemplatesTab(),
            EmailTemplatesTab(),
            CustomAppDataScreen(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showTemplateSettings,
          tooltip: 'Template Settings',
          color: Colors.white,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF Templates'),
          Tab(icon: Icon(Icons.sms), text: 'Message Templates'),
          Tab(icon: Icon(Icons.email), text: 'Email Templates'),
          Tab(icon: Icon(Icons.data_object), text: 'Custom Fields'),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton.extended(
          heroTag: 'pdf_fab',
          onPressed: _createNewPDFTemplate,
          icon: const Icon(Icons.add),
          label: const Text('New PDF Template'),
          backgroundColor: RufkoTheme.primaryColor,
        );
      case 1:
        return FloatingActionButton.extended(
          heroTag: 'message_fab',
          onPressed: _createNewTextTemplate,
          icon: const Icon(Icons.add),
          label: const Text('New Message Template'),
          backgroundColor: Colors.green,
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: 'email_fab',
          onPressed: _createNewEmailTemplate,
          icon: const Icon(Icons.add),
          label: const Text('New Email Template'),
          backgroundColor: Colors.orange,
        );
      default:
        return FloatingActionButton.extended(
          heroTag: 'custom_fab',
          onPressed: _createNewCustomField,
          icon: const Icon(Icons.add),
          label: const Text('New Custom Field'),
          backgroundColor: RufkoTheme.primaryColor,
        );
    }
  }

  Future<void> _createNewPDFTemplate() async {
    final selectedCategory = await _showCategorySelectionDialog();
    if (selectedCategory != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TemplateEditorScreen(preselectedCategory: selectedCategory),
        ),
      );
    }
  }

  Future<String?> _showCategorySelectionDialog() async {
    final appState = context.read<AppStateProvider>();
    final allCategories = await appState.getAllTemplateCategories();
    final pdfCategories = allCategories['pdf_templates'] ?? [];

    if (!mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Template Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('No Category'),
                subtitle: const Text('Create template without a specific category'),
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(),
              ...pdfCategories.map<Widget>((category) {
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(category['name'] as String),
                  onTap: () => Navigator.pop(context, category['key'] as String),
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.blue),
                title: const Text('Create New Category'),
                subtitle: const Text('Add a new template category'),
                onTap: () {
                  Navigator.pop(context);
                  _showTemplateSettings();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _createNewTextTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessageTemplateEditorScreen(),
      ),
    );
  }

  void _createNewEmailTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailTemplateEditorScreen(),
      ),
    );
  }

  void _createNewCustomField() {
    final appState = context.read<AppStateProvider>();
    final allCategories = appState.templateCategories;
    final customFieldCategories =
        allCategories.where((c) => c.templateType == 'custom_fields').toList();

    final availableCategories = <String>['custom'];
    final categoryNames = <String, String>{'custom': 'Custom Fields'};
    for (final category in customFieldCategories) {
      availableCategories.add(category.key);
      categoryNames[category.key] = category.name;
    }

    showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddCustomFieldDialog(
        categories: availableCategories,
        categoryNames: categoryNames,
      ),
    ).then((returnedValue) {
      if (returnedValue != null && mounted) {
        appState.addCustomAppDataField(returnedValue).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added custom field: ${returnedValue.displayName}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }).catchError((error) {
          _showErrorSnackBar('Error adding field: $error');
        });
      }
    }).catchError((error) {
      _showErrorSnackBar('Error: $error');
    });
  }

  void _showTemplateSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

