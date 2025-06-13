// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/templates/template_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemplateCategoryAdapter extends TypeAdapter<TemplateCategory> {
  @override
  final int typeId = 27;

  @override
  TemplateCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateCategory(
      id: fields[0] as String?,
      key: fields[1] as String,
      name: fields[2] as String,
      templateType: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateCategory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.key)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.templateType)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
