// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/settings/custom_app_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomAppDataFieldAdapter extends TypeAdapter<CustomAppDataField> {
  @override
  final int typeId = 12;

  @override
  CustomAppDataField read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomAppDataField(
      id: fields[0] as String?,
      fieldName: fields[1] as String,
      displayName: fields[2] as String,
      fieldType: fields[3] as String,
      currentValue: fields[4] as String,
      category: fields[5] as String,
      isRequired: fields[6] as bool,
      placeholder: fields[7] as String?,
      description: fields[8] as String?,
      sortOrder: fields[9] as int,
      dropdownOptions: (fields[12] as List?)?.cast<String>(),
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomAppDataField obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fieldName)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.fieldType)
      ..writeByte(4)
      ..write(obj.currentValue)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.isRequired)
      ..writeByte(7)
      ..write(obj.placeholder)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.sortOrder)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.dropdownOptions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomAppDataFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
