// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/business/customer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 0;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      id: fields[0] as String?,
      name: fields[1] as String,
      phone: fields[2] as String?,
      email: fields[3] as String?,
      notes: fields[5] as String?,
      communicationHistory: (fields[6] as List?)?.cast<String>(),
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
      streetAddress: fields[9] as String?,
      city: fields[10] as String?,
      stateAbbreviation: fields[11] as String?,
      zipCode: fields[12] as String?,
      inspectionData: (fields[13] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.communicationHistory)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.streetAddress)
      ..writeByte(10)
      ..write(obj.city)
      ..writeByte(11)
      ..write(obj.stateAbbreviation)
      ..writeByte(12)
      ..write(obj.zipCode)
      ..writeByte(13)
      ..write(obj.inspectionData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
