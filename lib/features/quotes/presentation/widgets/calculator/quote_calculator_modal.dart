import 'package:flutter/material.dart';
import 'expression_bar.dart';
import 'quick_chips.dart';
import 'calculator_keypad.dart';
import '../../../../../core/models/calculator/calculator_expression.dart';
import '../../../../../core/services/calculator/calculator_service.dart';

class QuoteCalculatorModal extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? unit;
  final Function(double) onValueCommitted;
  final VoidCallback? onCancel;

  const QuoteCalculatorModal({
    super.key,
    required this.title,
    this.initialValue,
    this.unit,
    required this.onValueCommitted,
    this.onCancel,
  });

  @override
  State<QuoteCalculatorModal> createState() => _QuoteCalculatorModalState();
}

class _QuoteCalculatorModalState extends State<QuoteCalculatorModal>
    with TickerProviderStateMixin {
  late AnimationController _modalController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _expression = '';
  CalculatorExpression _currentExpression = const CalculatorExpression(
    expression: '',
    isValid: true,
  );

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing value if provided
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _expression = widget.initialValue!;
      _updateExpression();
    }

    // Setup animations
    _modalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _modalController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _modalController,
      curve: Curves.easeOut,
    ));

    // Start entrance animation
    _modalController.forward();
  }

  @override
  void dispose() {
    _modalController.dispose();
    super.dispose();
  }

  void _updateExpression() {
    setState(() {
      _currentExpression = CalculatorService.evaluateExpression(_expression);
    });
  }

  void _onNumberPressed(String number) {
    setState(() {
      _expression = CalculatorService.addNumber(_expression, number, _expression.length);
    });
    _updateExpression();
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      _expression = CalculatorService.addOperator(_expression, operator, _expression.length);
    });
    _updateExpression();
  }

  void _onBackspace() {
    setState(() {
      _expression = CalculatorService.backspace(_expression);
    });
    _updateExpression();
  }

  void _onClear() {
    setState(() {
      _expression = CalculatorService.clear();
    });
    _updateExpression();
  }

  void _onQuickChipPressed(double Function(double) operation) {
    if (_currentExpression.hasResult) {
      final newValue = operation(_currentExpression.result!);
      setState(() {
        _expression = CalculatorService.formatNumber(newValue);
      });
      _updateExpression();
    }
  }

  void _toggleFormulasOverlay() {
    // Temporarily disabled - just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formula editor coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onDone() async {
    if (_currentExpression.hasResult) {
      // Animate out before calling callback
      await _modalController.reverse();
      if (!mounted) return;
      widget.onValueCommitted(_currentExpression.result!);
    }
  }

  Future<void> _onDismiss() async {
    if (!mounted) return;
    await _modalController.reverse();
    if (!mounted) return;
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.45; // 45% of screen height

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: _onDismiss,
        child: Stack(
          children: [
            // Background dimmer
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
              ),
            ),
            
            // Calculator modal
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: GestureDetector(
                  onTap: () {}, // Prevent dismiss when tapping the modal
                  child: Container(
                    height: modalHeight,
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
                        
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calculate,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.unit != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.unit!,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Expression bar (Zone A)
                        ExpressionBar(
                          expression: _currentExpression,
                          onExpressionChanged: (newExpression) {
                            setState(() {
                              _expression = newExpression;
                            });
                            _updateExpression();
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Main calculator content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                // Quick chips (Zone B)
                                QuickChips(
                                  onChipPressed: _onQuickChipPressed,
                                  currentValue: _currentExpression.result,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Calculator keypad and buttons
                                Expanded(
                                  child: Row(
                                    children: [
                                      // Keypad (Zone C) + fx button (Zone D)
                                      Expanded(
                                        flex: 3,
                                        child: CalculatorKeypad(
                                          onNumberPressed: _onNumberPressed,
                                          onOperatorPressed: _onOperatorPressed,
                                          onBackspace: _onBackspace,
                                          onClear: _onClear,
                                          onFxPressed: _toggleFormulasOverlay,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // Done button (Zone E)
                                      SizedBox(
                                        width: 80,
                                        child: FilledButton(
                                          onPressed: _currentExpression.hasResult ? _onDone : null,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                            minimumSize: const Size(double.infinity, double.infinity),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.check, size: 24),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Done',
                                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}