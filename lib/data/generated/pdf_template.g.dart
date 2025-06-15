// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/templates/pdf_template.dart';

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
      userCategoryKey: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PDFTemplate obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.metadata)
      ..writeByte(13)
      ..write(obj.userCategoryKey);
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
      appDataType: fields[1] as String,
      pdfFormFieldName: fields[2] as String,
      detectedPdfFieldType: fields[3] as PdfFormFieldType,
      visualX: fields[4] as double?,
      visualY: fields[5] as double?,
      visualWidth: fields[6] as double?,
      visualHeight: fields[7] as double?,
      pageNumber: fields[8] as int,
      fontFamilyOverride: fields[9] as String?,
      fontSizeOverride: fields[10] as double?,
      fontColorOverride: fields[11] as String?,
      alignmentOverride: fields[12] as String?,
      additionalProperties: (fields[14] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, FieldMapping obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.fieldId)
      ..writeByte(1)
      ..write(obj.appDataType)
      ..writeByte(2)
      ..write(obj.pdfFormFieldName)
      ..writeByte(3)
      ..write(obj.detectedPdfFieldType)
      ..writeByte(4)
      ..write(obj.visualX)
      ..writeByte(5)
      ..write(obj.visualY)
      ..writeByte(6)
      ..write(obj.visualWidth)
      ..writeByte(7)
      ..write(obj.visualHeight)
      ..writeByte(8)
      ..write(obj.pageNumber)
      ..writeByte(9)
      ..write(obj.fontFamilyOverride)
      ..writeByte(10)
      ..write(obj.fontSizeOverride)
      ..writeByte(11)
      ..write(obj.fontColorOverride)
      ..writeByte(12)
      ..write(obj.alignmentOverride)
      ..writeByte(14)
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
