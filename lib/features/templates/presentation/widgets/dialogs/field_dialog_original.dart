// lib/widgets/field_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/models/settings/custom_app_data.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../core/mixins/field_type_mixin.dart';
import '../../../../../app/theme/rufko_theme.dart';

enum FieldDialogMode { add, edit }

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

  // Static method to show add dialog with category check
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

  static Future<String?> _createNewCategoryAndReturn(
      BuildContext context) async {
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle,
                          color: Colors.white, size: 20),
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
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 20),
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
                          hintText:
                              'e.g., Project Info, Client Details, Inspection',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    border:
                        Border(top: BorderSide(color: Colors.grey.shade300)),
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
                                    content:
                                        Text('Created category: $categoryName'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Error creating category: $e'),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
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

class _FieldDialogState extends State<FieldDialog> with FieldTypeMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fieldNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _valueTextController;

  late String _selectedFieldCategory;
  late String _selectedFieldType;
  late bool _isRequired;
  bool _isLoading = false;
  bool _checkboxValue = false;

  late List<String> _currentCategories;
  late Map<String, String> _currentCategoryNames;

  static const String _createNewCategoryValue = '__create_new_category__';

  @override
  void initState() {
    super.initState();

    _currentCategories = List.from(widget.categories);
    _currentCategoryNames = Map.from(widget.categoryNames);

    if (widget.mode == FieldDialogMode.edit && widget.existingField != null) {
      final field = widget.existingField!;
      _fieldNameController = TextEditingController(text: field.fieldName);
      _displayNameController = TextEditingController(text: field.displayName);
      _valueTextController = TextEditingController(text: field.currentValue);

      if (widget.categories.contains(field.category)) {
        _selectedFieldCategory = field.category;
      } else if (widget.categories.isNotEmpty) {
        _selectedFieldCategory = widget.categories.first;
      } else {
        _selectedFieldCategory = field.category;
      }

      _selectedFieldType = field.fieldType;
      _isRequired = field.isRequired;

      if (_selectedFieldType == 'checkbox') {
        _checkboxValue = field.currentValue.toLowerCase() == 'true';
      }
    } else {
      _fieldNameController = TextEditingController();
      _displayNameController = TextEditingController();
      _valueTextController = TextEditingController();

      if (widget.preSelectedCategory != null &&
          _currentCategories.contains(widget.preSelectedCategory!)) {
        _selectedFieldCategory = widget.preSelectedCategory!;
      } else if (_currentCategories.isNotEmpty) {
        _selectedFieldCategory = _currentCategories.first;
      } else {
        // When no categories exist yet, default to the special
        // "Create New Category" option so the dropdown has a valid value.
        _selectedFieldCategory = _createNewCategoryValue;
      }
      _selectedFieldType = 'text';
      _isRequired = false;
      _valueTextController.text = 'false';
    }
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
              decoration: const BoxDecoration(
                color: RufkoTheme.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.mode == FieldDialogMode.add
                        ? Icons.add_circle
                        : Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.mode == FieldDialogMode.add
                          ? 'Add Field'
                          : 'Edit: ${widget.existingField!.displayName}',
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
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 20),
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ..._currentCategories.map((String categoryValue) {
                            return DropdownMenuItem<String>(
                              value: categoryValue,
                              child: Text(
                                _currentCategoryNames[categoryValue] ??
                                    categoryValue,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }),
                          if (_currentCategories.isNotEmpty)
                            const DropdownMenuItem<String>(
                              enabled: false,
                              value: null,
                              child: Divider(height: 1),
                            ),
                          DropdownMenuItem<String>(
                            value: _createNewCategoryValue,
                            child: Row(
                              children: [
                                Icon(Icons.add,
                                    color: RufkoTheme.primaryColor, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Create New Category...',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) async {
                          if (newValue == _createNewCategoryValue) {
                            final newCategory =
                                await FieldDialog._createNewCategoryAndReturn(
                                    context);
                            if (newCategory != null && mounted) {
                              // ignore: use_build_context_synchronously
                              final appState = context.read<AppStateProvider>();
                              await appState.loadTemplateCategories();

                              final updatedCategories = appState
                                  .templateCategories
                                  .where((cat) =>
                                      cat.templateType == 'custom_fields')
                                  .toList();

                              setState(() {
                                _currentCategories.clear();
                                _currentCategoryNames.clear();

                                for (final category in updatedCategories) {
                                  _currentCategories.add(category.key);
                                  _currentCategoryNames[category.key] =
                                      category.name;
                                }

                                _selectedFieldCategory = newCategory;
                              });
                            }
                          } else if (newValue != null &&
                              newValue != _createNewCategoryValue) {
                            setState(() {
                              _selectedFieldCategory = newValue;
                            });
                          }
                        },
                        validator: (value) =>
                            value == null || value == _createNewCategoryValue
                                ? 'Select category'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      // Field Type dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedFieldType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              if (newValue == 'checkbox') {
                                _checkboxValue =
                                    _valueTextController.text.toLowerCase() ==
                                        'true';
                              }
                            });
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Select type' : null,
                      ),
                      const SizedBox(height: 12),

                      // Field Name
                      TextFormField(
                        controller: _fieldNameController,
                        decoration: const InputDecoration(
                          labelText: 'Field Name',
                          hintText: 'no_spaces_allowed',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: widget.mode == FieldDialogMode.add
                            ? (value) {
                                if (_displayNameController.text.isEmpty ||
                                    _displayNameController.text ==
                                        _generateDisplayName(
                                            _fieldNameController.text)) {
                                  _displayNameController.text =
                                      _generateDisplayName(value);
                                }
                              }
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter field name';
                          }
                          if (value.contains(' ')) return 'No spaces allowed';

                          final appState = context.read<AppStateProvider>();
                          if (widget.mode == FieldDialogMode.edit) {
                            if (value.trim() !=
                                    widget.existingField!.fieldName &&
                                appState.customAppDataFields.any((f) =>
                                    f.fieldName == value.trim() &&
                                    f.category == _selectedFieldCategory &&
                                    f.id != widget.existingField!.id)) {
                              return 'Name already exists';
                            }
                          } else {
                            if (appState.customAppDataFields.any((f) =>
                                f.fieldName == value.trim() &&
                                f.category == _selectedFieldCategory)) {
                              return 'Name already exists in this category';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Display Name
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'User Friendly Name',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        title: const Text('Advanced Options',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        children: [
                          const SizedBox(height: 8),
                          if (_selectedFieldType == 'checkbox')
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                    widget.mode == FieldDialogMode.add
                                        ? 'Default State'
                                        : 'Current State',
                                    style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                    widget.mode == FieldDialogMode.add
                                        ? 'Initial checkbox value'
                                        : 'Current checkbox value',
                                    style: const TextStyle(fontSize: 12)),
                                value: _checkboxValue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _checkboxValue = value ?? false;
                                    _valueTextController.text =
                                        _checkboxValue.toString();
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            )
                          else
                            TextFormField(
                              controller: _valueTextController,
                              decoration: InputDecoration(
                                labelText: widget.mode == FieldDialogMode.add
                                    ? 'Default Value'
                                    : 'Current Value',
                                hintText: widget.mode == FieldDialogMode.add
                                    ? 'Enter default value'
                                    : 'Enter current value',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: const OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 14),
                              maxLines:
                                  _selectedFieldType == 'multiline' ? 2 : 1,
                              keyboardType: _selectedFieldType == 'number'
                                  ? TextInputType.number
                                  : _selectedFieldType == 'email'
                                      ? TextInputType.emailAddress
                                      : _selectedFieldType == 'phone'
                                          ? TextInputType.phone
                                          : TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return widget.mode == FieldDialogMode.add
                                      ? 'Enter default value'
                                      : 'Enter current value';
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
                              title: const Text('Required Field',
                                  style: TextStyle(fontSize: 14)),
                              subtitle: const Text('Must be filled for PDFs',
                                  style: TextStyle(fontSize: 12)),
                              value: _isRequired,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isRequired = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
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
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RufkoTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.mode == FieldDialogMode.add
                            ? 'Add Field'
                            : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateDisplayName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.mode == FieldDialogMode.add) {
        final newFieldData = CustomAppDataField(
          fieldName: _fieldNameController.text.trim(),
          displayName: _displayNameController.text.trim(),
          fieldType: _selectedFieldType,
          category: _selectedFieldCategory,
          currentValue: _valueTextController.text.trim(),
          placeholder: null,
          description: null,
          isRequired: _isRequired,
        );
        Navigator.of(context).pop(newFieldData);
      } else {
        final updatedField = CustomAppDataField(
          id: widget.existingField!.id,
          fieldName: _fieldNameController.text.trim(),
          displayName: _displayNameController.text.trim(),
          fieldType: _selectedFieldType,
          category: _selectedFieldCategory,
          currentValue: _valueTextController.text.trim(),
          placeholder: null,
          description: null,
          isRequired: _isRequired,
          sortOrder: widget.existingField!.sortOrder,
          createdAt: widget.existingField!.createdAt,
          updatedAt: DateTime.now(),
        );
        Navigator.of(context).pop(updatedField);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.mode == FieldDialogMode.add
                ? 'Error adding field: $e'
                : 'Error saving field: $e'),
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
