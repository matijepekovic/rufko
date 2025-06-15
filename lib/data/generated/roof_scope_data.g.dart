// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/business/roof_scope_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoofScopeDataAdapter extends TypeAdapter<RoofScopeData> {
  @override
  final int typeId = 2;

  @override
  RoofScopeData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoofScopeData(
      id: fields[0] as String?,
      customerId: fields[1] as String,
      sourceFileName: fields[2] as String?,
      roofArea: fields[3] as double,
      numberOfSquares: fields[4] as double,
      pitch: fields[5] as double,
      valleyLength: fields[6] as double,
      hipLength: fields[7] as double,
      ridgeLength: fields[8] as double,
      perimeterLength: fields[9] as double,
      eaveLength: fields[10] as double,
      gutterLength: fields[11] as double,
      chimneyCount: fields[12] as int,
      skylightCount: fields[13] as int,
      flashingLength: fields[14] as double,
      additionalMeasurements: (fields[15] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RoofScopeData obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.sourceFileName)
      ..writeByte(3)
      ..write(obj.roofArea)
      ..writeByte(4)
      ..write(obj.numberOfSquares)
      ..writeByte(5)
      ..write(obj.pitch)
      ..writeByte(6)
      ..write(obj.valleyLength)
      ..writeByte(7)
      ..write(obj.hipLength)
      ..writeByte(8)
      ..write(obj.ridgeLength)
      ..writeByte(9)
      ..write(obj.perimeterLength)
      ..writeByte(10)
      ..write(obj.eaveLength)
      ..writeByte(11)
      ..write(obj.gutterLength)
      ..writeByte(12)
      ..write(obj.chimneyCount)
      ..writeByte(13)
      ..write(obj.skylightCount)
      ..writeByte(14)
      ..write(obj.flashingLength)
      ..writeByte(15)
      ..write(obj.additionalMeasurements)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoofScopeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
