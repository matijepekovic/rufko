import 'package:flutter/material.dart';
import '../../../../core/models/calculator/custom_formula.dart';
import '../../../../core/models/calculator/formula_variable.dart';
import '../../../../core/services/calculator/formula_service.dart';
import 'variable_manager.dart';

class FormulaBuilder extends StatefulWidget {
  final CustomFormula? formula; // For editing existing formulas
  final Function(CustomFormula) onSave;

  const FormulaBuilder({
    super.key,
    this.formula,
    required this.onSave,
  });

  @override
  State<FormulaBuilder> createState() => _FormulaBuilderState();
}

class _FormulaBuilderState extends State<FormulaBuilder> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expressionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  final FormulaService _formulaService = FormulaService.instance;
  List<FormulaVariable> _variables = [];
  List<String> _availableCategories = [];
  bool _isGlobal = false;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (widget.formula != null) {
      _populateFields(widget.formula!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expressionController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _formulaService.getCategories();
      setState(() {
        _availableCategories = categories;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _populateFields(CustomFormula formula) {
    _nameController.text = formula.name;
    _expressionController.text = formula.expression;
    _descriptionController.text = formula.description ?? '';
    _categoryController.text = formula.category ?? '';
    _isGlobal = formula.isGlobal;
    _isFavorite = formula.isFavorite;
    _variables = List.from(formula.variables);
  }

  void _onExpressionChanged() {
    final expression = _expressionController.text;
    final variableNames = _formulaService.extractVariableNames(expression);
    
    // Add new variables found in expression
    for (final name in variableNames) {
      if (!_variables.any((v) => v.name == name)) {
        _variables.add(FormulaVariable.create(
          formulaId: 0, // Will be set when saving
          name: name,
        ));
      }
    }
    
    // Remove variables no longer in expression
    _variables.removeWhere((v) => !variableNames.contains(v.name));
    
    setState(() {});
  }

  void _addVariable() {
    showDialog(
      context: context,
      builder: (context) => VariableManager(
        onVariableCreated: (variable) {
          setState(() {
            _variables.add(variable);
          });
        },
      ),
    );
  }

  void _editVariable(int index) {
    showDialog(
      context: context,
      builder: (context) => VariableManager(
        variable: _variables[index],
        onVariableCreated: (variable) {
          setState(() {
            _variables[index] = variable;
          });
        },
      ),
    );
  }

  void _removeVariable(int index) {
    setState(() {
      _variables.removeAt(index);
    });
  }

  void _insertVariableIntoExpression(String variableName) {
    final text = _expressionController.text;
    final selection = _expressionController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '{$variableName}',
    );
    
    _expressionController.text = newText;
    _expressionController.selection = TextSelection.collapsed(
      offset: selection.start + variableName.length + 2,
    );
    
    _onExpressionChanged();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_formulaService.validateFormulaExpression(_expressionController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid formula expression'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final formula = widget.formula?.copyWith(
        name: _nameController.text.trim(),
        expression: _expressionController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        isGlobal: _isGlobal,
        isFavorite: _isFavorite,
        variables: _variables,
        updatedAt: DateTime.now(),
      ) ?? CustomFormula.create(
        name: _nameController.text.trim(),
        expression: _expressionController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        isGlobal: _isGlobal,
      ).copyWith(
        isFavorite: _isFavorite,
        variables: _variables,
      );
      
      widget.onSave(formula);
      
      if (widget.formula == null) {
        // Clear form for new formula
        _nameController.clear();
        _expressionController.clear();
        _descriptionController.clear();
        _categoryController.clear();
        setState(() {
          _variables.clear();
          _isGlobal = false;
          _isFavorite = false;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDialog = widget.formula != null;

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Formula name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Formula Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value?.trim().isEmpty == true) {
                return 'Please enter a formula name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Expression input
          TextFormField(
            controller: _expressionController,
            decoration: InputDecoration(
              labelText: 'Expression',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.functions),
              helperText: 'Use {VariableName} for variables, +, -, ×, ÷ for operations',
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Insert variable',
                onSelected: _insertVariableIntoExpression,
                itemBuilder: (context) => _variables.map((variable) {
                  return PopupMenuItem(
                    value: variable.name,
                    child: Text('{${variable.name}}'),
                  );
                }).toList(),
              ),
            ),
            maxLines: 3,
            style: const TextStyle(fontFamily: 'monospace'),
            onChanged: (_) => _onExpressionChanged(),
            validator: (value) {
              if (value?.trim().isEmpty == true) {
                return 'Please enter an expression';
              }
              if (!_formulaService.validateFormulaExpression(value!)) {
                return 'Invalid expression syntax';
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
          
          // Category
          TextFormField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'Category (optional)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category),
              suffixIcon: _availableCategories.isNotEmpty
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (category) {
                        _categoryController.text = category;
                      },
                      itemBuilder: (context) => _availableCategories.map((category) {
                        return PopupMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    )
                  : null,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Options
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Global'),
                  subtitle: const Text('Available to all users'),
                  value: _isGlobal,
                  onChanged: (value) {
                    setState(() {
                      _isGlobal = value ?? false;
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Favorite'),
                  subtitle: const Text('Show at top'),
                  value: _isFavorite,
                  onChanged: (value) {
                    setState(() {
                      _isFavorite = value ?? false;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Variables section
          if (_variables.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'Variables',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addVariable,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Variable'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            ...List.generate(_variables.length, (index) {
              final variable = _variables[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(variable.name),
                  subtitle: variable.description != null
                      ? Text(variable.description!)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (variable.defaultValue != null)
                        Chip(
                          label: Text(variable.formattedDefaultValue),
                          backgroundColor: colorScheme.primaryContainer,
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _editVariable(index),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _removeVariable(index),
                        icon: const Icon(Icons.delete),
                        color: colorScheme.error,
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 16),
          ],
        ],
      ),
    );

    if (isDialog) {
      return AlertDialog(
        title: Text(widget.formula != null ? 'Edit Formula' : 'Create Formula'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isLoading ? null : _onSave,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(child: content),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _onSave,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Saving...'),
                        ],
                      )
                    : const Text('Save Formula'),
              ),
            ),
          ],
        ),
      );
    }
  }
}