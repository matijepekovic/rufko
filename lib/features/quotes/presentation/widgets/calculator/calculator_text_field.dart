import 'package:flutter/material.dart';
import '../../../../../core/services/database/calculator_database_service.dart';
import '../../../../../core/utils/responsive_constants.dart';
import '../../controllers/calculator_ui_controller.dart';
import 'expression_bar.dart';
import 'quick_chips.dart';
import 'calculator_keypad.dart';
import '../../../../../shared/widgets/buttons/rufko_dialog_actions.dart';

class CalculatorTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? prefixText;
  final String? suffixText;
  final String? unit;
  final String? helperText;
  final Widget? prefixIcon;
  final bool readOnly;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final InputDecoration? decoration;
  final bool enabled;

  const CalculatorTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixText,
    this.suffixText,
    this.unit,
    this.helperText,
    this.prefixIcon,
    this.readOnly = false,
    this.validator,
    this.onChanged,
    this.decoration,
    this.enabled = true,
  });

  @override
  State<CalculatorTextField> createState() => _CalculatorTextFieldState();
}

class _CalculatorTextFieldState extends State<CalculatorTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isControllerOwned = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isControllerOwned = true;
    }
    
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_isControllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showCalculator() {
    // Check if calculator database is available
    try {
      CalculatorDatabaseService.instance.database;
    } catch (e) {
      // Fall back to regular text input if calculator not available
      _showRegularInput();
      return;
    }
    
    // Dismiss any keyboard
    _focusNode.unfocus();
    
    // Use showModalBottomSheet to avoid nested dialog issues
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // No background dimming
      builder: (context) => _CalculatorBottomSheet(
        title: widget.labelText ?? 'Enter Amount',
        initialValue: _controller.text,
        unit: widget.unit ?? widget.suffixText,
        onValueCommitted: (value) {
          setState(() {
            _controller.text = _formatValue(value);
          });
          if (widget.onChanged != null) {
            widget.onChanged!(_controller.text);
          }
          Navigator.of(context).pop();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
  
  void _showRegularInput() {
    showDialog(
      context: context,
      builder: (context) {
        final inputController = TextEditingController(text: _controller.text);
        return AlertDialog(
          title: Text(widget.labelText ?? 'Enter Amount'),
          content: TextField(
            controller: inputController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.labelText,
              suffixText: widget.unit ?? widget.suffixText,
            ),
            autofocus: true,
          ),
          actions: [
            RufkoDialogActions(
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: () {
                setState(() {
                  _controller.text = inputController.text;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(_controller.text);
                }
                Navigator.of(context).pop();
              },
              confirmText: 'Done',
            ),
          ],
        );
      },
    );
  }

  String _formatValue(double value) {
    // Format the value appropriately
    if (value == value.roundToDouble()) {
      return value.round().toString();
    } else {
      // Show up to 3 decimal places, removing trailing zeros
      return value.toStringAsFixed(3).replaceAll(RegExp(r'\.?0*$'), '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = widget.decoration ??
        InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText ?? widget.unit,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon,
          border: const OutlineInputBorder(),
        );

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: false, // Allow normal keyboard input
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: widget.validator,
      onChanged: widget.onChanged, // Allow direct text changes
      decoration: effectiveDecoration.copyWith(
        suffixIcon: widget.enabled
            ? Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _showCalculator,
                  icon: Icon(
                    Icons.calculate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Open calculator',
                ),
              )
            : effectiveDecoration.suffixIcon,
      ),
      // onTap removed - no longer shows calculator when field is tapped
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontFamily: 'monospace',
      ),
    );
  }
}

class _CalculatorBottomSheet extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? unit;
  final Function(double) onValueCommitted;
  final VoidCallback? onCancel;

  const _CalculatorBottomSheet({
    required this.title,
    this.initialValue,
    this.unit,
    required this.onValueCommitted,
    this.onCancel,
  });

  @override
  State<_CalculatorBottomSheet> createState() => _CalculatorBottomSheetState();
}

class _CalculatorBottomSheetState extends State<_CalculatorBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late CalculatorUIController _calculatorController;

  @override
  void initState() {
    super.initState();
    
    // Initialize calculator controller
    _calculatorController = CalculatorUIController();
    _calculatorController.initialize(widget.initialValue);

    // Setup slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start entrance animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _calculatorController.dispose();
    super.dispose();
  }

  // UI delegates to controller - no business logic here
  void _onNumberPressed(String number) => _calculatorController.onNumberPressed(number);
  void _onOperatorPressed(String operator) => _calculatorController.onOperatorPressed(operator);
  void _onBackspace() => _calculatorController.onBackspace();
  void _onClear() => _calculatorController.onClear();
  void _onQuickChipPressed(double Function(double) operation) => 
      _calculatorController.onQuickChipPressed(operation);

  void _toggleFormulasOverlay() {
    _calculatorController.toggleFormulaMode();
  }

  void _onDone() async {
    // Animate out first
    await _slideController.reverse();
    if (!mounted) return;
    
    // Only commit value if there's a valid result
    if (_calculatorController.hasResult && 
        _calculatorController.result != null && 
        !_calculatorController.result!.isNaN && 
        !_calculatorController.result!.isInfinite) {
      widget.onValueCommitted(_calculatorController.result!);
    }
    // If no valid result, just close without making changes
  }


  @override
  Widget build(BuildContext context) {
    final maxModalHeight = context.calculatorModalHeight;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxModalHeight,
          minHeight: ResponsiveConstants.minimumModalHeight,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Let content determine height
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 3),
            
            // Expression bar (Zone A)
            ListenableBuilder(
              listenable: _calculatorController,
              builder: (context, child) {
                return ExpressionBar(
                  expression: _calculatorController.currentExpression,
                  onExpressionChanged: _calculatorController.onExpressionChanged,
                );
              },
            ),
            
            const SizedBox(height: 4),
            
            // Main calculator content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick chips (Zone B)
                SizedBox(
                  height: context.quickChipsHeight,
                  child: ListenableBuilder(
                    listenable: _calculatorController,
                    builder: (context, child) {
                      return QuickChips(
                        onChipPressed: _onQuickChipPressed,
                        currentValue: _calculatorController.result,
                      );
                    },
                  ),
                ),
                
                SizedBox(height: context.isPhone ? 4 : 6),
                
                // Calculator keypad and buttons
                Padding(
                  padding: EdgeInsets.only(bottom: context.isPhone ? 12 : 16), // Prevent overflow
                  child: context.isLandscape && context.isPhone
                      ? _buildLandscapeLayout(context)
                      : _buildPortraitLayout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return ListenableBuilder(
      listenable: _calculatorController,
      builder: (context, child) {
        if (_calculatorController.isInFormulaMode) {
          return _buildFormulaList(context);
        } else {
          return CalculatorKeypad(
            onNumberPressed: _onNumberPressed,
            onOperatorPressed: _onOperatorPressed,
            onBackspace: _onBackspace,
            onClear: _onClear,
            onFxPressed: _toggleFormulasOverlay,
            onDone: _calculatorController.hasResult ? _onDone : null,
          );
        }
      },
    );
  }

  Widget _buildFormulaList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Formula mode header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.functions,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formulas',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _calculatorController.exitFormulaMode,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          
          // Formula list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true, // Let ListView size itself based on content
              padding: const EdgeInsets.all(8),
              itemCount: _calculatorController.filteredFormulas.length,
              itemBuilder: (context, index) {
                final formula = _calculatorController.filteredFormulas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      formula.isFavorite ? Icons.star : Icons.functions,
                      size: 20,
                      color: formula.isFavorite 
                          ? Colors.amber 
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      formula.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: formula.description != null 
                        ? Text(
                            formula.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: formula.category != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formula.category!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => _calculatorController.selectFormula(formula),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return ListenableBuilder(
      listenable: _calculatorController,
      builder: (context, child) {
        if (_calculatorController.isInFormulaMode) {
          return _buildFormulaList(context);
        } else {
          return CalculatorKeypad(
            onNumberPressed: _onNumberPressed,
            onOperatorPressed: _onOperatorPressed,
            onBackspace: _onBackspace,
            onClear: _onClear,
            onFxPressed: _toggleFormulasOverlay,
            onDone: _calculatorController.hasResult ? _onDone : null,
          );
        }
      },
    );
  }
}