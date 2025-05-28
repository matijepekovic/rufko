// lib/models/pdf_template.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'pdf_template.g.dart';

@HiveType(typeId: 21) // Fixed: Use unique typeId
class PDFTemplate extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String templateName;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late String pdfFilePath;

  @HiveField(4)
  late String templateType; // 'quote', 'invoice', 'estimate'

  @HiveField(5)
  late double pageWidth;

  @HiveField(6)
  late double pageHeight;

  @HiveField(7)
  late int totalPages;

  @HiveField(8)
  late List<FieldMapping> fieldMappings;

  @HiveField(9)
  late bool isActive;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  late DateTime updatedAt;

  @HiveField(12)
  late Map<String, dynamic> metadata;

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
  }) {
    this.id = id ?? const Uuid().v4();
    this.fieldMappings = fieldMappings ?? [];
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.metadata = metadata ?? {};
  }

  // Field management methods
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

  // Available field types for quotes
  static List<String> getQuoteFieldTypes() {
    return [
      'customerName',
      'customerAddress',
      'customerPhone',
      'customerEmail',
      'companyName',
      'companyAddress',
      'companyPhone',
      'companyEmail',
      'quoteNumber',
      'quoteDate',
      'validUntil',
      'quoteStatus',
      'levelName',
      'levelPrice',
      'itemName',
      'itemQuantity',
      'itemUnitPrice',
      'itemTotal',
      'subtotal',
      'taxRate',
      'taxAmount',
      'discount',
      'grandTotal',
      'notes',
      'terms',
    ];
  }

  // Get display name for field type
  static String getFieldDisplayName(String fieldType) {
    final names = {
      'customerName': 'Customer Name',
      'customerAddress': 'Customer Address',
      'customerPhone': 'Customer Phone',
      'customerEmail': 'Customer Email',
      'companyName': 'Company Name',
      'companyAddress': 'Company Address',
      'companyPhone': 'Company Phone',
      'companyEmail': 'Company Email',
      'quoteNumber': 'Quote Number',
      'quoteDate': 'Quote Date',
      'validUntil': 'Valid Until',
      'quoteStatus': 'Quote Status',
      'levelName': 'Level Name',
      'levelPrice': 'Level Price',
      'itemName': 'Item Name',
      'itemQuantity': 'Item Quantity',
      'itemUnitPrice': 'Item Unit Price',
      'itemTotal': 'Item Total',
      'subtotal': 'Subtotal',
      'taxRate': 'Tax Rate',
      'taxAmount': 'Tax Amount',
      'discount': 'Discount',
      'grandTotal': 'Grand Total',
      'notes': 'Notes',
      'terms': 'Terms & Conditions',
    };
    return names[fieldType] ?? fieldType;
  }

  // Serialization methods
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
          .toList() ?? [],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'PDFTemplate(id: $id, name: $templateName, fields: ${fieldMappings.length})';
  }
}

@HiveType(typeId: 20) // Fixed: Use unique typeId
class FieldMapping extends HiveObject {
  @HiveField(0)
  late String fieldId;

  @HiveField(1)
  late String fieldType;

  @HiveField(2)
  late double x; // Relative position (0.0 - 1.0)

  @HiveField(3)
  late double y; // Relative position (0.0 - 1.0)

  @HiveField(4)
  late double width; // Relative width (0.0 - 1.0)

  @HiveField(5)
  late double height; // Relative height (0.0 - 1.0)

  @HiveField(6)
  late String fontFamily;

  @HiveField(7)
  late double fontSize;

  @HiveField(8)
  late String fontColor;

  @HiveField(9)
  late bool isBold;

  @HiveField(10)
  late bool isItalic;

  @HiveField(11)
  late String alignment; // 'left', 'center', 'right'

  @HiveField(12)
  String? placeholder;

  @HiveField(13)
  late Map<String, dynamic> additionalProperties;

  FieldMapping({
    String? fieldId,
    required this.fieldType,
    this.x = 0.0,
    this.y = 0.0,
    this.width = 0.2,
    this.height = 0.05,
    this.fontFamily = 'Arial',
    this.fontSize = 12.0,
    this.fontColor = '#000000',
    this.isBold = false,
    this.isItalic = false,
    this.alignment = 'left',
    this.placeholder,
    Map<String, dynamic>? additionalProperties,
  }) {
    this.fieldId = fieldId ?? const Uuid().v4();
    this.additionalProperties = additionalProperties ?? {};
  }

  // Serialization methods
  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'fieldType': fieldType,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontColor': fontColor,
      'isBold': isBold,
      'isItalic': isItalic,
      'alignment': alignment,
      'placeholder': placeholder,
      'additionalProperties': additionalProperties,
    };
  }

  static FieldMapping fromMap(Map<String, dynamic> map) {
    return FieldMapping(
      fieldId: map['fieldId'],
      fieldType: map['fieldType'] ?? '',
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      width: map['width']?.toDouble() ?? 0.2,
      height: map['height']?.toDouble() ?? 0.05,
      fontFamily: map['fontFamily'] ?? 'Arial',
      fontSize: map['fontSize']?.toDouble() ?? 12.0,
      fontColor: map['fontColor'] ?? '#000000',
      isBold: map['isBold'] ?? false,
      isItalic: map['isItalic'] ?? false,
      alignment: map['alignment'] ?? 'left',
      placeholder: map['placeholder'],
      additionalProperties: Map<String, dynamic>.from(map['additionalProperties'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'FieldMapping(id: $fieldId, type: $fieldType, pos: ($x, $y))';
  }
}