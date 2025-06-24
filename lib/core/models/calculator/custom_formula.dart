import 'formula_variable.dart';

class CustomFormula {
  final int? id;
  final String name;
  final String expression;
  final String? description;
  final bool isGlobal;
  final bool isFavorite;
  final String? category;
  final int orderIndex;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FormulaVariable> variables;

  const CustomFormula({
    this.id,
    required this.name,
    required this.expression,
    this.description,
    this.isGlobal = false,
    this.isFavorite = false,
    this.category,
    this.orderIndex = 0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.variables = const [],
  });

  factory CustomFormula.create({
    required String name,
    required String expression,
    String? description,
    bool isGlobal = false,
    String? category,
    String? createdBy,
  }) {
    final now = DateTime.now();
    return CustomFormula(
      name: name,
      expression: expression,
      description: description,
      isGlobal: isGlobal,
      category: category,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CustomFormula.fromMap(Map<String, dynamic> map, {List<FormulaVariable>? variables}) {
    return CustomFormula(
      id: map['id'] as int?,
      name: map['name'] as String,
      expression: map['expression'] as String,
      description: map['description'] as String?,
      isGlobal: (map['is_global'] as int) == 1,
      isFavorite: (map['is_favorite'] as int) == 1,
      category: map['category'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      variables: variables ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'expression': expression,
      'description': description,
      'is_global': isGlobal ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'category': category,
      'order_index': orderIndex,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CustomFormula copyWith({
    int? id,
    String? name,
    String? expression,
    String? description,
    bool? isGlobal,
    bool? isFavorite,
    String? category,
    int? orderIndex,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FormulaVariable>? variables,
  }) {
    return CustomFormula(
      id: id ?? this.id,
      name: name ?? this.name,
      expression: expression ?? this.expression,
      description: description ?? this.description,
      isGlobal: isGlobal ?? this.isGlobal,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      orderIndex: orderIndex ?? this.orderIndex,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      variables: variables ?? this.variables,
    );
  }

  String get displayExpression {
    // Show a simplified version of the expression for preview
    String preview = expression;
    
    // Replace variable placeholders with readable names
    for (final variable in variables) {
      preview = preview.replaceAll(variable.placeholder, variable.name);
    }
    
    // Truncate if too long
    if (preview.length > 30) {
      preview = '${preview.substring(0, 27)}...';
    }
    
    return preview;
  }

  List<String> get variablePlaceholders {
    final RegExp variableRegex = RegExp(r'\{([^}]+)\}');
    final matches = variableRegex.allMatches(expression);
    return matches.map((match) => match.group(0)!).toSet().toList();
  }

  bool get hasVariables => variablePlaceholders.isNotEmpty;

  String get categoryDisplayName => category?.isNotEmpty == true ? category! : 'General';

  bool containsVariable(String variableName) {
    return expression.contains('{$variableName}');
  }

  double? evaluateWithValues(Map<String, double> variableValues) {
    try {
      String evaluateExpression = expression;
      
      // Replace all variables with their values
      for (final entry in variableValues.entries) {
        evaluateExpression = evaluateExpression.replaceAll(
          '{${entry.key}}', 
          entry.value.toString(),
        );
      }
      
      // Use default values for missing variables
      for (final variable in variables) {
        if (!variableValues.containsKey(variable.name) && variable.defaultValue != null) {
          evaluateExpression = evaluateExpression.replaceAll(
            variable.placeholder,
            variable.defaultValue.toString(),
          );
        }
      }
      
      // If there are still placeholders, we can't evaluate
      if (evaluateExpression.contains(RegExp(r'\{[^}]+\}'))) {
        return null;
      }
      
      // This would need a proper expression evaluator
      // For now, return null as placeholder
      return null;
    } catch (e) {
      return null;
    }
  }
}