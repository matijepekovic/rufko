class CalculatorExpression {
  final String expression;
  final double? result;
  final bool isValid;
  final String? error;
  final int cursorPosition;
  final List<ExpressionToken> tokens;

  const CalculatorExpression({
    required this.expression,
    this.result,
    required this.isValid,
    this.error,
    this.cursorPosition = 0,
    this.tokens = const [],
  });

  CalculatorExpression copyWith({
    String? expression,
    double? result,
    bool? isValid,
    String? error,
    int? cursorPosition,
    List<ExpressionToken>? tokens,
  }) {
    return CalculatorExpression(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      isValid: isValid ?? this.isValid,
      error: error ?? this.error,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      tokens: tokens ?? this.tokens,
    );
  }

  String get formattedResult {
    if (result == null) return '';
    if (result!.isNaN || result!.isInfinite) return 'Error';
    
    // Remove unnecessary decimal places
    if (result! == result!.roundToDouble()) {
      return result!.round().toString();
    }
    return result!.toStringAsFixed(2).replaceAll(RegExp(r'\.?0*$'), '');
  }

  bool get hasResult => result != null && !result!.isNaN && !result!.isInfinite;
}

class ExpressionToken {
  final String value;
  final TokenType type;
  final int startIndex;
  final int endIndex;

  const ExpressionToken({
    required this.value,
    required this.type,
    required this.startIndex,
    required this.endIndex,
  });
}

enum TokenType {
  number,
  operator,
  parenthesis,
  variable,
  function,
  error,
}