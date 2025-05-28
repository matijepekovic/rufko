// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PDFTemplateAdapter extends TypeAdapter<PDFTemplate> {
  @override
  final int typeId = 21;

  @override
  PDFTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PDFTemplate(
      id: fields[0] as String?,
      templateName: fields[1] as String,
      description: fields[2] as String,
      pdfFilePath: fields[3] as String,
      templateType: fields[4] as String,
      pageWidth: fields[5] as double,
      pageHeight: fields[6] as double,
      totalPages: fields[7] as int,
      fieldMappings: (fields[8] as List?)?.cast<FieldMapping>(),
      isActive: fields[9] as bool,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      metadata: (fields[12] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, PDFTemplate obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.pdfFilePath)
      ..writeByte(4)
      ..write(obj.templateType)
      ..writeByte(5)
      ..write(obj.pageWidth)
      ..writeByte(6)
      ..write(obj.pageHeight)
      ..writeByte(7)
      ..write(obj.totalPages)
      ..writeByte(8)
      ..write(obj.fieldMappings)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FieldMappingAdapter extends TypeAdapter<FieldMapping> {
  @override
  final int typeId = 20;

  @override
  FieldMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FieldMapping(
      fieldId: fields[0] as String?,
      fieldType: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      width: fields[4] as double,
      height: fields[5] as double,
      fontFamily: fields[6] as String,
      fontSize: fields[7] as double,
      fontColor: fields[8] as String,
      isBold: fields[9] as bool,
      isItalic: fields[10] as bool,
      alignment: fields[11] as String,
      placeholder: fields[12] as String?,
      additionalProperties: (fields[13] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, FieldMapping obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.fieldId)
      ..writeByte(1)
      ..write(obj.fieldType)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.width)
      ..writeByte(5)
      ..write(obj.height)
      ..writeByte(6)
      ..write(obj.fontFamily)
      ..writeByte(7)
      ..write(obj.fontSize)
      ..writeByte(8)
      ..write(obj.fontColor)
      ..writeByte(9)
      ..write(obj.isBold)
      ..writeByte(10)
      ..write(obj.isItalic)
      ..writeByte(11)
      ..write(obj.alignment)
      ..writeByte(12)
      ..write(obj.placeholder)
      ..writeByte(13)
      ..write(obj.additionalProperties);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldMappingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
