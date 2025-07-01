class FormulaVariable {
  final int? id;
  final int formulaId;
  final String name;
  final double? defaultValue;
  final String? description;
  final String? unit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FormulaVariable({
    this.id,
    required this.formulaId,
    required this.name,
    this.defaultValue,
    this.description,
    this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FormulaVariable.create({
    required int formulaId,
    required String name,
    double? defaultValue,
    String? description,
    String? unit,
  }) {
    final now = DateTime.now();
    return FormulaVariable(
      formulaId: formulaId,
      name: name,
      defaultValue: defaultValue,
      description: description,
      unit: unit,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory FormulaVariable.fromMap(Map<String, dynamic> map) {
    return FormulaVariable(
      id: map['id'] as int?,
      formulaId: map['formula_id'] as int,
      name: map['name'] as String,
      defaultValue: map['default_value'] as double?,
      description: map['description'] as String?,
      unit: map['unit'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'formula_id': formulaId,
      'name': name,
      'default_value': defaultValue,
      'description': description,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FormulaVariable copyWith({
    int? id,
    int? formulaId,
    String? name,
    double? defaultValue,
    String? description,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FormulaVariable(
      id: id ?? this.id,
      formulaId: formulaId ?? this.formulaId,
      name: name ?? this.name,
      defaultValue: defaultValue ?? this.defaultValue,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get placeholder => '{$name}';
  
  String get displayName {
    if (description != null && description!.isNotEmpty) {
      return '$name - $description';
    }
    return name;
  }

  String get formattedDefaultValue {
    if (defaultValue == null) return '';
    if (defaultValue! == defaultValue!.roundToDouble()) {
      return defaultValue!.round().toString();
    }
    return defaultValue!.toString();
  }
}