// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/business/simplified_quote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuoteDiscountAdapter extends TypeAdapter<QuoteDiscount> {
  @override
  final int typeId = 8;

  @override
  QuoteDiscount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuoteDiscount(
      id: fields[0] as String?,
      type: fields[1] as String,
      value: fields[2] as double,
      code: fields[3] as String?,
      description: fields[4] as String?,
      applyToAddons: fields[5] as bool,
      excludedProductIds: (fields[6] as List?)?.cast<String>(),
      expiryDate: fields[7] as DateTime?,
      isActive: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, QuoteDiscount obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.code)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.applyToAddons)
      ..writeByte(6)
      ..write(obj.excludedProductIds)
      ..writeByte(7)
      ..write(obj.expiryDate)
      ..writeByte(8)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteDiscountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      baseQuantity: fields[6] as double,
      includedItems: (fields[4] as List?)?.cast<QuoteItem>(),
      subtotal: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, QuoteLevel obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.subtotal)
      ..writeByte(6)
      ..write(obj.baseQuantity);
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
      baseProductId: fields[13] as String?,
      baseProductName: fields[14] as String?,
      baseProductUnit: fields[15] as String?,
      discounts: (fields[16] as List?)?.cast<QuoteDiscount>(),
      nonDiscountableProductIds: (fields[17] as List?)?.cast<String>(),
      pdfPath: fields[18] as String?,
      pdfTemplateId: fields[19] as String?,
      pdfGeneratedAt: fields[20] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SimplifiedMultiLevelQuote obj) {
    writer
      ..writeByte(21)
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
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.baseProductId)
      ..writeByte(14)
      ..write(obj.baseProductName)
      ..writeByte(15)
      ..write(obj.baseProductUnit)
      ..writeByte(16)
      ..write(obj.discounts)
      ..writeByte(17)
      ..write(obj.nonDiscountableProductIds)
      ..writeByte(18)
      ..write(obj.pdfPath)
      ..writeByte(19)
      ..write(obj.pdfTemplateId)
      ..writeByte(20)
      ..write(obj.pdfGeneratedAt);
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
