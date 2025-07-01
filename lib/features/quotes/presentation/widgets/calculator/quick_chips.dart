import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/services/calculator/formula_service.dart';
import '../../../../../core/utils/responsive_constants.dart';
import '../../../../../core/models/calculator/custom_formula.dart';
import '../../../../../data/providers/state/app_state_provider.dart';

class QuickChips extends StatelessWidget {
  final Function(double Function(double)) onChipPressed;
  final double? currentValue;

  const QuickChips({
    super.key,
    required this.onChipPressed,
    this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        // Check if quick chips are enabled in settings
        if (!appState.appSettings.showCalculatorQuickChips) {
          return const SizedBox.shrink(); // Hide chips if disabled
        }

        final colorScheme = Theme.of(context).colorScheme;
        final hasValue = currentValue != null && !currentValue!.isNaN && !currentValue!.isInfinite;

        return FutureBuilder<List<CustomFormula>>(
          future: FormulaService.instance.getMostUsedFormulas(limit: 6),
          builder: (context, snapshot) {
        List<dynamic> items = [];
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          // Use most-used formulas
          items = snapshot.data!;
        } else {
          // Fall back to default quick chips if no usage data
          items = FormulaService.instance.getDefaultQuickChips();
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.keySpacing),
          itemCount: items.length,
          separatorBuilder: (context, index) => SizedBox(width: context.keySpacing * 2),
          itemBuilder: (context, index) {
            final item = items[index];
            
            if (item is CustomFormula) {
              return _FormulaChipWidget(
                formula: item,
                onPressed: hasValue ? () => _handleFormulaChip(item) : null,
                isEnabled: hasValue,
                colorScheme: colorScheme,
              );
            } else {
              // QuickChip fallback
              final chip = item as QuickChip;
              return _QuickChipWidget(
                chip: chip,
                onPressed: hasValue ? () => onChipPressed(chip.operation) : null,
                isEnabled: hasValue,
                colorScheme: colorScheme,
              );
            }
          },
        );
      },
    );
      }
    );
  }

  void _handleFormulaChip(CustomFormula formula) {
    // For now, just record usage and show a message
    // In the future, this could integrate with formula evaluation
    FormulaService.instance.recordFormulaUsage(formula.id!);
    
    // Create a simple operation if the formula has no variables and is a simple expression
    if (formula.variables.isEmpty) {
      // Try to create a simple operation for basic formulas
      final operation = _createOperationFromFormula(formula);
      if (operation != null) {
        onChipPressed(operation);
      }
    }
  }

  double Function(double)? _createOperationFromFormula(CustomFormula formula) {
    final expression = formula.expression.toLowerCase();
    
    // Handle simple formulas that can be converted to operations
    if (expression.contains('/ 100')) {
      return (value) => value / 100;
    } else if (expression.contains('* 1.1')) {
      return (value) => value * 1.1;
    } else if (expression.contains('* 1.15')) {
      return (value) => value * 1.15;
    } else if (expression.contains('* 0.9')) {
      return (value) => value * 0.9;
    } else if (expression.contains('* 1.05')) {
      return (value) => value * 1.05;
    }
    
    return null;
  }
}

class _QuickChipWidget extends StatefulWidget {
  final QuickChip chip;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final ColorScheme colorScheme;

  const _QuickChipWidget({
    required this.chip,
    this.onPressed,
    required this.isEnabled,
    required this.colorScheme,
  });

  @override
  State<_QuickChipWidget> createState() => _QuickChipWidgetState();
}

class _QuickChipWidgetState extends State<_QuickChipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _resetPress();
  }

  void _onTapCancel() {
    _resetPress();
  }

  void _resetPress() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(
          message: widget.chip.description,
          preferBelow: false,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.isPhone ? 12 : 16, 
              vertical: context.isPhone ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: widget.isEnabled
                  ? widget.colorScheme.primaryContainer
                  : widget.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: widget.isEnabled
                    ? widget.colorScheme.primary.withValues(alpha: 0.3)
                    : widget.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: widget.isEnabled && _isPressed
                  ? [
                      BoxShadow(
                        color: widget.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getChipIcon(widget.chip.label),
                  size: 16,
                  color: widget.isEnabled
                      ? widget.colorScheme.onPrimaryContainer
                      : widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.chip.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.isEnabled
                        ? widget.colorScheme.onPrimaryContainer
                        : widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getChipIcon(String label) {
    switch (label) {
      case 'ft → sq ft':
        return Icons.square_foot;
      case '÷100 (sq)':
        return Icons.calculate;
      case '+10% waste':
        return Icons.add_circle_outline;
      case '×1.15 (pitch)':
        return Icons.trending_up;
      case '×0.9 (coverage)':
        return Icons.layers;
      case '+5% overage':
        return Icons.add_box;
      default:
        return Icons.functions;
    }
  }
}

class _FormulaChipWidget extends StatefulWidget {
  final CustomFormula formula;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final ColorScheme colorScheme;

  const _FormulaChipWidget({
    required this.formula,
    this.onPressed,
    required this.isEnabled,
    required this.colorScheme,
  });

  @override
  State<_FormulaChipWidget> createState() => _FormulaChipWidgetState();
}

class _FormulaChipWidgetState extends State<_FormulaChipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _resetPress();
  }

  void _onTapCancel() {
    _resetPress();
  }

  void _resetPress() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(
          message: widget.formula.description ?? widget.formula.name,
          preferBelow: false,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.isPhone ? 12 : 16, 
              vertical: context.isPhone ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: widget.isEnabled
                  ? widget.colorScheme.primaryContainer
                  : widget.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: widget.isEnabled
                    ? widget.colorScheme.primary.withValues(alpha: 0.3)
                    : widget.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: widget.isEnabled && _isPressed
                  ? [
                      BoxShadow(
                        color: widget.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.formula.isFavorite ? Icons.star : _getCategoryIcon(widget.formula.category),
                  size: 16,
                  color: widget.isEnabled
                      ? widget.colorScheme.onPrimaryContainer
                      : widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.formula.name,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.isEnabled
                        ? widget.colorScheme.onPrimaryContainer
                        : widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'roofing':
        return Icons.roofing;
      case 'materials':
        return Icons.construction;
      case 'labor':
        return Icons.engineering;
      case 'waste':
        return Icons.add_circle_outline;
      default:
        return Icons.functions;
    }
  }
}