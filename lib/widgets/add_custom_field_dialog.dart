// lib/widgets/add_custom_field_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_app_data.dart';
import '../providers/app_state_provider.dart';

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

class _AddCustomFieldDialogState extends State<AddCustomFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fieldNameController = TextEditingController();
  final _valueTextController = TextEditingController();

  late String _selectedFieldCategory;

  @override
  void initState() {
    super.initState();
    // Initialize with first non-'all' category
    _selectedFieldCategory = widget.categories.where((c) => c != 'all').isNotEmpty
        ? widget.categories.where((c) => c != 'all').first
        : 'custom';
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    _valueTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get unique categories and filter out 'all'
    final availableCategories = widget.categories.where((c) => c != 'all').toSet().toList();

    return AlertDialog(
      title: const Text('Add Custom Data Field'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: availableCategories.contains(_selectedFieldCategory)
                    ? _selectedFieldCategory
                    : (availableCategories.isNotEmpty ? availableCategories.first : 'custom'),
                decoration: const InputDecoration(labelText: 'Category *'),
                items: availableCategories.map((String categoryValue) {
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
                  if (appState.customAppDataFields.any((f) => f.fieldName == value.trim() && f.category == _selectedFieldCategory)) {
                    return 'This field name already exists in this category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueTextController,
                decoration: const InputDecoration(
                  labelText: 'Text / Value *',
                  hintText: 'e.g., example@example.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the text/value for this field';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        ElevatedButton(
          onPressed: _handleAddField,
          child: const Text('Add Field'),
        ),
      ],
    );
  }

  void _handleAddField() {
    if (_formKey.currentState!.validate()) {
      final newFieldData = CustomAppDataField(
        fieldName: _fieldNameController.text.trim(),
        displayName: _fieldNameController.text.trim()
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
            .join(' '),
        fieldType: 'text',
        category: _selectedFieldCategory,
        currentValue: _valueTextController.text.trim(),
      );

      Navigator.of(context).pop(newFieldData);
    }
  }
}