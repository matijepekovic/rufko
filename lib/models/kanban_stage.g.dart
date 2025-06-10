// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_stage.dart';

class KanbanStageAdapter extends TypeAdapter<KanbanStage> {
  @override
  final int typeId = 29;

  @override
  KanbanStage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KanbanStage(
      id: fields[0] as String?,
      name: fields[1] as String,
      color: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, KanbanStage obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color);
  }
}
