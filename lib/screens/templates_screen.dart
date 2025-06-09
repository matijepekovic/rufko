// lib/screens/templates_screen.dart - UPDATED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'template_editor_screen.dart';
import '../widgets/templates/custom_app_data_tab.dart';
import '../widgets/templates/pdf_templates_tab.dart';
import '../widgets/templates/message_templates_tab.dart';
import '../widgets/templates/email_templates_tab.dart';
import '../theme/rufko_theme.dart';
import '../widgets/templates/dialgos/message_template_editor.dart';
import '../widgets/templates/dialgos/email_template_editor.dart';
import 'category_management_screen.dart';
import '../models/custom_app_data.dart';
import '../widgets/templates/dialgos/add_custom_field_dialog.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with TickerProviderStateMixin {
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
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth < 600;

            return Scaffold(
              backgroundColor: Colors.grey[50],
              body: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    _buildModernSliverAppBar(appState, isPhone),
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
        );
      },
    );
  }

  Widget _buildModernSliverAppBar(AppStateProvider appState, bool isPhone) {
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
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final currentTab = _tabController.index;

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

  // Replace the _showCategorySelectionDialog method in templates_screen.dart with this:

  Future<String?> _showCategorySelectionDialog() async {
    final appState = context.read<AppStateProvider>();
    final allCategories = await appState.getAllTemplateCategories();
    final pdfCategories = allCategories['pdf_templates'] ?? [];

    if (!mounted) return null;

    // If no categories exist, go directly to create one
    if (pdfCategories.isEmpty) {
      return _createNewCategoryAndReturn();
    }

    String? selectedCategory = pdfCategories.first['key'] as String;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header - matching add_custom_field_dialog style
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                      decoration: const BoxDecoration(
                        color: RufkoTheme.primaryColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Select Category',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Content - Categories List
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose a category for your new PDF template:',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),

                            // Categories as radio buttons - compact style
                            ...pdfCategories.map<Widget>((category) {
                              final categoryKey = category['key'] as String;
                              final categoryName = category['name'] as String;
                              final isSelected = selectedCategory == categoryKey;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? RufkoTheme.primaryColor : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: RadioListTile<String>(
                                  value: categoryKey,
                                  groupValue: selectedCategory,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  },
                                  title: Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  secondary: Icon(
                                    Icons.description,
                                    color: isSelected ? RufkoTheme.primaryColor : Colors.grey,
                                    size: 20,
                                  ),
                                  activeColor: RufkoTheme.primaryColor,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: 16),

                            // Create new category option - styled like add custom field
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.add, color: RufkoTheme.primaryColor, size: 20),
                                title: const Text(
                                  'Create New Category',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                subtitle: const Text(
                                  'Add a new template category',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final newCategory = await _createNewCategoryAndReturn();
                                  if (newCategory != null && mounted) {
                                    // Restart the process with the new category
                                    final finalCategory = await _showCategorySelectionDialog();
                                    if (finalCategory != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TemplateEditorScreen(
                                            preselectedCategory: finalCategory,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions - matching add_custom_field_dialog style
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedCategory != null
                                ? () => Navigator.of(context).pop(selectedCategory)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RufkoTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Also add this new method to templates_screen.dart:
  Future<String?> _createNewCategoryAndReturn() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - matching style
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  decoration: const BoxDecoration(
                    color: RufkoTheme.primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create Category',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter a name for your new PDF template category:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g., Residential, Commercial, Estimates',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final categoryName = controller.text.trim();
                          if (categoryName.isNotEmpty) {
                            try {
                              final appState = context.read<AppStateProvider>();
                              final categoryKey = categoryName.toLowerCase().replaceAll(' ', '_');

                              await appState.addTemplateCategory('pdf_templates', categoryKey, categoryName);

                              if (mounted) {
                                Navigator.of(context).pop(categoryKey);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Created category: $categoryName'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating category: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RufkoTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  void _createNewCustomField() async {
    // Use the static method from AddCustomFieldDialog which handles everything properly
    try {
      final result = await AddCustomFieldDialog.show(context);

      if (result != null && mounted) {
        final appState = context.read<AppStateProvider>();

        await appState.addCustomAppDataField(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added custom field: ${result.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      _showErrorSnackBar('Error adding field: $error');
    }
  }

  void _showTemplateSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }
}