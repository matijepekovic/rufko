// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_level_quote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LevelQuoteAdapter extends TypeAdapter<LevelQuote> {
  @override
  final int typeId = 7;

  @override
  LevelQuote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LevelQuote(
      levelId: fields[0] as String,
      levelName: fields[1] as String,
      levelNumber: fields[2] as int,
      items: (fields[3] as List?)?.cast<QuoteItem>(),
      subtotal: fields[4] as double,
      taxAmount: fields[5] as double,
      total: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LevelQuote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.levelId)
      ..writeByte(1)
      ..write(obj.levelName)
      ..writeByte(2)
      ..write(obj.levelNumber)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.subtotal)
      ..writeByte(5)
      ..write(obj.taxAmount)
      ..writeByte(6)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelQuoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MultiLevelQuoteAdapter extends TypeAdapter<MultiLevelQuote> {
  @override
  final int typeId = 8;

  @override
  MultiLevelQuote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MultiLevelQuote(
      id: fields[0] as String?,
      customerId: fields[1] as String,
      roofScopeDataId: fields[2] as String?,
      quoteNumber: fields[3] as String?,
      levels: (fields[4] as Map?)?.cast<String, LevelQuote>(),
      commonItems: (fields[5] as List?)?.cast<QuoteItem>(),
      addons: (fields[6] as List?)?.cast<QuoteItem>(),
      taxRate: fields[7] as double,
      commonSubtotal: fields[8] as double,
      discount: fields[9] as double,
      status: fields[10] as String,
      notes: fields[11] as String?,
      validUntil: fields[12] as DateTime?,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MultiLevelQuote obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.commonItems)
      ..writeByte(6)
      ..write(obj.addons)
      ..writeByte(7)
      ..write(obj.taxRate)
      ..writeByte(8)
      ..write(obj.commonSubtotal)
      ..writeByte(9)
      ..write(obj.discount)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.validUntil)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultiLevelQuoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
