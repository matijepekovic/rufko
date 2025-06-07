// lib/widgets/edit_custom_field_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_app_data.dart';
import '../providers/app_state_provider.dart';
import '../mixins/field_type_mixin.dart';

class EditCustomFieldDialog extends StatefulWidget {
  final CustomAppDataField field;
  final List<String> categories;
  final Map<String, String> categoryNames;

  const EditCustomFieldDialog({
    super.key,
    required this.field,
    required this.categories,
    required this.categoryNames,
  });

  @override
  State<EditCustomFieldDialog> createState() => _EditCustomFieldDialogState();
}

class _EditCustomFieldDialogState extends State<EditCustomFieldDialog>
    with FieldTypeMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fieldNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _valueTextController;
  late final TextEditingController _placeholderController;
  late final TextEditingController _descriptionController;

  late String _selectedFieldCategory;
  late String _selectedFieldType;
  late bool _isRequired;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _fieldNameController = TextEditingController(text: widget.field.fieldName);
    _displayNameController = TextEditingController(text: widget.field.displayName);
    _valueTextController = TextEditingController(text: widget.field.currentValue);
    _placeholderController = TextEditingController(text: widget.field.placeholder ?? '');
    _descriptionController = TextEditingController(text: widget.field.description ?? '');

    // Ensure the field category exists in available categories
    _selectedFieldCategory = widget.categories.contains(widget.field.category)
        ? widget.field.category
        : (widget.categories.isNotEmpty ? widget.categories.first : 'custom');

    _selectedFieldType = widget.field.fieldType;
    _isRequired = widget.field.isRequired;

    debugPrint('🔧 Editing field: ${widget.field.fieldName} in category: $_selectedFieldCategory');
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
      title: Text('Edit Field: ${widget.field.displayName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              DropdownButtonFormField<String>(
                value: _selectedFieldCategory,
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
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a field name';
                  if (value.contains(' ')) return 'Field name cannot contain spaces';

                  final appState = context.read<AppStateProvider>();
                  // Allow keeping the same name, but check for duplicates with different IDs
                  if (value.trim() != widget.field.fieldName &&
                      appState.customAppDataFields.any((f) =>
                      f.fieldName == value.trim() &&
                          f.category == _selectedFieldCategory &&
                          f.id != widget.field.id)) {
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

              // Current Value
              TextFormField(
                controller: _valueTextController,
                decoration: const InputDecoration(
                  labelText: 'Current Value *',
                  hintText: 'e.g., example@example.com',
                  border: OutlineInputBorder(),
                ),
                maxLines: _selectedFieldType == 'multiline' ? 3 : 1,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value for this field';
                  }
                  return null;
                },
              ),
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSaveChanges,
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
              : const Text('Save Changes'),
        ),
      ],
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
      final updatedField = CustomAppDataField(
        id: widget.field.id, // Keep the same ID
        fieldName: _fieldNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        fieldType: _selectedFieldType,
        category: _selectedFieldCategory,
        currentValue: _valueTextController.text.trim(),
        placeholder: _placeholderController.text.trim().isEmpty ? null : _placeholderController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isRequired: _isRequired,
        sortOrder: widget.field.sortOrder, // Keep the same sort order
        createdAt: widget.field.createdAt, // Keep original creation date
        updatedAt: DateTime.now(), // Update the modified date
      );

      debugPrint('💾 Saving updated field: ${updatedField.fieldName}');
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