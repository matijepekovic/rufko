// lib/models/pdf_template.dart (HIVE ANNOTATIONS REMOVED)

import 'package:uuid/uuid.dart';
import '../business/product.dart';
import '../ui/field_definition.dart';

enum PdfFormFieldType {
  unknown,
  textBox,
  checkBox,
  radioButtonGroup,
  comboBox,
  listBox,
  signatureField,
}

class PDFTemplate {
  late String id;
  late String templateName;
  late String description;
  late String pdfFilePath;
  late String templateType;
  late double pageWidth;
  late double pageHeight;
  late int totalPages;
  late List<FieldMapping> fieldMappings;
  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;
  late Map<String, dynamic> metadata;
  String? userCategoryKey; // Stores the key of the TemplateCategory

  PDFTemplate({
    String? id,
    required this.templateName,
    this.description = '',
    required this.pdfFilePath,
    this.templateType = 'quote',
    required this.pageWidth,
    required this.pageHeight,
    this.totalPages = 1,
    List<FieldMapping>? fieldMappings,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    this.userCategoryKey, //
  }) {
    this.id = id ?? const Uuid().v4();
    this.fieldMappings = fieldMappings ?? [];
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.metadata = metadata ?? {};
  }

  void addField(FieldMapping field) {
    fieldMappings.add(field);
    updatedAt = DateTime.now();
  }

  void removeField(String fieldId) {
    fieldMappings.removeWhere((f) => f.fieldId == fieldId);
    updatedAt = DateTime.now();
  }

  void updateField(FieldMapping field) {
    final index = fieldMappings.indexWhere((f) => f.fieldId == field.fieldId);
    if (index != -1) {
      fieldMappings[index] = field;
      updatedAt = DateTime.now();
    }
  }

  FieldMapping? getField(String fieldId) {
    try {
      return fieldMappings.firstWhere((f) => f.fieldId == fieldId);
    } catch (e) {
      return null;
    }
  }

  /// Return a combined list of all built-in, product and custom field definitions.
  static List<FieldDefinition> getFieldDefinitions([
    List<Product>? availableProducts,
    List<dynamic>? customAppDataFields,
  ]) {
    final defs = <FieldDefinition>[...generateBaseFieldDefinitions()];

    if (availableProducts != null && availableProducts.isNotEmpty) {
      for (final product in availableProducts) {
        final safeName = _createSafeFieldName(product.name);
        final category =
            product.category.isEmpty ? 'Products' : '🏠 ${product.category}';
        defs.addAll([
          FieldDefinition(
              appDataType: '${safeName}Name',
              displayName: '${product.name} Product Name',
              category: category,
              source: 'product.${product.id}.name'),
          FieldDefinition(
              appDataType: '${safeName}Qty',
              displayName: '${product.name} Product Quantity',
              category: category,
              source: 'product.${product.id}.quantity'),
          FieldDefinition(
              appDataType: '${safeName}UnitPrice',
              displayName: '${product.name} Product Unit Price',
              category: category,
              source: 'product.${product.id}.unitPrice'),
          FieldDefinition(
              appDataType: '${safeName}Total',
              displayName: '${product.name} Product Total',
              category: category,
              source: 'product.${product.id}.total'),
          FieldDefinition(
              appDataType: '${safeName}Description',
              displayName: '${product.name} Product Description',
              category: category,
              source: 'product.${product.id}.description'),
        ]);
      }
    }

    if (customAppDataFields != null && customAppDataFields.isNotEmpty) {
      for (final field in customAppDataFields) {
        final String fieldName;
        final String displayName;
        final String category;
        if (field is Map<String, dynamic>) {
          fieldName = field['fieldName'] as String? ?? '';
          displayName = field['displayName'] as String? ?? fieldName;
          category = field['category'] as String? ?? 'Fields';
        } else {
          fieldName = field.fieldName;
          displayName = field.displayName;
          category = field.category;
        }
        if (fieldName.isNotEmpty) {
          defs.add(FieldDefinition(
              appDataType: fieldName,
              displayName: displayName,
              category: category,
              source: 'custom.$fieldName'));
        }
      }
    }

    return defs;
  }

  // 🔧 Helper method to create safe field names
  static String _createSafeFieldName(String productName) {
    return productName
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '') // Remove spaces
        .replaceAllMapped(RegExp(r'^\w'), (match) => match.group(0)!.toLowerCase()) // First letter lowercase
        .replaceAllMapped(RegExp(r'\s\w'), (match) => match.group(0)!.toUpperCase().replaceAll(' ', '')); // Camel case
  }

  /// Categorize field definitions for UI presentation.
  static Map<String, List<String>> getCategorizedQuoteFieldTypes([
    List<Product>? availableProducts,
    List<dynamic>? customFields,
  ]) {
    final defs = getFieldDefinitions(availableProducts, customFields);
    final Map<String, List<String>> map = {};
    for (final def in defs) {
      map.putIfAbsent(def.category, () => []).add(def.appDataType);
    }
    return map;
  }


  /// Display name helper for UI elements.
  static String getFieldDisplayName(String appDataType,
      [List<dynamic>? customAppDataFields]) {
    final defs = getFieldDefinitions(null, customAppDataFields);
    final match = defs.firstWhere(
        (d) => d.appDataType == appDataType,
        orElse: () => FieldDefinition(
            appDataType: appDataType,
            displayName: appDataType,
            category: '',
            source: ''));
    return match.displayName;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateName': templateName,
      'description': description,
      'pdfFilePath': pdfFilePath,
      'templateType': templateType,
      'pageWidth': pageWidth,
      'pageHeight': pageHeight,
      'totalPages': totalPages,
      'fieldMappings': fieldMappings.map((f) => f.toMap()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'userCategoryKey': userCategoryKey,
    };
  }

  static PDFTemplate fromMap(Map<String, dynamic> map) {
    return PDFTemplate(
      id: map['id'],
      templateName: map['templateName'] ?? '',
      description: map['description'] ?? '',
      pdfFilePath: map['pdfFilePath'] ?? '',
      templateType: map['templateType'] ?? 'quote',
      pageWidth: map['pageWidth']?.toDouble() ?? 0.0,
      pageHeight: map['pageHeight']?.toDouble() ?? 0.0,
      totalPages: map['totalPages']?.toInt() ?? 1,
      fieldMappings: (map['fieldMappings'] as List<dynamic>?)
          ?.map((item) => FieldMapping.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      userCategoryKey: map['userCategoryKey'] as String?,
    );
  }

  // 🔧 FIXED: Clone method with no (Copy) suffix
  PDFTemplate clone({bool preserveId = false}) {
    return PDFTemplate(
      id: preserveId ? id : Uuid().v4(),
      templateName: templateName, // 🔧 Remove the (Copy) addition
      description: description,
      pdfFilePath: pdfFilePath,
      templateType: templateType,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      totalPages: totalPages,
      fieldMappings: fieldMappings.map((fm) => FieldMapping(
        appDataType: fm.appDataType,
        pdfFormFieldName: fm.pdfFormFieldName,
        detectedPdfFieldType: fm.detectedPdfFieldType,
        visualX: fm.visualX,
        visualY: fm.visualY,
        visualWidth: fm.visualWidth,
        visualHeight: fm.visualHeight,
        pageNumber: fm.pageNumber,
        fontFamilyOverride: fm.fontFamilyOverride,
        fontSizeOverride: fm.fontSizeOverride,
        fontColorOverride: fm.fontColorOverride,
        alignmentOverride: fm.alignmentOverride,
        //defaultValue: fm.defaultValue,
        //overrideValueEnabled: fm.overrideValueEnabled, // Clone this new field
        additionalProperties: Map<String, dynamic>.from(fm.additionalProperties),
      )).toList(),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: Map<String, dynamic>.from(metadata),
      userCategoryKey: userCategoryKey,
    );
  }

  @override
  String toString() {
    return 'PDFTemplate(id: $id, name: $templateName, type: $templateType, userCategoryKey: $userCategoryKey, fields: ${fieldMappings.length})';
  }
}

class FieldMapping {
  late String fieldId;
  late String appDataType;
  late String pdfFormFieldName;
  late PdfFormFieldType detectedPdfFieldType;
  double? visualX;
  double? visualY;
  double? visualWidth;
  double? visualHeight;
  late int pageNumber;
  String? fontFamilyOverride;
  double? fontSizeOverride;
  String? fontColorOverride;
  String? alignmentOverride;
  late Map<String, dynamic> additionalProperties;

  FieldMapping({
    String? fieldId,
    required this.appDataType,
    required this.pdfFormFieldName,
    this.detectedPdfFieldType = PdfFormFieldType. unknown,
    this.visualX,
    this.visualY,
    this.visualWidth,
    this.visualHeight,
    this.pageNumber = 0,
    this.fontFamilyOverride,
    this.fontSizeOverride,
    this.fontColorOverride,
    this.alignmentOverride,
    //this.defaultValue,
    Map<String, dynamic>? additionalProperties,
    //bool? overrideValueEnabled, // New constructor parameter
  }) {
    this.fieldId = fieldId ?? const Uuid().v4();
    this.additionalProperties = additionalProperties ?? {};
    //this.overrideValueEnabled = overrideValueEnabled ?? false; // Default to false
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'appDataType': appDataType,
      'pdfFormFieldName': pdfFormFieldName,
      'detectedPdfFieldType': detectedPdfFieldType.index,
      'visualX': visualX,
      'visualY': visualY,
      'visualWidth': visualWidth,
      'visualHeight': visualHeight,
      'pageNumber': pageNumber,
      'fontFamilyOverride': fontFamilyOverride,
      'fontSizeOverride': fontSizeOverride,
      'fontColorOverride': fontColorOverride,
      'alignmentOverride': alignmentOverride,
      //'defaultValue': defaultValue,
      'additionalProperties': additionalProperties,
      //'overrideValueEnabled': overrideValueEnabled, // Add to map
    };
  }

  static FieldMapping fromMap(Map<String, dynamic> map) {
    String appDataTypeValue = map['appDataType'] ?? map['fieldType'] ?? '';
    String pdfFormFieldNameValue = map['pdfFormFieldName'] ?? '';
    PdfFormFieldType detectedTypeValue = map['detectedPdfFieldType'] != null
        ? PdfFormFieldType.values[map['detectedPdfFieldType'] as int]
        : PdfFormFieldType. unknown;

    return FieldMapping(
      fieldId: map['fieldId'],
      appDataType: appDataTypeValue,
      pdfFormFieldName: pdfFormFieldNameValue,
      detectedPdfFieldType: detectedTypeValue,
      visualX: map['visualX']?.toDouble() ?? map['x']?.toDouble(),
      visualY: map['visualY']?.toDouble() ?? map['y']?.toDouble(),
      visualWidth: map['visualWidth']?.toDouble() ?? map['width']?.toDouble(),
      visualHeight: map['visualHeight']?.toDouble() ?? map['height']?.toDouble(),
      pageNumber: map['pageNumber']?.toInt() ?? 0,
      fontFamilyOverride: map['fontFamilyOverride'] ?? map['fontFamily'],
      fontSizeOverride: map['fontSizeOverride']?.toDouble() ?? map['fontSize']?.toDouble(),
      fontColorOverride: map['fontColorOverride'] ?? map['fontColor'],
      alignmentOverride: map['alignmentOverride'] ?? map['alignment'],
      //defaultValue: map['defaultValue'] ?? map['placeholder'],
      additionalProperties: Map<String, dynamic>.from(map['additionalProperties'] ?? {}),
      //overrideValueEnabled: map['overrideValueEnabled'] as bool? ?? false, // Parse from map, default to false
    );
  }

  @override
  String toString() {
    return 'FieldMapping(id: $fieldId, appData: $appDataType, pdfField: $pdfFormFieldName, type: $detectedPdfFieldType)';
  }
}

// Removed PdfFormFieldTypeAdapter - no longer needed without Hive