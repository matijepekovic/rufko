// lib/widgets/add_custom_field_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_app_data.dart';
import '../providers/app_state_provider.dart';
import '../mixins/field_type_mixin.dart';

class AddCustomFieldDialog extends StatefulWidget {
  final List<String> categories;
  final Map<String, String> categoryNames;

  const AddCustomFieldDialog({
    super.key,
    required this.categories,
    required this.categoryNames,
  });

  @override
  State<AddCustomFieldDialog> createState() => _AddCustomFieldDialogState();
}

class _AddCustomFieldDialogState extends State<AddCustomFieldDialog>
    with FieldTypeMixin {
  final _formKey = GlobalKey<FormState>();
  final _fieldNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _valueTextController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _selectedFieldCategory;
  String _selectedFieldType = 'text';
  bool _isRequired = false;
  bool _isLoading = false;
  bool _checkboxValue = false; // Add this for checkbox state




  @override
  void initState() {
    super.initState();
    // Initialize with first available category
    _selectedFieldCategory = widget.categories.isNotEmpty
        ? widget.categories.first
        : 'custom';

    // Initialize checkbox default value
    _valueTextController.text = 'false';
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    _displayNameController.dispose();
    _valueTextController.dispose();
    _placeholderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Data Field'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Category
              DropdownButtonFormField<String>(
                value: widget.categories.contains(_selectedFieldCategory)
                    ? _selectedFieldCategory
                    : (widget.categories.isNotEmpty ? widget.categories.first : null),
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories.map((String categoryValue) {
                  return DropdownMenuItem<String>(
                    value: categoryValue,
                    child: Text(widget.categoryNames[categoryValue] ?? categoryValue),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFieldCategory = newValue;
                    });
                  }
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Field Type
              DropdownButtonFormField<String>(
                value: _selectedFieldType,
                decoration: const InputDecoration(
                  labelText: 'Field Type *',
                  border: OutlineInputBorder(),
                ),
                items: fieldTypes.map((String fieldType) {
                  return DropdownMenuItem<String>(
                    value: fieldType,
                    child: Text(fieldTypeNames[fieldType] ?? fieldType),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFieldType = newValue;
                    });
                  }
                },
                validator: (value) => value == null ? 'Please select a field type' : null,
              ),
              const SizedBox(height: 16),

              // Field Name
              TextFormField(
                controller: _fieldNameController,
                decoration: const InputDecoration(
                  labelText: 'Field Name *',
                  hintText: 'e.g., representative_email (no spaces)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Auto-generate display name from field name
                  if (_displayNameController.text.isEmpty ||
                      _displayNameController.text == _generateDisplayName(_fieldNameController.text)) {
                    _displayNameController.text = _generateDisplayName(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a field name';
                  if (value.contains(' ')) return 'Field name cannot contain spaces';

                  final appState = context.read<AppStateProvider>();
                  if (appState.customAppDataFields.any((f) =>
                  f.fieldName == value.trim() && f.category == _selectedFieldCategory)) {
                    return 'This field name already exists in this category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name *',
                  hintText: 'e.g., Representative Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Current Value - Different UI for checkbox vs other types
              if (_selectedFieldType == 'checkbox') ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CheckboxListTile(
                    title: const Text('Default Checkbox State'),
                    subtitle: const Text('Set the initial state of this checkbox'),
                    value: _checkboxValue,
                    onChanged: (bool? value) {
                      setState(() {
                        _checkboxValue = value ?? false;
                        _valueTextController.text = _checkboxValue.toString();
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _valueTextController,
                  decoration: const InputDecoration(
                    labelText: 'Current Value *',
                    hintText: 'Enter the default value',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: _selectedFieldType == 'multiline' ? 3 : 1,
                  keyboardType: _selectedFieldType == 'number' ? TextInputType.number :
                  _selectedFieldType == 'email' ? TextInputType.emailAddress :
                  _selectedFieldType == 'phone' ? TextInputType.phone :
                  TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value for this field';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Placeholder (optional)
              TextFormField(
                controller: _placeholderController,
                decoration: const InputDecoration(
                  labelText: 'Placeholder (optional)',
                  hintText: 'e.g., Enter email address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Description (optional)
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of this field',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Required checkbox
              CheckboxListTile(
                title: const Text('Required Field'),
                subtitle: const Text('Must be filled when generating PDFs'),
                value: _isRequired,
                onChanged: (bool? value) {
                  setState(() {
                    _isRequired = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAddField,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E86AB),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Add Field'),
        ),
      ],
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

  Future<void> _handleAddField() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newFieldData = CustomAppDataField(
        fieldName: _fieldNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        fieldType: _selectedFieldType,
        category: _selectedFieldCategory,
        currentValue: _valueTextController.text.trim(),
        placeholder: _placeholderController.text.trim().isEmpty ? null : _placeholderController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isRequired: _isRequired,
      );

      debugPrint('🆕 Adding new custom field: ${newFieldData.fieldName}');
      Navigator.of(context).pop(newFieldData);
    } catch (e) {
      debugPrint('❌ Error in add field dialog: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding field: $e'),
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