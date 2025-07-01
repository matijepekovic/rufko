import 'package:flutter/material.dart';
import '../../../../core/models/calculator/formula_variable.dart';

class VariableManager extends StatefulWidget {
  final FormulaVariable? variable; // For editing existing variables
  final Function(FormulaVariable) onVariableCreated;

  const VariableManager({
    super.key,
    this.variable,
    required this.onVariableCreated,
  });

  @override
  State<VariableManager> createState() => _VariableManagerState();
}

class _VariableManagerState extends State<VariableManager> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _defaultValueController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  final List<String> _commonUnits = [
    'sq ft',
    'ft',
    'in',
    '%',
    'squares',
    'bundles',
    'sheets',
    'linear ft',
    'pieces',
    'gallons',
    'lbs',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.variable != null) {
      _populateFields(widget.variable!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _defaultValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _populateFields(FormulaVariable variable) {
    _nameController.text = variable.name;
    _descriptionController.text = variable.description ?? '';
    _defaultValueController.text = variable.formattedDefaultValue;
    _unitController.text = variable.unit ?? '';
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final defaultValue = _defaultValueController.text.trim().isEmpty
        ? null
        : double.tryParse(_defaultValueController.text.trim());

    final variable = widget.variable?.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      defaultValue: defaultValue,
      unit: _unitController.text.trim().isEmpty 
          ? null 
          : _unitController.text.trim(),
      updatedAt: DateTime.now(),
    ) ?? FormulaVariable.create(
      formulaId: 0, // Will be set by parent
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      defaultValue: defaultValue,
      unit: _unitController.text.trim().isEmpty 
          ? null 
          : _unitController.text.trim(),
    );

    widget.onVariableCreated(variable);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.variable != null ? 'Edit Variable' : 'Add Variable'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Variable name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Variable Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                  helperText: 'Used as {VariableName} in formulas',
                ),
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'Please enter a variable name';
                  }
                  
                  final name = value!.trim();
                  if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
                    return 'Variable name must start with letter/underscore and contain only letters, numbers, underscores';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              // Default value
              TextFormField(
                controller: _defaultValueController,
                decoration: const InputDecoration(
                  labelText: 'Default Value (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isNotEmpty == true) {
                    if (double.tryParse(value!.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Unit
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'Unit (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.straighten),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    tooltip: 'Common units',
                    onSelected: (unit) {
                      _unitController.text = unit;
                    },
                    itemBuilder: (context) => _commonUnits.map((unit) {
                      return PopupMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}