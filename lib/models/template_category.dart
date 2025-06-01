// lib/models/template_category.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'template_category.g.dart';

@HiveType(typeId: 27)
class TemplateCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String key;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String templateType;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  TemplateCategory({
    String? id,
    required this.key,
    required this.name,
    required this.templateType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TemplateCategory copyWith({
    String? key,
    String? name,
    String? templateType,
    DateTime? updatedAt,
  }) {
    return TemplateCategory(
      id: id,
      key: key ?? this.key,
      name: name ?? this.name,
      templateType: templateType ?? this.templateType,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'templateType': templateType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TemplateCategory.fromMap(Map<String, dynamic> map) {
    return TemplateCategory(
      id: map['id'],
      key: map['key'] ?? '',
      name: map['name'] ?? '',
      templateType: map['templateType'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TemplateCategory(id: $id, key: $key, name: $name, type: $templateType)';
  }
}