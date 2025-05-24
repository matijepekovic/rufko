// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      isActive: fields[7] != null ? fields[7] as bool : true,
      definesLevel: fields[10] != null ? fields[10] as bool : false,
      levelName: fields[11] as String?,
      levelNumber: fields[12] as int?,
      levelPrices: (fields[13] as Map?)?.cast<String, double>(),
      isUpgrade: fields[14] != null ? fields[14] as bool : false,
      isAddon: fields[15] != null ? fields[15] as bool : false,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.definesLevel)
      ..writeByte(11)
      ..write(obj.levelName)
      ..writeByte(12)
      ..write(obj.levelNumber)
      ..writeByte(13)
      ..write(obj.levelPrices)
      ..writeByte(14)
      ..write(obj.isUpgrade)
      ..writeByte(15)
      ..write(obj.isAddon);
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
