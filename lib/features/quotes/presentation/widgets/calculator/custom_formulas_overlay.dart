import 'package:flutter/material.dart';
import '../../../../../core/models/calculator/custom_formula.dart';
import '../../../../../core/services/calculator/formula_service.dart';

class CustomFormulasOverlay extends StatefulWidget {
  final AnimationController controller;
  final Function(String, Map<String, double>) onFormulaSelected;
  final VoidCallback onClose;

  const CustomFormulasOverlay({
    super.key,
    required this.controller,
    required this.onFormulaSelected,
    required this.onClose,
  });

  @override
  State<CustomFormulasOverlay> createState() => _CustomFormulasOverlayState();
}

class _CustomFormulasOverlayState extends State<CustomFormulasOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FormulaService _formulaService = FormulaService.instance;
  
  List<CustomFormula> _formulas = [];
  List<CustomFormula> _filteredFormulas = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFormulas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFormulas() async {
    try {
      final formulas = await _formulaService.getAllFormulas();
      setState(() {
        _formulas = formulas;
        _filteredFormulas = formulas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFormulas = _formulas;
      } else {
        _filteredFormulas = _formulas.where((formula) {
          return formula.name.toLowerCase().contains(query) ||
                 formula.description?.toLowerCase().contains(query) == true ||
                 formula.expression.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _onFormulaSelected(CustomFormula formula) {
    if (formula.hasVariables) {
      _showVariableDialog(formula);
    } else {
      // Formula has no variables, can be used directly
      widget.onFormulaSelected(formula.expression, {});
    }
  }

  void _showVariableDialog(CustomFormula formula) {
    showDialog(
      context: context,
      builder: (context) => _VariableInputDialog(
        formula: formula,
        onSubmit: (variableValues) {
          widget.onFormulaSelected(formula.expression, variableValues);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayHeight = screenHeight * 0.3; // 30% of screen height

    return Positioned(
      bottom: screenHeight * 0.45, // Above the calculator modal
      left: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: widget.controller,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          height: overlayHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.functions,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Custom Formulas',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search formulas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              
              // Formulas list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredFormulas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty 
                                      ? Icons.search_off 
                                      : Icons.functions,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No formulas found'
                                      : 'No formulas available',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                    child: const Text('Clear search'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredFormulas.length,
                            itemBuilder: (context, index) {
                              final formula = _filteredFormulas[index];
                              return _FormulaListItem(
                                formula: formula,
                                onTap: () => _onFormulaSelected(formula),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormulaListItem extends StatelessWidget {
  final CustomFormula formula;
  final VoidCallback onTap;

  const _FormulaListItem({
    required this.formula,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: formula.isFavorite 
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            formula.isFavorite ? Icons.star : Icons.functions,
            color: formula.isFavorite 
                ? colorScheme.primary 
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                formula.name,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (formula.isGlobal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Global',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formula.displayExpression,
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (formula.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  formula.description!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
        trailing: formula.hasVariables
            ? Icon(
                Icons.input,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              )
            : Icon(
                Icons.play_arrow,
                color: colorScheme.primary,
                size: 20,
              ),
      ),
    );
  }
}

class _VariableInputDialog extends StatefulWidget {
  final CustomFormula formula;
  final Function(Map<String, double>) onSubmit;

  const _VariableInputDialog({
    required this.formula,
    required this.onSubmit,
  });

  @override
  State<_VariableInputDialog> createState() => _VariableInputDialogState();
}

class _VariableInputDialogState extends State<_VariableInputDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    for (final variable in widget.formula.variables) {
      _controllers[variable.name] = TextEditingController(
        text: variable.defaultValue?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final variableValues = <String, double>{};
      for (final entry in _controllers.entries) {
        final value = double.tryParse(entry.value.text);
        if (value != null) {
          variableValues[entry.key] = value;
        }
      }
      Navigator.of(context).pop();
      widget.onSubmit(variableValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Values: ${widget.formula.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.formula.variables.length,
            itemBuilder: (context, index) {
              final variable = widget.formula.variables[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _controllers[variable.name],
                  decoration: InputDecoration(
                    labelText: variable.displayName,
                    suffixText: variable.unit,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.trim().isEmpty == true) {
                      return 'Please enter a value';
                    }
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSubmit,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}