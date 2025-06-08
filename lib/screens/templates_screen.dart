// lib/screens/templates_screen.dart - CUSTOMER DETAIL STYLE DESIGN

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message_template.dart';
import '../models/pdf_template.dart';
import '../providers/app_state_provider.dart';
import 'template_editor_screen.dart';
import 'pdf_preview_screen.dart';
import '../widgets/templates/custom_app_data_tab.dart';
import '../widgets/templates/pdf_templates_tab.dart';
import '../widgets/templates/message_templates_tab.dart';
import '../widgets/templates/email_templates_tab.dart';
import '../theme/rufko_theme.dart';
import 'message_template_editor_screen.dart';
import 'email_template_editor_screen.dart';
import '../models/email_template.dart';
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
  // Selection controllers for each tab
  final SelectionState _pdfSelection = SelectionState();
  final SelectionState _messageSelection = SelectionState();
  final SelectionState _emailSelection = SelectionState();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen for tab changes to exit selection modes
    _tabController.addListener(() {
      if (_pdfSelection.isSelectionMode && _tabController.index != 0) {
        _exitPDFSelectionMode();
      }
      if (_messageSelection.isSelectionMode && _tabController.index != 1) {
        _exitMessageSelectionMode();
      }
      if (_emailSelection.isSelectionMode && _tabController.index != 2) {
        _exitEmailSelectionMode();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // PDF Selection Mode Methods
  void _enterPDFSelectionMode() => enterSelectionMode(_pdfSelection);

  void _exitPDFSelectionMode() => exitSelectionMode(_pdfSelection);

  void _togglePDFSelection(String templateId) =>
      toggleSelection(_pdfSelection, templateId);


// Message Selection Mode Methods
  void _enterMessageSelectionMode() => enterSelectionMode(_messageSelection);

  void _exitMessageSelectionMode() => exitSelectionMode(_messageSelection);


  void _deleteSelectedMessages() {
    if (_messageSelection.selectedIds.isEmpty) return;
    _showErrorSnackBar(
        'Delete ${_messageSelection.selectedIds.length} message template${_messageSelection.selectedIds.length == 1 ? '' : 's'} - Coming soon!');
    _exitMessageSelectionMode();
  }

// Email Selection Mode Methods
  void _enterEmailSelectionMode() => enterSelectionMode(_emailSelection);

  void _exitEmailSelectionMode() => exitSelectionMode(_emailSelection);


  void _deleteSelectedEmails() {
    if (_emailSelection.selectedIds.isEmpty) return;
    _showErrorSnackBar(
        'Delete ${_emailSelection.selectedIds.length} email template${_emailSelection.selectedIds.length == 1 ? '' : 's'} - Coming soon!');
    _exitEmailSelectionMode();
  }

  void _deleteSelectedPDF() {
    if (_pdfSelection.selectedIds.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Delete ${_pdfSelection.selectedIds.length} template${_pdfSelection.selectedIds.length == 1 ? '' : 's'}'),
        content: Text(_pdfSelection.selectedIds.length == 1
            ? 'Are you sure you want to delete this PDF template?'
            : 'Are you sure you want to delete these ${_pdfSelection.selectedIds.length} PDF templates?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final appState = context.read<AppStateProvider>();

                for (final templateId in _pdfSelection.selectedIds) {
                  await appState.deletePDFTemplate(templateId);
                }

                _exitPDFSelectionMode();

                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        'Deleted ${_pdfSelection.selectedIds.length} template${_pdfSelection.selectedIds.length == 1 ? '' : 's'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                navigator.pop();
                _showErrorSnackBar('Error deleting templates: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_pdfSelection.isSelectionMode &&
          !_messageSelection.isSelectionMode &&
          !_emailSelection.isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_pdfSelection.isSelectionMode) {
            _exitPDFSelectionMode();
          } else if (_messageSelection.isSelectionMode) {
            _exitMessageSelectionMode();
          } else if (_emailSelection.isSelectionMode) {
            _exitEmailSelectionMode();
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
          Tab(
            icon: Icon(_messageSelection.isSelectionMode && _tabController.index == 1
                ? Icons.checklist
                : Icons.sms),
            text: _messageSelection.isSelectionMode && _tabController.index == 1
                ? '${_messageSelection.selectedIds.length} selected'
                : 'Message Templates',
          ),
          Tab(
            icon: Icon(_emailSelection.isSelectionMode && _tabController.index == 2
                ? Icons.checklist
                : Icons.email),
            text: _emailSelection.isSelectionMode && _tabController.index == 2
                ? '${_emailSelection.selectedIds.length} selected'
                : 'Email Templates',
          ),
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

        // PDF tab with selection mode
        if (currentTab == 0 && _pdfSelection.isSelectionMode) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_pdfSelection.selectedIds.isNotEmpty)
                FloatingActionButton(
                  heroTag: "delete_selected_pdf_fab",
                  onPressed: _deleteSelectedPDF,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: "cancel_pdf_selection_fab",
                onPressed: _exitPDFSelectionMode,
                backgroundColor: Colors.grey,
                child: const Icon(Icons.close),
              ),
            ],
          );
        }

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

  void _editPDFTemplate(PDFTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _previewPDFTemplate(PDFTemplate template) async {
    final navigator = Navigator.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating preview...'),
            ],
          ),
        ),
      );

      final appState = context.read<AppStateProvider>();
      final previewPath =
          await appState.generateTemplatePreview(template);

      navigator.pop(); // Close loading dialog

      navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: previewPath,
            suggestedFileName: 'Preview_${template.templateName}.pdf',
            title: 'Template Preview: ${template.templateName}',
            isPreview: true,
          ),
        ),
      );
    } catch (e) {
      navigator.pop(); // Close loading dialog
      _showErrorSnackBar('Error generating preview: $e');
    }
  }

  void _handlePDFTemplateAction(String action, PDFTemplate template) {
    switch (action) {
      case 'toggle_active':
        context.read<AppStateProvider>().togglePDFTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
          ),
        );
        break;

      case 'duplicate':
        _duplicatePDFTemplate(template);
        break;

      case 'delete':
        _showPDFDeleteConfirmation(template);
        break;
    }
  }

  void _showPDFTemplateContextMenu(PDFTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.pop(context);
                _editPDFTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('Preview'),
              onTap: () {
                Navigator.pop(context);
                _previewPDFTemplate(template);
              },
            ),
            ListTile(
              leading: Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(template.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _handlePDFTemplateAction('toggle_active', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _handlePDFTemplateAction('duplicate', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handlePDFTemplateAction('delete', template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _duplicatePDFTemplate(PDFTemplate template) async {
    try {
      final duplicatedTemplate = template.clone();
      duplicatedTemplate.templateName = '${template.templateName} (Copy)';

      await context.read<AppStateProvider>().addPDFTemplate(duplicatedTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error duplicating template: $e');
      }
    }
  }

  void _showPDFDeleteConfirmation(PDFTemplate template) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?\n\n'
          'This action cannot be undone and will also delete the associated PDF file.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();

              try {
                await context
                    .read<AppStateProvider>()
                    .deletePDFTemplate(template.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Template deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorSnackBar('Error deleting template: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

  // Small helper used by template cards
  Widget _buildDetailChip(IconData icon, String text, {bool isSelected = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14, color: isSelected ? Colors.blue.shade600 : Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue.shade600 : Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  // NEW MESSAGE TEMPLATE CARD BUILDERS
  Widget _buildSelectableMessageCard(MessageTemplate template) {
    final isSelected = _messageSelection.selectedIds.contains(template.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 3 : 1.5,
            color: isSelected ? Colors.green.shade50 : null,
            child: InkWell(
              onTap: _messageSelection.isSelectionMode
                  ? () => _toggleMessageSelection(template.id)
                  : () => _editMessageTemplate(template),
              onLongPress: !_messageSelection.isSelectionMode
                  ? () => _showMessageTemplateContextMenu(template)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      )
                    : null,
                child: _buildMessageTemplateCardContent(template, isSelected),
              ),
            ),
          ),
          if (_messageSelection.isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) =>
                      _toggleMessageSelection(template.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageTemplateCard(MessageTemplate template) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editMessageTemplate(template),
        onLongPress: () => _showMessageTemplateContextMenu(template),
        borderRadius: BorderRadius.circular(12),
        child: _buildMessageTemplateCardContent(template, false),
      ),
    );
  }

  Widget _buildMessageTemplateCardContent(
      MessageTemplate template, bool isSelected) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: template.isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sms,
                  color: template.isActive
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.templateName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green.shade800 : null,
                          ),
                    ),
                    if (template.description.isNotEmpty)
                      Text(
                        template.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.green.shade600
                                  : Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: template.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  template.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Template preview
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              template.messageContent.length > 100
                  ? '${template.messageContent.substring(0, 100)}...'
                  : template.messageContent,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Template details
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  Icons.category,
                  'Category: ${template.userCategoryKey ?? 'No Category'}',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.dynamic_form,
                  '${template.placeholders.length} placeholders',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.calendar_today,
                  dateFormat.format(template.updatedAt),
                  isSelected: isSelected,
                ),
              ),
            ],
          ),

          if (!_messageSelection.isSelectionMode) ...[
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editMessageTemplate(template),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendTestMessage(template),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Test'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleMessageTemplateAction(action, template),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            template.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(template.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Message template selection helpers
  void _toggleMessageSelection(String templateId) {
    toggleSelection(_messageSelection, templateId);
  }

  void _editMessageTemplate(MessageTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MessageTemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _sendTestMessage(MessageTemplate template) {
    _showErrorSnackBar('Test message sending coming soon!');
  }

  void _handleMessageTemplateAction(String action, MessageTemplate template) {
    switch (action) {
      case 'toggle_active':
        context
            .read<AppStateProvider>()
            .toggleMessageTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
          ),
        );
        break;

      case 'duplicate':
        _duplicateMessageTemplate(template);
        break;

      case 'delete':
        _showMessageDeleteConfirmation(template);
        break;
    }
  }

  void _showMessageTemplateContextMenu(MessageTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.pop(context);
                _editMessageTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send Test'),
              onTap: () {
                Navigator.pop(context);
                _sendTestMessage(template);
              },
            ),
            ListTile(
              leading: Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(template.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _handleMessageTemplateAction('toggle_active', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _handleMessageTemplateAction('duplicate', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleMessageTemplateAction('delete', template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _duplicateMessageTemplate(MessageTemplate template) async {
    try {
      final duplicatedTemplate = template.copyWith(
        templateName: '${template.templateName} (Copy)',
        updatedAt: DateTime.now(),
      );

      // Create a new template (copyWith keeps the same ID, but we need a new one)
      final newTemplate = MessageTemplate(
        templateName: duplicatedTemplate.templateName,
        description: duplicatedTemplate.description,
        category: duplicatedTemplate.category,
        messageContent: duplicatedTemplate.messageContent,
        placeholders: List.from(duplicatedTemplate.placeholders),
        isActive: duplicatedTemplate.isActive,
        sortOrder: duplicatedTemplate.sortOrder,
      );

      await context.read<AppStateProvider>().addMessageTemplate(newTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message template duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error duplicating template: $e');
      }
    }
  }

  void _showMessageDeleteConfirmation(MessageTemplate template) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();

              try {
                await context
                    .read<AppStateProvider>()
                    .deleteMessageTemplate(template.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Message template deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorSnackBar('Error deleting template: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

// Email template selection helpers
  void _toggleEmailSelection(String templateId) {
    toggleSelection(_emailSelection, templateId);
  }

  void _editEmailTemplate(EmailTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmailTemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _showEmailTemplateContextMenu(EmailTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.pop(context);
                _editEmailTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send Test'),
              onTap: () {
                Navigator.pop(context);
                _sendTestEmail(template);
              },
            ),
            ListTile(
              leading: Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(template.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _handleEmailTemplateAction('toggle_active', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _handleEmailTemplateAction('duplicate', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleEmailTemplateAction('delete', template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestEmail(EmailTemplate template) {
    _showErrorSnackBar('Test email sending coming soon!');
  }

  void _handleEmailTemplateAction(String action, EmailTemplate template) {
    switch (action) {
      case 'toggle_active':
        context.read<AppStateProvider>().toggleEmailTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
          ),
        );
        break;

      case 'duplicate':
        _duplicateEmailTemplate(template);
        break;

      case 'delete':
        _showEmailDeleteConfirmation(template);
        break;
    }
  }

  void _duplicateEmailTemplate(EmailTemplate template) async {
    try {
      final duplicatedTemplate = template.copyWith(
        templateName: '${template.templateName} (Copy)',
        updatedAt: DateTime.now(),
      );

      // Create a new template (copyWith keeps the same ID, but we need a new one)
      final newTemplate = EmailTemplate(
        templateName: duplicatedTemplate.templateName,
        description: duplicatedTemplate.description,
        category: duplicatedTemplate.category,
        subject: duplicatedTemplate.subject,
        emailContent: duplicatedTemplate.emailContent,
        placeholders: List.from(duplicatedTemplate.placeholders),
        isActive: duplicatedTemplate.isActive,
        isHtml: duplicatedTemplate.isHtml,
        sortOrder: duplicatedTemplate.sortOrder,
      );

      await context.read<AppStateProvider>().addEmailTemplate(newTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email template duplicated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error duplicating template: $e');
      }
    }
  }

  void _showEmailDeleteConfirmation(EmailTemplate template) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();

              try {
                await context
                    .read<AppStateProvider>()
                    .deleteEmailTemplate(template.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Email template deleted successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                _showErrorSnackBar('Error deleting template: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTemplateCardContent(
      EmailTemplate template, bool isSelected) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: template.isActive
                      ? Colors.orange.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.email,
                  color: template.isActive
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.templateName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.orange.shade800 : null,
                          ),
                    ),
                    if (template.description.isNotEmpty)
                      Text(
                        template.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.orange.shade600
                                  : Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: template.isActive ? Colors.orange : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  template.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Email preview
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.subject.isNotEmpty) ...[
                  Text(
                    'Subject: ${template.subject.length > 50 ? '${template.subject.substring(0, 50)}...' : template.subject}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  template.emailContent.length > 100
                      ? '${template.emailContent.substring(0, 100)}...'
                      : template.emailContent,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Template details
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  Icons.category,
                  'Category: ${template.category}',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.dynamic_form,
                  '${template.placeholders.length} placeholders',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.calendar_today,
                  dateFormat.format(template.updatedAt),
                  isSelected: isSelected,
                ),
              ),
            ],
          ),

          if (!_emailSelection.isSelectionMode) ...[
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editEmailTemplate(template),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendTestEmail(template),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Test'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleEmailTemplateAction(action, template),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            template.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(template.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

// EMAIL TEMPLATE CARD BUILDERS (NEW - ADDITION TO EXISTING MESSAGE METHODS)
  Widget _buildSelectableEmailCard(EmailTemplate template) {
    final isSelected = _emailSelection.selectedIds.contains(template.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 3 : 1.5,
            color: isSelected ? Colors.orange.shade50 : null,
            child: InkWell(
              onTap: _emailSelection.isSelectionMode
                  ? () => _toggleEmailSelection(template.id)
                  : () => _editEmailTemplate(template),
              onLongPress: !_emailSelection.isSelectionMode
                  ? () => _showEmailTemplateContextMenu(template)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      )
                    : null,
                child: _buildEmailTemplateCardContent(template, isSelected),
              ),
            ),
          ),
          if (_emailSelection.isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) =>
                      _toggleEmailSelection(template.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailTemplateCard(EmailTemplate template) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editEmailTemplate(template),
        onLongPress: () => _showEmailTemplateContextMenu(template),
        borderRadius: BorderRadius.circular(12),
        child: _buildEmailTemplateCardContent(template, false),
      ),
    );
  }
}
