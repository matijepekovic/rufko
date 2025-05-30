// lib/widgets/edit_custom_field_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_app_data.dart';
import '../providers/app_state_provider.dart';

class EditCustomFieldDialog extends StatefulWidget {
  final CustomAppDataField field;
  final List<String> categories;
  final Map<String, String> categoryNames;

  const EditCustomFieldDialog({
    Key? key,
    required this.field,
    required this.categories,
    required this.categoryNames,
  }) : super(key: key);

  @override
  State<EditCustomFieldDialog> createState() => _EditCustomFieldDialogState();
}

class _EditCustomFieldDialogState extends State<EditCustomFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fieldNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _valueTextController;
  late final TextEditingController _placeholderController;
  late final TextEditingController _descriptionController;

  late String _selectedFieldCategory;
  late String _selectedFieldType;
  late bool _isRequired;

  final List<String> _fieldTypes = [
    'text',
    'number',
    'email',
    'phone',
    'multiline',
    'date',
    'currency'
  ];

  final Map<String, String> _fieldTypeNames = {
    'text': 'Text',
    'number': 'Number',
    'email': 'Email',
    'phone': 'Phone',
    'multiline': 'Multi-line Text',
    'date': 'Date',
    'currency': 'Currency',
  };

  @override
  void initState() {
    super.initState();
    _fieldNameController = TextEditingController(text: widget.field.fieldName);
    _displayNameController = TextEditingController(text: widget.field.displayName);
    _valueTextController = TextEditingController(text: widget.field.currentValue);
    _placeholderController = TextEditingController(text: widget.field.placeholder ?? '');
    _descriptionController = TextEditingController(text: widget.field.description ?? '');
    _selectedFieldCategory = widget.field.category;
    _selectedFieldType = widget.field.fieldType;
    _isRequired = widget.field.isRequired;
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
                decoration: const InputDecoration(labelText: 'Category *'),
                items: widget.categories.where((c) => c != 'all').map((String categoryValue) {
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
                decoration: const InputDecoration(labelText: 'Field Type *'),
                items: _fieldTypes.map((String fieldType) {
                  return DropdownMenuItem<String>(
                    value: fieldType,
                    child: Text(_fieldTypeNames[fieldType] ?? fieldType),
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a field name';
                  if (value.contains(' ')) return 'Field name cannot contain spaces';
                  final appState = Provider.of<AppStateProvider>(context, listen: false);
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
                ),
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
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        ElevatedButton(
          child: const Text('Save Changes'),
          onPressed: _handleSaveChanges,
        ),
      ],
    );
  }

  void _handleSaveChanges() {
    if (_formKey.currentState!.validate()) {
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

      Navigator.of(context).pop(updatedField);
    }
  }
}