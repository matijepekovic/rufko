// lib/models/template_category.dart (HIVE ANNOTATIONS REMOVED)

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class TemplateCategory {
  final String id;
  final String key;
  final String name;
  final String templateType;
  final DateTime createdAt;
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
    String? id = map['id'] is String ? map['id'] as String : null;
    String? key = map['key'] is String ? map['key'] as String : null;
    String? name = map['name'] is String ? map['name'] as String : null;
    String? templateType = map['templateType'] is String ? map['templateType'] as String : null;

    DateTime createdAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        try {
          createdAt = DateTime.parse(map['createdAt'] as String);
        } catch (e) {
          if (kDebugMode) {
            debugPrint("Error parsing createdAt string: ${map['createdAt']}. Using current time. Error: $e");
          }
          createdAt = DateTime.now();
        }
      } else if (map['createdAt'] is DateTime) {
        createdAt = map['createdAt'] as DateTime;
      } else {
        if (kDebugMode) {
          debugPrint("Unexpected type for createdAt: ${map['createdAt'].runtimeType}. Using current time.");
        }
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    if (map['updatedAt'] != null) {
      if (map['updatedAt'] is String) {
        try {
          updatedAt = DateTime.parse(map['updatedAt'] as String);
        } catch (e) {
          if (kDebugMode) {
            debugPrint("Error parsing updatedAt string: ${map['updatedAt']}. Using current time. Error: $e");
          }
          updatedAt = DateTime.now();
        }
      } else if (map['updatedAt'] is DateTime) {
        updatedAt = map['updatedAt'] as DateTime;
      } else {
        if (kDebugMode) {
          debugPrint("Unexpected type for updatedAt: ${map['updatedAt'].runtimeType}. Using current time.");
        }
        updatedAt = DateTime.now();
      }
    } else {
      updatedAt = DateTime.now();
    }

    if (key == null || name == null || templateType == null) {
      String missingFields = [
        if (key == null) 'key',
        if (name == null) 'name',
        if (templateType == null) 'templateType'
      ].join(', ');
      final errorMessage = "TemplateCategory.fromMap: Critical fields missing ($missingFields) in map: $map. Providing defaults.";
      if (kDebugMode) {
        debugPrint("ERROR: $errorMessage");
      }
    }

    return TemplateCategory(
      id: id, // The constructor handles null ID by generating a new one
      key: key ?? 'error_key_${const Uuid().v4().substring(0, 8)}',
      name: name ?? 'Error Name',
      templateType: templateType ?? 'error_type',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }


  @override
  String toString() {
    return 'TemplateCategory(id: $id, key: $key, name: $name, type: $templateType)';
  }
}