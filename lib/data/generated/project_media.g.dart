// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/media/project_media.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectMediaAdapter extends TypeAdapter<ProjectMedia> {
  @override
  final int typeId = 5;

  @override
  ProjectMedia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectMedia(
      id: fields[0] as String?,
      customerId: fields[1] as String,
      quoteId: fields[2] as String?,
      filePath: fields[3] as String,
      fileName: fields[4] as String,
      fileType: fields[5] as String,
      description: fields[6] as String?,
      tags: (fields[7] as List?)?.cast<String>(),
      category: fields[8] as String,
      fileSizeBytes: fields[9] as int?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectMedia obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.quoteId)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.fileName)
      ..writeByte(5)
      ..write(obj.fileType)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.fileSizeBytes)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
