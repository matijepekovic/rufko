// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/business/quote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuoteItemAdapter extends TypeAdapter<QuoteItem> {
  @override
  final int typeId = 3;

  @override
  QuoteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuoteItem(
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as double,
      unitPrice: fields[3] as double,
      unit: fields[4] as String,
      description: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QuoteItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
