// lib/widgets/edit_field_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/custom_app_data.dart';
import '../../../providers/app_state_provider.dart';
import '../../../mixins/field_type_mixin.dart';
import '../../../theme/rufko_theme.dart';

class EditFieldDialog extends StatefulWidget {
  final CustomAppDataField field;
  final List<String> categories;
  final Map<String, String> categoryNames;

  const EditFieldDialog({
    super.key,
    required this.field,
    required this.categories,
    required this.categoryNames,
  });

  // Static method to create a new category
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
                    color: RufkoTheme.primaryColor,
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
                              final categoryKey = categoryName.toLowerCase().replaceAll(' ', '_');

                              await appState.addTemplateCategory('custom_fields', categoryKey, categoryName);

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

  @override
  State<EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<EditFieldDialog>
    with FieldTypeMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fieldNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _valueTextController;

  late String _selectedFieldCategory;
  late String _selectedFieldType;
  late bool _isRequired;
  bool _isLoading = false;
  bool _checkboxValue = false;

  // Extended categories and names to include new categories created during editing
  late List<String> _currentCategories;
  late Map<String, String> _currentCategoryNames;

  // Special value for "Create New Category" option
  static const String _createNewCategoryValue = '__create_new_category__';

  @override
  void initState() {
    super.initState();
    _fieldNameController = TextEditingController(text: widget.field.fieldName);
    _displayNameController = TextEditingController(text: widget.field.displayName);
    _valueTextController = TextEditingController(text: widget.field.currentValue);

    _currentCategories = List.from(widget.categories);
    _currentCategoryNames = Map.from(widget.categoryNames);

    // Keep the field's original category if it exists, otherwise use first available
    if (widget.categories.contains(widget.field.category)) {
      _selectedFieldCategory = widget.field.category;
    } else if (widget.categories.isNotEmpty) {
      _selectedFieldCategory = widget.categories.first;
    } else {
      // This shouldn't happen, but fallback to the original category
      _selectedFieldCategory = widget.field.category;
    }

    _selectedFieldType = widget.field.fieldType;
    _isRequired = widget.field.isRequired;

    // Initialize checkbox state if it's a checkbox field
    if (_selectedFieldType == 'checkbox') {
      _checkboxValue = widget.field.currentValue.toLowerCase() == 'true';
    }

    debugPrint('🔧 Editing field: ${widget.field.fieldName} in category: $_selectedFieldCategory');
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    _displayNameController.dispose();
    _valueTextController.dispose();
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
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              decoration: BoxDecoration(
                color: RufkoTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit: ${widget.field.displayName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category dropdown with "Create New Category" option
                      DropdownButtonFormField<String>(
                        value: _selectedFieldCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          // Regular categories
                          ..._currentCategories.map((String categoryValue) {
                            return DropdownMenuItem<String>(
                              value: categoryValue,
                              child: Text(
                                _currentCategoryNames[categoryValue] ?? categoryValue,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }),
                          // Divider
                          if (_currentCategories.isNotEmpty)
                            const DropdownMenuItem<String>(
                              enabled: false,
                              value: null,
                              child: Divider(height: 1),
                            ),
                          // Create New Category option
                          DropdownMenuItem<String>(
                            value: _createNewCategoryValue,
                            child: Row(
                              children: [
                                Icon(Icons.add, color: RufkoTheme.primaryColor, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Create New Category...',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) async {
                          if (newValue == _createNewCategoryValue) {
                            // Show create category dialog
                            final newCategory = await EditFieldDialog._createNewCategoryAndReturn(context);
                            if (newCategory != null && mounted) {
                              // Update the local categories and select the new one
                              final appState = context.read<AppStateProvider>();
                              await appState.loadTemplateCategories();

                              final updatedCategories = appState.templateCategories
                                  .where((cat) => cat.templateType == 'custom_fields')
                                  .toList();

                              setState(() {
                                _currentCategories.clear();
                                _currentCategoryNames.clear();

                                for (final category in updatedCategories) {
                                  _currentCategories.add(category.key);
                                  _currentCategoryNames[category.key] = category.name;
                                }

                                _selectedFieldCategory = newCategory;
                              });

                              debugPrint('🆕 Created and selected new category: $newCategory');
                            }
                          } else if (newValue != null && newValue != _createNewCategoryValue) {
                            setState(() {
                              _selectedFieldCategory = newValue;
                            });
                            debugPrint('🔄 Category changed to: $newValue');
                          }
                        },
                        validator: (value) => value == null || value == _createNewCategoryValue ? 'Select category' : null,
                      ),
                      const SizedBox(height: 12),

                      // Field Type dropdown - compact
                      DropdownButtonFormField<String>(
                        value: _selectedFieldType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: fieldTypes.map((String fieldType) {
                          return DropdownMenuItem<String>(
                            value: fieldType,
                            child: Text(
                              fieldTypeNames[fieldType] ?? fieldType,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFieldType = newValue;
                              // Reset checkbox value when type changes
                              if (newValue == 'checkbox') {
                                _checkboxValue = _valueTextController.text.toLowerCase() == 'true';
                              }
                            });
                          }
                        },
                        validator: (value) => value == null ? 'Select type' : null,
                      ),
                      const SizedBox(height: 12),

                      // Field Name - compact
                      TextFormField(
                        controller: _fieldNameController,
                        decoration: const InputDecoration(
                          labelText: 'Field Name',
                          hintText: 'no_spaces_allowed',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter field name';
                          if (value.contains(' ')) return 'No spaces allowed';

                          final appState = context.read<AppStateProvider>();
                          if (value.trim() != widget.field.fieldName &&
                              appState.customAppDataFields.any((f) =>
                              f.fieldName == value.trim() &&
                                  f.category == _selectedFieldCategory &&
                                  f.id != widget.field.id)) {
                            return 'Name already exists';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Display Name - compact
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'User Friendly Name',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter display name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Advanced Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        children: [
                          const SizedBox(height: 8),
                          if (_selectedFieldType == 'checkbox')
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CheckboxListTile(
                                title: const Text('Current State', style: TextStyle(fontSize: 14)),
                                subtitle: const Text('Current checkbox value', style: TextStyle(fontSize: 12)),
                                value: _checkboxValue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _checkboxValue = value ?? false;
                                    _valueTextController.text = _checkboxValue.toString();
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            )
                          else
                            TextFormField(
                              controller: _valueTextController,
                              decoration: const InputDecoration(
                                labelText: 'Current Value',
                                hintText: 'Enter current value',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 14),
                              maxLines: _selectedFieldType == 'multiline' ? 2 : 1,
                              keyboardType: _selectedFieldType == 'number' ? TextInputType.number :
                              _selectedFieldType == 'email' ? TextInputType.emailAddress :
                              _selectedFieldType == 'phone' ? TextInputType.phone :
                              TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter current value';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CheckboxListTile(
                              title: const Text('Required Field', style: TextStyle(fontSize: 14)),
                              subtitle: const Text('Must be filled for PDFs', style: TextStyle(fontSize: 12)),
                              value: _isRequired,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isRequired = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSaveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RufkoTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('💾 Saving field with category: $_selectedFieldCategory');

      final updatedField = CustomAppDataField(
        id: widget.field.id,
        fieldName: _fieldNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        fieldType: _selectedFieldType,
        category: _selectedFieldCategory,
        currentValue: _valueTextController.text.trim(),
        placeholder: null, // Removed as requested
        description: null, // Removed as requested
        isRequired: _isRequired,
        sortOrder: widget.field.sortOrder,
        createdAt: widget.field.createdAt,
        updatedAt: DateTime.now(),
      );

      debugPrint('💾 Updated field: ${updatedField.fieldName} in category: ${updatedField.category}');
      Navigator.of(context).pop(updatedField);
    } catch (e) {
      debugPrint('❌ Error in edit field dialog: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving field: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
