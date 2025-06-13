// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/business/product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductLevelPriceAdapter extends TypeAdapter<ProductLevelPrice> {
  @override
  final int typeId = 7;

  @override
  ProductLevelPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductLevelPrice(
      levelId: fields[0] as String,
      levelName: fields[1] as String,
      price: fields[2] as double,
      description: fields[3] as String?,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProductLevelPrice obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.levelId)
      ..writeByte(1)
      ..write(obj.levelName)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductLevelPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 1;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String?,
      unitPrice: fields[3] as double,
      unit: fields[4] as String,
      category: fields[5] as String,
      sku: fields[6] as String?,
      isActive: fields[7] as bool,
      levelPrices: (fields[10] as Map?)?.cast<String, double>(),
      isAddon: fields[11] as bool,
      isDiscountable: fields[12] as bool,
      enhancedLevelPrices: (fields[13] as List?)?.cast<ProductLevelPrice>(),
      maxLevels: fields[14] as int,
      notes: fields[15] as String?,
      isMainDifferentiator: fields[16] as bool,
      enableLevelPricing: fields[17] as bool,
      pricingType: fields[18] as ProductPricingType?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.sku)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.levelPrices)
      ..writeByte(11)
      ..write(obj.isAddon)
      ..writeByte(12)
      ..write(obj.isDiscountable)
      ..writeByte(13)
      ..write(obj.enhancedLevelPrices)
      ..writeByte(14)
      ..write(obj.maxLevels)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.isMainDifferentiator)
      ..writeByte(17)
      ..write(obj.enableLevelPricing)
      ..writeByte(18)
      ..write(obj.pricingType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductPricingTypeAdapter extends TypeAdapter<ProductPricingType> {
  @override
  final int typeId = 19;

  @override
  ProductPricingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProductPricingType.mainDifferentiator;
      case 1:
        return ProductPricingType.subLeveled;
      case 2:
        return ProductPricingType.simple;
      default:
        return ProductPricingType.mainDifferentiator;
    }
  }

  @override
  void write(BinaryWriter writer, ProductPricingType obj) {
    switch (obj) {
      case ProductPricingType.mainDifferentiator:
        writer.writeByte(0);
        break;
      case ProductPricingType.subLeveled:
        writer.writeByte(1);
        break;
      case ProductPricingType.simple:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductPricingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
