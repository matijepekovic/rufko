import '../../models/calculator/custom_formula.dart';
import '../../models/calculator/formula_variable.dart';
import '../database/calculator_database_service.dart';

class FormulaService {
  static final FormulaService _instance = FormulaService._internal();
  factory FormulaService() => _instance;
  FormulaService._internal();
  
  static FormulaService get instance => _instance;
  
  final _db = CalculatorDatabaseService.instance;

  /// Gets all formulas, with favorites first
  Future<List<CustomFormula>> getAllFormulas() async {
    return await _db.getAllFormulas();
  }

  /// Searches formulas by name, description, or expression
  Future<List<CustomFormula>> searchFormulas(String query) async {
    if (query.trim().isEmpty) {
      return await getAllFormulas();
    }
    return await _db.searchFormulas(query.trim());
  }

  /// Gets formulas filtered by category
  Future<List<CustomFormula>> getFormulasByCategory(String category) async {
    final allFormulas = await getAllFormulas();
    return allFormulas.where((f) => f.categoryDisplayName == category).toList();
  }

  /// Gets only favorite formulas
  Future<List<CustomFormula>> getFavoriteFormulas() async {
    final allFormulas = await getAllFormulas();
    return allFormulas.where((f) => f.isFavorite).toList();
  }

  /// Gets only global (company-wide) formulas
  Future<List<CustomFormula>> getGlobalFormulas() async {
    final allFormulas = await getAllFormulas();
    return allFormulas.where((f) => f.isGlobal).toList();
  }

  /// Creates a new formula
  Future<int> createFormula({
    required String name,
    required String expression,
    String? description,
    String? category,
    bool isGlobal = false,
    List<FormulaVariable> variables = const [],
  }) async {
    final formula = CustomFormula.create(
      name: name,
      expression: expression,
      description: description,
      category: category,
      isGlobal: isGlobal,
    );

    final formulaId = await _db.insertFormula(formula);

    // Add variables
    for (final variable in variables) {
      await _db.insertVariable(
        variable.copyWith(formulaId: formulaId),
      );
    }

    return formulaId;
  }

  /// Updates an existing formula
  Future<void> updateFormula(CustomFormula formula) async {
    await _db.updateFormula(formula);
  }

  /// Deletes a formula and all its variables
  Future<void> deleteFormula(int formulaId) async {
    await _db.deleteFormula(formulaId);
  }

  /// Toggles favorite status of a formula
  Future<void> toggleFavorite(int formulaId, bool isFavorite) async {
    await _db.toggleFavorite(formulaId, isFavorite);
  }

  /// Gets a specific formula by ID
  Future<CustomFormula?> getFormula(int id) async {
    return await _db.getFormula(id);
  }

  /// Creates a variable for a formula
  Future<int> createVariable({
    required int formulaId,
    required String name,
    double? defaultValue,
    String? description,
    String? unit,
  }) async {
    final variable = FormulaVariable.create(
      formulaId: formulaId,
      name: name,
      defaultValue: defaultValue,
      description: description,
      unit: unit,
    );

    return await _db.insertVariable(variable);
  }

  /// Updates a formula variable
  Future<void> updateVariable(FormulaVariable variable) async {
    await _db.updateVariable(variable);
  }

  /// Deletes a formula variable
  Future<void> deleteVariable(int variableId) async {
    await _db.deleteVariable(variableId);
  }

  /// Gets all variables for a formula
  Future<List<FormulaVariable>> getFormulaVariables(int formulaId) async {
    return await _db.getFormulaVariables(formulaId);
  }

  /// Validates a formula expression for syntax errors
  bool validateFormulaExpression(String expression) {
    try {
      // Basic validation - check for balanced braces
      final openBraces = '{'.allMatches(expression).length;
      final closeBraces = '}'.allMatches(expression).length;
      
      if (openBraces != closeBraces) return false;

      // Check for valid variable syntax
      final variablePattern = RegExp(r'\{([^}]+)\}');
      final matches = variablePattern.allMatches(expression);
      
      for (final match in matches) {
        final variableName = match.group(1);
        if (variableName == null || variableName.trim().isEmpty) {
          return false;
        }
        
        // Variable names should only contain letters, numbers, and underscores
        if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(variableName)) {
          return false;
        }
      }

      // Check for basic math operators
      final allowedChars = RegExp(r'^[a-zA-Z0-9_{}+\-*/().×÷\s]+$');
      if (!allowedChars.hasMatch(expression)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extracts variable names from a formula expression
  List<String> extractVariableNames(String expression) {
    final variablePattern = RegExp(r'\{([^}]+)\}');
    final matches = variablePattern.allMatches(expression);
    return matches.map((match) => match.group(1)!).toSet().toList();
  }

  /// Evaluates a formula with given variable values
  double? evaluateFormula(CustomFormula formula, Map<String, double> variableValues) {
    return formula.evaluateWithValues(variableValues);
  }

  /// Gets unique categories from all formulas
  Future<List<String>> getCategories() async {
    final formulas = await getAllFormulas();
    final categories = formulas
        .map((f) => f.categoryDisplayName)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Creates default quick conversion chips for roofing calculations
  List<QuickChip> getDefaultQuickChips() {
    return [
      QuickChip(
        label: 'ft → sq ft',
        description: 'Convert feet to square feet',
        operation: (value) => value * value,
      ),
      QuickChip(
        label: '÷100 (sq)',
        description: 'Convert sq ft to roofing squares',
        operation: (value) => value / 100,
      ),
      QuickChip(
        label: '+10% waste',
        description: 'Add 10% waste factor',
        operation: (value) => value * 1.1,
      ),
      QuickChip(
        label: '×1.15 (pitch)',
        description: 'Apply standard pitch multiplier',
        operation: (value) => value * 1.15,
      ),
      QuickChip(
        label: '×0.9 (coverage)',
        description: 'Apply coverage factor',
        operation: (value) => value * 0.9,
      ),
      QuickChip(
        label: '+5% overage',
        description: 'Add 5% material overage',
        operation: (value) => value * 1.05,
      ),
    ];
  }

  /// Duplicates a formula (useful for creating variations)
  Future<int> duplicateFormula(int originalId, {String? newName}) async {
    final original = await getFormula(originalId);
    if (original == null) throw Exception('Formula not found');

    final duplicatedName = newName ?? '${original.name} (Copy)';
    
    return await createFormula(
      name: duplicatedName,
      expression: original.expression,
      description: original.description,
      category: original.category,
      isGlobal: false, // Duplicates are always personal
      variables: original.variables,
    );
  }

  /// Records that a formula has been used (for usage tracking)
  Future<void> recordFormulaUsage(int formulaId) async {
    await _db.recordFormulaUsage(formulaId);
  }

  /// Gets the most frequently used formulas
  Future<List<CustomFormula>> getMostUsedFormulas({int limit = 10}) async {
    return await _db.getMostUsedFormulas(limit: limit);
  }

  /// Exports formulas to a map (for sharing or backup)
  Future<Map<String, dynamic>> exportFormulas(List<int> formulaIds) async {
    final formulas = <Map<String, dynamic>>[];
    
    for (final id in formulaIds) {
      final formula = await getFormula(id);
      if (formula != null) {
        formulas.add({
          'formula': formula.toMap(),
          'variables': formula.variables.map((v) => v.toMap()).toList(),
        });
      }
    }

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'formulas': formulas,
    };
  }

  /// Imports formulas from exported data
  Future<List<int>> importFormulas(Map<String, dynamic> data) async {
    final importedIds = <int>[];
    final formulas = data['formulas'] as List<dynamic>;

    for (final formulaData in formulas) {
      final formulaMap = formulaData['formula'] as Map<String, dynamic>;
      final variablesData = formulaData['variables'] as List<dynamic>;

      // Remove ID to create new formula
      formulaMap.remove('id');
      
      final formula = CustomFormula.fromMap(formulaMap);
      final formulaId = await _db.insertFormula(formula);

      // Import variables
      for (final variableData in variablesData) {
        final variableMap = Map<String, dynamic>.from(variableData);
        variableMap.remove('id');
        variableMap['formula_id'] = formulaId;
        
        final variable = FormulaVariable.fromMap(variableMap);
        await _db.insertVariable(variable);
      }

      importedIds.add(formulaId);
    }

    return importedIds;
  }
}

class QuickChip {
  final String label;
  final String description;
  final double Function(double value) operation;

  const QuickChip({
    required this.label,
    required this.description,
    required this.operation,
  });
}