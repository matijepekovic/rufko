// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/templates/email_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmailTemplateAdapter extends TypeAdapter<EmailTemplate> {
  @override
  final int typeId = 26;

  @override
  EmailTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmailTemplate(
      id: fields[0] as String?,
      templateName: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      subject: fields[4] as String,
      emailContent: fields[5] as String,
      placeholders: (fields[6] as List?)?.cast<String>(),
      isActive: fields[7] as bool,
      sortOrder: fields[8] as int,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
      isHtml: fields[11] as bool,
      userCategoryKey: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EmailTemplate obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.emailContent)
      ..writeByte(6)
      ..write(obj.placeholders)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.sortOrder)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.isHtml)
      ..writeByte(12)
      ..write(obj.userCategoryKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
