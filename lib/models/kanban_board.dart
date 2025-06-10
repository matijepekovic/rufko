import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'kanban_stage.dart';

part 'kanban_board.g.dart';

@HiveType(typeId: 28)
class KanbanBoard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<KanbanStage> stages;

  KanbanBoard({
    String? id,
    required this.name,
    List<KanbanStage>? stages,
  })  : id = id ?? const Uuid().v4(),
        stages = stages ?? const [];

  KanbanBoard clone({String? newName}) {
    return KanbanBoard(
      name: newName ?? '${name} Copy',
      stages: stages.map((s) => s.clone()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stages': stages.map((s) => s.toMap()).toList(),
    };
  }

  factory KanbanBoard.fromMap(Map<String, dynamic> map) {
    return KanbanBoard(
      id: map['id'],
      name: map['name'] ?? 'Board',
      stages: map['stages'] != null
          ? (map['stages'] as List)
              .map((e) => KanbanStage.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
