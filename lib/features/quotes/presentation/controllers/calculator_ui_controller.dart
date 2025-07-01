import 'package:flutter/foundation.dart';
import '../../../../core/models/calculator/calculator_expression.dart';
import '../../../../core/services/calculator/calculator_service.dart';
import '../../../../core/services/calculator/formula_service.dart';
import '../../../../core/models/calculator/custom_formula.dart';

/// Controller for calculator UI that handles all business logic
/// Separates calculator operations from UI presentation
class CalculatorUIController extends ChangeNotifier {
  String _expression = '';
  CalculatorExpression _currentExpression = const CalculatorExpression(
    expression: '',
    isValid: true,
  );
  bool _isInFormulaMode = false;
  List<CustomFormula> _availableFormulas = [];
  String _formulaSearchQuery = '';

  // Read-only getters for UI
  String get expression => _expression;
  CalculatorExpression get currentExpression => _currentExpression;
  bool get hasResult => _currentExpression.hasResult;
  double? get result => _currentExpression.result;
  String get formattedResult => _currentExpression.formattedResult;
  bool get isValid => _currentExpression.isValid;
  String? get error => _currentExpression.error;
  bool get isInFormulaMode => _isInFormulaMode;
  List<CustomFormula> get availableFormulas => _availableFormulas;
  String get formulaSearchQuery => _formulaSearchQuery;

  /// Initialize calculator with optional initial value
  void initialize([String? initialValue]) {
    if (initialValue != null && initialValue.isNotEmpty) {
      _expression = initialValue;
      _updateExpression();
    }
  }

  /// Handle number button press with smart default replacement
  void onNumberPressed(String number) {
    _expression = CalculatorService.addNumber(_expression, number, _expression.length);
    _updateExpression();
  }

  /// Handle operator button press
  void onOperatorPressed(String operator) {
    if (operator == '%') {
      // Handle percentage as a special case
      if (_currentExpression.hasResult) {
        final percentage = _currentExpression.result! / 100;
        _expression = formatValue(percentage);
        _updateExpression();
      } else if (_expression.isNotEmpty) {
        // If there's an expression but no result, add "/100" to convert to percentage
        _expression = '($_expression)/100';
        _updateExpression();
      }
    } else {
      _expression = CalculatorService.addOperator(_expression, operator, _expression.length);
      _updateExpression();
    }
  }

  /// Handle backspace button press
  void onBackspace() {
    _expression = CalculatorService.backspace(_expression);
    _updateExpression();
  }

  /// Handle clear button press
  void onClear() {
    _expression = CalculatorService.clear();
    _updateExpression();
  }

  /// Handle direct expression change (from text input)
  void onExpressionChanged(String newExpression) {
    _expression = newExpression;
    _updateExpression();
  }

  /// Handle quick chip operations (like +10%, ×1.15, etc.)
  void onQuickChipPressed(double Function(double) operation) {
    if (_currentExpression.hasResult) {
      final newValue = operation(_currentExpression.result!);
      _expression = CalculatorService.formatNumber(newValue);
      _updateExpression();
    }
  }

  /// Get formatted value for result display
  String formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    } else {
      // Show up to 3 decimal places, removing trailing zeros
      return value.toStringAsFixed(3).replaceAll(RegExp(r'\.?0*$'), '');
    }
  }

  /// Private method to update expression evaluation
  void _updateExpression() {
    _currentExpression = CalculatorService.evaluateExpression(_expression);
    notifyListeners();
  }

  /// Toggle between formula mode and calculator mode
  Future<void> toggleFormulaMode() async {
    _isInFormulaMode = !_isInFormulaMode;
    
    if (_isInFormulaMode) {
      await _loadFormulas();
    }
    
    notifyListeners();
  }

  /// Load available formulas for formula mode
  Future<void> _loadFormulas() async {
    try {
      final formulas = await FormulaService.instance.getAllFormulas();
      _availableFormulas = formulas;
    } catch (e) {
      _availableFormulas = [];
    }
  }

  /// Filter formulas based on search query
  void searchFormulas(String query) {
    _formulaSearchQuery = query;
    notifyListeners();
  }

  /// Get filtered formulas based on search query
  List<CustomFormula> get filteredFormulas {
    if (_formulaSearchQuery.isEmpty) {
      return _availableFormulas;
    }
    
    final query = _formulaSearchQuery.toLowerCase();
    return _availableFormulas.where((formula) {
      return formula.name.toLowerCase().contains(query) ||
             (formula.description?.toLowerCase().contains(query) ?? false) ||
             (formula.category?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Select a formula and insert it into the expression
  Future<void> selectFormula(CustomFormula formula) async {
    // Record usage
    await FormulaService.instance.recordFormulaUsage(formula.id!);
    
    // For simple formulas without variables, insert the formula name
    // In a full implementation, this would show a variable input dialog
    if (formula.variables.isEmpty) {
      _expression += formula.name;
      _updateExpression();
    }
    
    // Exit formula mode after selection
    _isInFormulaMode = false;
    notifyListeners();
  }

  /// Exit formula mode without selecting a formula
  void exitFormulaMode() {
    _isInFormulaMode = false;
    notifyListeners();
  }

}