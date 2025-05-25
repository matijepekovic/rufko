// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      id: fields[0] as String?,
      productCategories: (fields[1] as List?)?.cast<String>(),
      productUnits: (fields[2] as List?)?.cast<String>(),
      defaultUnit: fields[3] as String?,
      defaultQuoteLevelNames: (fields[5] as List?)?.cast<String>(),
      taxRate: fields[6] as double,
      companyName: fields[7] as String?,
      companyAddress: fields[8] as String?,
      companyPhone: fields[9] as String?,
      companyEmail: fields[10] as String?,
      companyLogoPath: fields[11] as String?,
      updatedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productCategories)
      ..writeByte(2)
      ..write(obj.productUnits)
      ..writeByte(3)
      ..write(obj.defaultUnit)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.defaultQuoteLevelNames)
      ..writeByte(6)
      ..write(obj.taxRate)
      ..writeByte(7)
      ..write(obj.companyName)
      ..writeByte(8)
      ..write(obj.companyAddress)
      ..writeByte(9)
      ..write(obj.companyPhone)
      ..writeByte(10)
      ..write(obj.companyEmail)
      ..writeByte(11)
      ..write(obj.companyLogoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
