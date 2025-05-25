// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simplified_quote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuoteLevelAdapter extends TypeAdapter<QuoteLevel> {
  @override
  final int typeId = 9;

  @override
  QuoteLevel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuoteLevel(
      id: fields[0] as String,
      name: fields[1] as String,
      levelNumber: fields[2] as int,
      basePrice: fields[3] as double,
      includedItems: (fields[4] as List?)?.cast<QuoteItem>(),
      subtotal: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, QuoteLevel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.levelNumber)
      ..writeByte(3)
      ..write(obj.basePrice)
      ..writeByte(4)
      ..write(obj.includedItems)
      ..writeByte(5)
      ..write(obj.subtotal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SimplifiedMultiLevelQuoteAdapter
    extends TypeAdapter<SimplifiedMultiLevelQuote> {
  @override
  final int typeId = 10;

  @override
  SimplifiedMultiLevelQuote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SimplifiedMultiLevelQuote(
      id: fields[0] as String?,
      customerId: fields[1] as String,
      roofScopeDataId: fields[2] as String?,
      quoteNumber: fields[3] as String?,
      levels: (fields[4] as List?)?.cast<QuoteLevel>(),
      addons: (fields[5] as List?)?.cast<QuoteItem>(),
      taxRate: fields[6] as double,
      discount: fields[7] as double,
      status: fields[8] as String,
      notes: fields[9] as String?,
      validUntil: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SimplifiedMultiLevelQuote obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.roofScopeDataId)
      ..writeByte(3)
      ..write(obj.quoteNumber)
      ..writeByte(4)
      ..write(obj.levels)
      ..writeByte(5)
      ..write(obj.addons)
      ..writeByte(6)
      ..write(obj.taxRate)
      ..writeByte(7)
      ..write(obj.discount)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.validUntil)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimplifiedMultiLevelQuoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
