import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'kanban_stage.g.dart';

@HiveType(typeId: 29)
class KanbanStage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int color;

  KanbanStage({
    String? id,
    required this.name,
    int? color,
  })  : id = id ?? const Uuid().v4(),
        color = color ?? Colors.blue.value;

  KanbanStage clone({String? newName}) {
    return KanbanStage(
      name: newName ?? name,
      color: color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  factory KanbanStage.fromMap(Map<String, dynamic> map) {
    return KanbanStage(
      id: map['id'],
      name: map['name'] ?? '',
      color: map['color'] ?? Colors.blue.value,
    );
  }
}
