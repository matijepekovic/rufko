// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/templates/message_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageTemplateAdapter extends TypeAdapter<MessageTemplate> {
  @override
  final int typeId = 25;

  @override
  MessageTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageTemplate(
      id: fields[0] as String?,
      templateName: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      messageContent: fields[4] as String,
      placeholders: (fields[5] as List?)?.cast<String>(),
      isActive: fields[6] as bool,
      sortOrder: fields[7] as int,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      userCategoryKey: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageTemplate obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.messageContent)
      ..writeByte(5)
      ..write(obj.placeholders)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.sortOrder)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.userCategoryKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
