// lib/screens/templates_screen.dart - CUSTOMER DETAIL STYLE DESIGN

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pdf_template.dart';
import '../providers/app_state_provider.dart';
import 'template_editor_screen.dart';
import '../widgets/templates/custom_app_data_tab.dart';
import '../widgets/templates/pdf_templates_tab.dart';
import '../widgets/templates/message_templates_tab.dart';
import '../widgets/templates/email_templates_tab.dart';
import '../theme/rufko_theme.dart';
import 'message_template_editor_screen.dart';
import 'email_template_editor_screen.dart';
import 'category_management_screen.dart';
import '../models/custom_app_data.dart';
import '../widgets/add_custom_field_dialog.dart';
import '../mixins/selection_mixin.dart';


class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with TickerProviderStateMixin, SelectionMixin {
  late TabController _tabController;
  final SelectionState _pdfSelection = SelectionState();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen for tab changes to exit selection modes
    _tabController.addListener(() {
      if (_pdfSelection.isSelectionMode && _tabController.index != 0) {
        _exitPDFSelectionMode();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // PDF Selection Mode Methods
  void _exitPDFSelectionMode() => exitSelectionMode(_pdfSelection);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_pdfSelection.isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_pdfSelection.isSelectionMode) {
            _exitPDFSelectionMode();
          }
        }
      },
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  _buildModernSliverAppBar(appState),
                ];
              },
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
        },
      ),
    );
  }

  Widget _buildModernSliverAppBar(AppStateProvider appState) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
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
        // Settings only
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
        tabs: [
          Tab(
            icon: Icon(_pdfSelection.isSelectionMode && _tabController.index == 0
                ? Icons.checklist
                : Icons.picture_as_pdf),
            text: _pdfSelection.isSelectionMode && _tabController.index == 0
                ? '${_pdfSelection.selectedIds.length} selected'
                : 'PDF Templates',
          ),
          const Tab(icon: Icon(Icons.sms), text: 'Message Templates'),
          const Tab(icon: Icon(Icons.email), text: 'Email Templates'),
          const Tab(icon: Icon(Icons.data_object), text: 'Custom Fields'),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final currentTab = _tabController.index;



        // Regular FABs for each tab
        switch (currentTab) {
          case 0: // PDF Templates tab
            return FloatingActionButton.extended(
              heroTag: "pdf_fab",
              onPressed: _createNewPDFTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New PDF Template'),
              backgroundColor: RufkoTheme.primaryColor,
            );
          case 1: // Message Templates tab
            return FloatingActionButton.extended(
              heroTag: "message_fab",
              onPressed: _createNewTextTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New Message Template'),
              backgroundColor: Colors.green,
            );
          case 2: // Email Templates tab
            return FloatingActionButton.extended(
              heroTag: "email_fab",
              onPressed: _createNewEmailTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New Email Template'),
              backgroundColor: Colors.orange,
            );
          case 3: // Custom Fields tab
            return FloatingActionButton.extended(
              heroTag: "custom_fields_fab",
              onPressed: _createNewCustomField,
              icon: const Icon(Icons.add),
              label: const Text('New Custom Field'),
              backgroundColor: RufkoTheme.primaryColor,
            );
          default:
            return FloatingActionButton.extended(
              heroTag: "default_fab",
              onPressed: _createNewPDFTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New Template'),
              backgroundColor: RufkoTheme.primaryColor,
            );
        }
      },
    );
  }


  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ACTION HANDLERS

  void _createNewPDFTemplate() async {
    // Show category selection dialog first
    final selectedCategory = await _showCategorySelectionDialog();

    if (selectedCategory != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateEditorScreen(
            preselectedCategory: selectedCategory,
          ),
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Template Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "No Category" option
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('No Category'),
                subtitle: const Text('Create template without a specific category'),
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(),
              // User-defined categories
              ...pdfCategories.map<Widget>((category) {
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(category['name'] as String),
                  onTap: () => Navigator.pop(context, category['key'] as String),
                );
              }),
              const Divider(),
              // Option to create new category
              ListTile(
                leading: const Icon(Icons.add, color: Colors.blue),
                title: const Text('Create New Category'),
                subtitle: const Text('Add a new template category'),
                onTap: () {
                  Navigator.pop(context);
                  _showTemplateSettings(); // This opens category management
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

  // ADD THIS NEW METHOD HERE:
  void _createNewCustomField() {
    // Get the app state provider
    final appState = context.read<AppStateProvider>();

    // Get categories synchronously from already-loaded data
    final allTemplateCategories = appState.templateCategories;
    final customFieldCategories = allTemplateCategories
        .where((cat) => cat.templateType == 'custom_fields')
        .toList();

    final availableCategories = <String>['custom'];
    final categoryNames = <String, String>{'custom': 'Custom Fields'};

    // Add loaded categories
    for (final category in customFieldCategories) {
      availableCategories.add(category.key);
      categoryNames[category.key] = category.name;
    }



    showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AddCustomFieldDialog(
          categories: availableCategories,
          categoryNames: categoryNames,
        );
      },
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding field: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

