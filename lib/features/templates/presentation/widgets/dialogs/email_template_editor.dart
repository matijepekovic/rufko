import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/templates/email_template.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../controllers/email_template_editor_controller.dart';
import '../../controllers/placeholder_help_controller.dart';
import '../form_components/template_form_field.dart';
import '../form_components/placeholder_display_widget.dart';
import '../form_components/template_preview_widget.dart';
import 'category_creation_dialog.dart';
import 'placeholder_help_dialog.dart';

/// Refactored EmailTemplateEditorScreen with extracted components
/// Original 1,222-line monolithic file broken down into manageable components
/// All original functionality preserved with improved maintainability
class EmailTemplateEditorScreen extends StatefulWidget {
  const EmailTemplateEditorScreen({
    super.key,
    this.existingTemplate,
    this.initialCategory,
  });

  final EmailTemplate? existingTemplate;
  final String? initialCategory;

  @override
  State<EmailTemplateEditorScreen> createState() => _EmailTemplateEditorScreenState();
}

class _EmailTemplateEditorScreenState extends State<EmailTemplateEditorScreen> {
  late EmailTemplateEditorController _controller;
  late Future<Map<String, List<Map<String, dynamic>>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _controller = EmailTemplateEditorController(
      context: context,
      initialTemplate: widget.existingTemplate,
      initialCategory: widget.initialCategory,
    );
    _categoriesFuture = context.read<AppStateProvider>().getAllTemplateCategories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody();
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _controller.isEditing ? 'Edit Email' : 'New Email',
        style: const TextStyle(fontSize: 18),
      ),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.data_object, size: 20),
          onPressed: _showFieldSelector,
          tooltip: 'Insert Field',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoCard(),
                  const SizedBox(height: 16),
                  _buildContentCard(),
                  const SizedBox(height: 16),
                  _buildPlaceholdersCard(),
                  const SizedBox(height: 16),
                  _buildPreviewCard(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Template Information', Icons.info_outline),
            const SizedBox(height: 16),
            TemplateFormField(
              controller: _controller.templateNameController,
              label: 'Template Name',
              hintText: 'e.g., Quote Follow-up, Welcome Email',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            TemplateFormField(
              controller: _controller.descriptionController,
              label: 'Description',
              hintText: 'Describe when this template should be used',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildTemplateSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Email Content', Icons.email),
            const SizedBox(height: 16),
            TemplateFormField(
              controller: _controller.subjectController,
              label: 'Subject Line',
              hintText: 'Enter email subject',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            TemplateContentField(
              controller: _controller.emailContentController,
              label: 'Email Content',
              hintText: 'Enter your email message here...',
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholdersCard() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return PlaceholderDisplayWidget(
          placeholders: _controller.detectedPlaceholders,
        );
      },
    );
  }

  Widget _buildPreviewCard() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller.subjectController,
      builder: (context, subjectValue, child) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller.emailContentController,
          builder: (context, contentValue, child) {
            return ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                return TemplatePreviewWidget(
                  subject: subjectValue.text,
                  content: contentValue.text,
                  isHtml: _controller.isHtml,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 2,
            child: const LinearProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final allCategories = snapshot.data!;
        final emailCategories = allCategories['email_templates'] ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Category *',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Category'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _controller.selectedCategoryKey,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Select category'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
              items: emailCategories.map<DropdownMenuItem<String>>((category) {
                return DropdownMenuItem<String>(
                  value: category['key'] as String,
                  child: Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 6),
                      Text(category['name'] as String, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                _controller.selectedCategoryKey = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemplateSettings() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Active', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Template is available for use', style: TextStyle(fontSize: 12)),
                    value: _controller.isActive,
                    onChanged: (value) {
                      _controller.isActive = value ?? true;
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('HTML Format', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Enable HTML formatting', style: TextStyle(fontSize: 12)),
                    value: _controller.isHtml,
                    onChanged: (value) {
                      _controller.isHtml = value ?? false;
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(_controller.isEditing ? 'Update' : 'Create'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateCategoryDialog() async {
    final categoryName = await showCategoryCreationDialog(
      context: context,
      title: 'Create Email Category',
      description: 'Enter a name for your new email template category:',
      hintText: 'e.g., Quotes, Follow-up, Invoices',
      onCategoryCreated: _controller.createCategory,
    );

    if (categoryName != null && mounted) {
      // Refresh the categories future to include the new category
      setState(() {
        _categoriesFuture = context.read<AppStateProvider>().getAllTemplateCategories();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created category: $categoryName'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showFieldSelector() {
    final controller = PlaceholderHelpController(
      appState: context.read<AppStateProvider>(),
    );
    showDialog(
      context: context,
      builder: (context) => PlaceholderHelpDialog(
        controller: controller,
        onPlaceholderSelected: _insertField,
      ),
    );
  }

  void _insertField(String fieldName) {
    final controller = _controller.emailContentController;
    final text = controller.text;
    final selection = controller.selection;
    
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '{$fieldName}',
    );
    
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + fieldName.length + 2,
      ),
    );
    
    Navigator.pop(context);
  }

  Future<void> _handleSave() async {
    final success = await _controller.saveTemplate();
    
    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _controller.isEditing 
                ? 'Email template updated successfully!' 
                : 'Email template created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check the form for errors'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}