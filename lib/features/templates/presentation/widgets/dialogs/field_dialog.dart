import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/settings/custom_app_data.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../controllers/field_dialog_controller.dart';
import '../field_form/field_form_header.dart';
import '../field_form/field_category_dropdown.dart';
import '../field_form/field_type_dropdown.dart';
import '../field_form/field_basic_inputs.dart';
import '../field_form/field_advanced_options.dart';
import '../field_form/field_form_actions.dart';

/// Refactored FieldDialog with extracted components and controller
/// Original 807-line monolithic dialog broken down into manageable components
/// All original functionality preserved with improved maintainability
class FieldDialog extends StatefulWidget {
  final FieldDialogMode mode;
  final CustomAppDataField? existingField;
  final List<String> categories;
  final Map<String, String> categoryNames;
  final String? preSelectedCategory;

  const FieldDialog._({
    super.key,
    required this.mode,
    this.existingField,
    required this.categories,
    required this.categoryNames,
    this.preSelectedCategory,
  });

  factory FieldDialog.add({
    Key? key,
    required List<String> categories,
    required Map<String, String> categoryNames,
    String? preSelectedCategory,
  }) {
    return FieldDialog._(
      key: key,
      mode: FieldDialogMode.add,
      categories: categories,
      categoryNames: categoryNames,
      preSelectedCategory: preSelectedCategory,
    );
  }

  factory FieldDialog.edit(
    CustomAppDataField field, {
    Key? key,
    required List<String> categories,
    required Map<String, String> categoryNames,
  }) {
    return FieldDialog._(
      key: key,
      mode: FieldDialogMode.edit,
      existingField: field,
      categories: categories,
      categoryNames: categoryNames,
    );
  }

  /// Static method to show add dialog with category check
  /// Preserves all original functionality including category creation
  static Future<CustomAppDataField?> showAdd(BuildContext context,
      {String? preSelectedCategory}) async {
    final appState = context.read<AppStateProvider>();

    final allTemplateCategories = appState.templateCategories;
    final customFieldCategories = allTemplateCategories
        .where((cat) => cat.templateType == 'custom_fields')
        .toList();

    if (customFieldCategories.isEmpty) {
      final newCategory = await _createNewCategoryAndReturn(context);
      if (newCategory == null) return null;

      await appState.loadTemplateCategories();
      if (!context.mounted) return null;
      final updatedCategories = appState.templateCategories
          .where((cat) => cat.templateType == 'custom_fields')
          .toList();

      if (updatedCategories.isEmpty) return null;
      preSelectedCategory = newCategory;
    }

    final finalCategories = appState.templateCategories
        .where((cat) => cat.templateType == 'custom_fields')
        .toList();

    final availableCategories = <String>[];
    final categoryNames = <String, String>{};

    for (final category in finalCategories) {
      availableCategories.add(category.key);
      categoryNames[category.key] = category.name;
    }

    return showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return FieldDialog.add(
          categories: availableCategories,
          categoryNames: categoryNames,
          preSelectedCategory: preSelectedCategory,
        );
      },
    );
  }

  /// Create new category using controller logic
  /// Preserves original implementation exactly
  static Future<String?> _createNewCategoryAndReturn(BuildContext context) async {
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
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3), // RufkoTheme.primaryColor
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create Field Category',
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
                        'Create a new category for fields:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g., Project Info, Client Details, Inspection',
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
                              final categoryKey = categoryName
                                  .toLowerCase()
                                  .replaceAll(' ', '_');

                              await appState.addTemplateCategory(
                                  'custom_fields', categoryKey, categoryName);

                              if (context.mounted) {
                                Navigator.of(context).pop(categoryKey);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Created category: $categoryName'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
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
                          backgroundColor: const Color(0xFF2196F3), // RufkoTheme.primaryColor
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

  @override
  State<FieldDialog> createState() => _FieldDialogState();
}

class _FieldDialogState extends State<FieldDialog> {
  late FieldDialogController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FieldDialogController(
      context: context,
      mode: widget.mode,
      existingField: widget.existingField,
      preSelectedCategory: widget.preSelectedCategory,
      initialCategories: widget.categories,
      initialCategoryNames: widget.categoryNames,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - extracted to component
            FieldFormHeader(
              mode: widget.mode,
              existingFieldName: widget.existingField?.displayName,
              onClose: () => Navigator.of(context).pop(null),
            ),

            // Content - organized into focused components
            Flexible(
              child: Form(
                key: _controller.formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category dropdown with inline creation
                      FieldCategoryDropdown(controller: _controller),
                      const SizedBox(height: 12),

                      // Field type dropdown
                      FieldTypeDropdown(controller: _controller),
                      const SizedBox(height: 12),

                      // Basic inputs (field name, display name)
                      FieldBasicInputs(controller: _controller),
                      const SizedBox(height: 12),

                      // Advanced options (expandable)
                      FieldAdvancedOptions(controller: _controller),
                    ],
                  ),
                ),
              ),
            ),

            // Actions - extracted to component
            FieldFormActions(
              controller: _controller,
              onCancel: () => Navigator.of(context).pop(null),
              onSave: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle save operation with preserved functionality
  Future<void> _handleSave() async {
    final result = await _controller.handleSave();
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }
}