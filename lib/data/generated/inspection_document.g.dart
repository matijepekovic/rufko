// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/media/inspection_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InspectionDocumentAdapter extends TypeAdapter<InspectionDocument> {
  @override
  final int typeId = 15;

  @override
  InspectionDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionDocument(
      id: fields[0] as String?,
      customerId: fields[1] as String,
      type: fields[2] as String,
      title: fields[3] as String,
      content: fields[4] as String?,
      filePath: fields[5] as String?,
      sortOrder: fields[6] as int,
      quoteId: fields[9] as String?,
      fileSizeBytes: fields[10] as int?,
      tags: (fields[11] as List?)?.cast<String>(),
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InspectionDocument obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.filePath)
      ..writeByte(6)
      ..write(obj.sortOrder)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.quoteId)
      ..writeByte(10)
      ..write(obj.fileSizeBytes)
      ..writeByte(11)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
