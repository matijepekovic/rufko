// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_board.dart';

class KanbanBoardAdapter extends TypeAdapter<KanbanBoard> {
  @override
  final int typeId = 28;

  @override
  KanbanBoard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KanbanBoard(
      id: fields[0] as String?,
      name: fields[1] as String,
      stages: (fields[2] as List).cast<KanbanStage>(),
    );
  }

  @override
  void write(BinaryWriter writer, KanbanBoard obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.stages);
  }
}
