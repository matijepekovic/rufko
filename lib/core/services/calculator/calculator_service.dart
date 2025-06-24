import '../../models/calculator/calculator_expression.dart';

class CalculatorService {
  static const double _maxValue = 999999999.0;
  static const double _minValue = -999999999.0;

  /// Evaluates a mathematical expression and returns the result
  static CalculatorExpression evaluateExpression(String expression) {
    try {
      // Clean the expression
      final cleanExpression = _cleanExpression(expression);
      
      if (cleanExpression.isEmpty) {
        return CalculatorExpression(
          expression: expression,
          isValid: true,
        );
      }

      // Tokenize and validate
      final tokens = _tokenize(cleanExpression);
      final validationResult = _validateTokens(tokens);
      
      if (!validationResult.isValid) {
        return CalculatorExpression(
          expression: expression,
          isValid: false,
          error: validationResult.error,
          tokens: tokens,
        );
      }

      // Evaluate the expression
      final result = _evaluate(tokens);
      
      // Check for valid result
      if (result.isNaN || result.isInfinite) {
        return CalculatorExpression(
          expression: expression,
          isValid: false,
          error: 'Invalid calculation',
          tokens: tokens,
        );
      }

      // Check bounds
      if (result > _maxValue || result < _minValue) {
        return CalculatorExpression(
          expression: expression,
          isValid: false,
          error: 'Result too large',
          tokens: tokens,
        );
      }

      return CalculatorExpression(
        expression: expression,
        result: result,
        isValid: true,
        tokens: tokens,
      );
    } catch (e) {
      return CalculatorExpression(
        expression: expression,
        isValid: false,
        error: 'Calculation error',
      );
    }
  }

  /// Adds an operator to the expression at the cursor position
  static String addOperator(String expression, String operator, int cursorPosition) {
    // Don't add operator to empty expression
    if (expression.isEmpty) return expression;
    
    // Replace if last character is already an operator
    if (expression.isNotEmpty && _isOperator(expression[expression.length - 1])) {
      return expression.substring(0, expression.length - 1) + operator;
    }
    
    // Add operator at cursor position or end
    if (cursorPosition >= expression.length) {
      return expression + operator;
    }
    
    return expression.substring(0, cursorPosition) + 
           operator + 
           expression.substring(cursorPosition);
  }

  /// Adds a number to the expression with smart default replacement
  /// If current expression is "1" or "0", replace it entirely with the new number
  static String addNumber(String expression, String number, int cursorPosition) {
    // Handle smart replacement for default values
    if (expression == '1' || expression == '0') {
      return number;
    }
    
    // For other cases, append the number at cursor position
    if (cursorPosition <= 0) {
      return number + expression;
    }
    if (cursorPosition >= expression.length) {
      return expression + number;
    }
    
    return expression.substring(0, cursorPosition) + 
           number + 
           expression.substring(cursorPosition);
  }

  /// Removes the last character from the expression
  static String backspace(String expression) {
    if (expression.isEmpty) return expression;
    return expression.substring(0, expression.length - 1);
  }

  /// Clears the entire expression
  static String clear() {
    return '';
  }


  /// Formats a number for display in the calculator
  static String formatNumber(double number) {
    if (number.isNaN || number.isInfinite) return 'Error';
    
    // Remove unnecessary decimal places
    if (number == number.roundToDouble()) {
      return number.round().toString();
    }
    
    // Show up to 8 decimal places, removing trailing zeros
    return number.toStringAsFixed(8).replaceAll(RegExp(r'\.?0*$'), '');
  }

  /// Checks if a character is an operator
  static bool _isOperator(String char) {
    return ['+', '-', '−', '×', '÷', '*', '/', '='].contains(char);
  }

  /// Cleans the expression by replacing display operators with calculation operators
  static String _cleanExpression(String expression) {
    return expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')  // Replace Unicode minus with ASCII minus
        .replaceAll(' ', '');
  }

  /// Tokenizes the expression into numbers, operators, and parentheses
  static List<ExpressionToken> _tokenize(String expression) {
    final tokens = <ExpressionToken>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      final startIndex = i - buffer.length;
      
      if (_isNumber(char) || char == '.') {
        buffer.write(char);
      } else {
        // Flush number buffer
        if (buffer.isNotEmpty) {
          tokens.add(ExpressionToken(
            value: buffer.toString(),
            type: TokenType.number,
            startIndex: startIndex,
            endIndex: i - 1,
          ));
          buffer.clear();
        }
        
        // Add operator or parenthesis
        if (_isOperator(char)) {
          tokens.add(ExpressionToken(
            value: char,
            type: TokenType.operator,
            startIndex: i,
            endIndex: i,
          ));
        } else if (char == '(' || char == ')') {
          tokens.add(ExpressionToken(
            value: char,
            type: TokenType.parenthesis,
            startIndex: i,
            endIndex: i,
          ));
        }
      }
    }
    
    // Flush final number buffer
    if (buffer.isNotEmpty) {
      tokens.add(ExpressionToken(
        value: buffer.toString(),
        type: TokenType.number,
        startIndex: expression.length - buffer.length,
        endIndex: expression.length - 1,
      ));
    }
    
    return tokens;
  }

  /// Validates the tokens for syntax errors
  static ValidationResult _validateTokens(List<ExpressionToken> tokens) {
    if (tokens.isEmpty) {
      return const ValidationResult(isValid: true);
    }

    // Check for invalid number formats
    for (final token in tokens) {
      if (token.type == TokenType.number) {
        if (double.tryParse(token.value) == null) {
          return ValidationResult(
            isValid: false,
            error: 'Invalid number: ${token.value}',
          );
        }
      }
    }

    // Check for consecutive operators
    for (int i = 0; i < tokens.length - 1; i++) {
      if (tokens[i].type == TokenType.operator && 
          tokens[i + 1].type == TokenType.operator) {
        return const ValidationResult(
          isValid: false,
          error: 'Consecutive operators not allowed',
        );
      }
    }

    // Check parentheses balance
    int parenCount = 0;
    for (final token in tokens) {
      if (token.type == TokenType.parenthesis) {
        if (token.value == '(') {
          parenCount++;
        } else {
          parenCount--;
          if (parenCount < 0) {
            return const ValidationResult(
              isValid: false,
              error: 'Mismatched parentheses',
            );
          }
        }
      }
    }
    
    if (parenCount != 0) {
      return const ValidationResult(
        isValid: false,
        error: 'Unmatched parentheses',
      );
    }

    return const ValidationResult(isValid: true);
  }

  /// Evaluates the tokenized expression using order of operations
  static double _evaluate(List<ExpressionToken> tokens) {
    // Convert to postfix notation (Reverse Polish Notation)
    final postfix = _toPostfix(tokens);
    
    // Evaluate postfix expression
    final stack = <double>[];
    
    for (final token in postfix) {
      if (token.type == TokenType.number) {
        stack.add(double.parse(token.value));
      } else if (token.type == TokenType.operator) {
        if (stack.length < 2) throw Exception('Invalid expression');
        
        final b = stack.removeLast();
        final a = stack.removeLast();
        
        switch (token.value) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) throw Exception('Division by zero');
            stack.add(a / b);
            break;
          default:
            throw Exception('Unknown operator: ${token.value}');
        }
      }
    }
    
    if (stack.length != 1) throw Exception('Invalid expression');
    return stack.first;
  }

  /// Converts infix notation to postfix notation using Shunting Yard algorithm
  static List<ExpressionToken> _toPostfix(List<ExpressionToken> tokens) {
    final output = <ExpressionToken>[];
    final operators = <ExpressionToken>[];
    
    for (final token in tokens) {
      if (token.type == TokenType.number) {
        output.add(token);
      } else if (token.type == TokenType.operator) {
        while (operators.isNotEmpty &&
               operators.last.type == TokenType.operator &&
               _getPrecedence(operators.last.value) >= _getPrecedence(token.value)) {
          output.add(operators.removeLast());
        }
        operators.add(token);
      } else if (token.value == '(') {
        operators.add(token);
      } else if (token.value == ')') {
        while (operators.isNotEmpty && operators.last.value != '(') {
          output.add(operators.removeLast());
        }
        if (operators.isNotEmpty) operators.removeLast(); // Remove '('
      }
    }
    
    while (operators.isNotEmpty) {
      output.add(operators.removeLast());
    }
    
    return output;
  }

  /// Gets the precedence of an operator
  static int _getPrecedence(String operator) {
    switch (operator) {
      case '+':
      case '-':
        return 1;
      case '*':
      case '/':
        return 2;
      default:
        return 0;
    }
  }

  /// Checks if a character is a number
  static bool _isNumber(String char) {
    return RegExp(r'[0-9]').hasMatch(char);
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({
    required this.isValid,
    this.error,
  });
}