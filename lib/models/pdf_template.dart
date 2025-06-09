// lib/models/pdf_template.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'product.dart'; // 🔧 ADDED IMPORT FOR PRODUCT
import '../utils/common_utils.dart';

part 'pdf_template.g.dart'; // This will be regenerated

// @HiveType(typeId: 22) // Keep this commented out if using manual adapter
enum PdfFormFieldType {
  @HiveField(0)
   unknown,
  @HiveField(1)
  textBox,
  @HiveField(2)
  checkBox,
  @HiveField(3)
  radioButtonGroup,
  @HiveField(4)
  comboBox,
  @HiveField(5)
  listBox,
  @HiveField(6)
  signatureField,
}

@HiveType(typeId: 21)
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
  late String templateType;
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
  @HiveField(13)
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
    if(isInBox) save();
  }

  void removeField(String fieldId) {
    fieldMappings.removeWhere((f) => f.fieldId == fieldId);
    updatedAt = DateTime.now();
    if(isInBox) save();
  }

  void updateField(FieldMapping field) {
    final index = fieldMappings.indexWhere((f) => f.fieldId == field.fieldId);
    if (index != -1) {
      fieldMappings[index] = field;
      updatedAt = DateTime.now();
      if(isInBox) save();
    }
  }

  FieldMapping? getField(String fieldId) {
    try {
      return fieldMappings.firstWhere((f) => f.fieldId == fieldId);
    } catch (e) {
      return null;
    }
  }

  // 🚀 NEW: Dynamic field generation method
  static List<String> getQuoteFieldTypes([List<Product>? availableProducts]) {
    final baseFields = [
      // Customer fields
      'customerName',
      'customerStreetAddress',
      'customerCity',
      'customerState',
      'customerZipCode',
      'customerFullAddress',
      'customerPhone',
      'customerEmail',

      // Company fields
      'companyName',
      'companyAddress',
      'companyPhone',
      'companyEmail',

      // Quote basic fields
      'quoteNumber',
      'quoteDate',
      'validUntil',
      'quoteStatus',
      'todaysDate',

      // Level 1 (Builder Grade) fields
      'level1Name',
      'level1Subtotal',
      'level1Tax',
      'level1TotalWithTax',

      // Level 2 (Homeowner Grade) fields
      'level2Name',
      'level2Subtotal',
      'level2Tax',
      'level2TotalWithTax',

      // Level 3 (Platinum Preferred) fields
      'level3Name',
      'level3Subtotal',
      'level3Tax',
      'level3TotalWithTax',

      // Totals and calculations
      'subtotal',
      'taxRate',
      'taxAmount',
      'discount',
      'grandTotal',

      // Text fields
      'notes',
      'terms',
      'upgradeQuoteText',

    ];

    // 🚀 Generate dynamic product fields
    final productFields = <String>[];

    if (availableProducts != null && availableProducts.isNotEmpty) {
      for (final product in availableProducts) {
        // Create safe field name from product name
        final safeProductName = _createSafeFieldName(product.name);

        // Generate 5 fields for each product
        productFields.addAll([
          '${safeProductName}Name',
          '${safeProductName}Qty',
          '${safeProductName}UnitPrice',
          '${safeProductName}Total',
          '${safeProductName}Description',
        ]);
      }
    }


    return [...baseFields, ...productFields];
  }

  // 🔧 Helper method to create safe field names
  static String _createSafeFieldName(String productName) {
    return productName
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '') // Remove spaces
        .replaceAllMapped(RegExp(r'^\w'), (match) => match.group(0)!.toLowerCase()) // First letter lowercase
        .replaceAllMapped(RegExp(r'\s\w'), (match) => match.group(0)!.toUpperCase().replaceAll(' ', '')); // Camel case
  }

  // 🚀 NEW: Get categorized field types for organized UI (FIXED VERSION)
  // 🚀 NEW: Get categorized field types for organized UI (WITH CUSTOM FIELDS INTEGRATION)
  static Map<String, List<String>> getCategorizedQuoteFieldTypes([List<Product>? availableProducts]) {
    final categories = <String, List<String>>{
      'Customer Information': [
        'customerName', 'customerStreetAddress', 'customerCity', 'customerState',
        'customerZipCode', 'customerFullAddress', 'customerPhone', 'customerEmail'
      ],

      'Company Information': [
        'companyName', 'companyAddress', 'companyPhone', 'companyEmail'
      ],

      'Quote Information': [
        'quoteNumber', 'quoteDate', 'validUntil', 'quoteStatus', 'todaysDate'
      ],

      'Quote Levels (3 levels)': [
        'level1Name', 'level1Subtotal', 'level1Tax', 'level1TotalWithTax',
        'level2Name', 'level2Subtotal', 'level2Tax', 'level2TotalWithTax',
        'level3Name', 'level3Subtotal', 'level3Tax', 'level3TotalWithTax'
      ],

      'Calculations & Totals': [
        'subtotal', 'taxRate', 'taxAmount', 'discount', 'grandTotal'
      ],

      'Text & Notes': [
        'notes', 'terms', 'upgradeQuoteText'
      ],

      'Custom Fields': [
        'customText1', 'customText2', 'customText3',
        'customNumeric1', 'customNumeric2',
        'customDate1', 'customDate2',
        'customBoolean1_for_checkbox', 'customBoolean2_for_checkbox'
      ],
    };

    // 🚀 Add product categories dynamically
    if (availableProducts != null && availableProducts.isNotEmpty) {
      final productsByCategory = <String, List<Product>>{};

      for (final product in availableProducts) {
        final category = product.category.isEmpty ? 'Other' : product.category;
        productsByCategory.putIfAbsent(category, () => []).add(product);
      }

      productsByCategory.forEach((categoryName, products) {
        final categoryFields = <String>[];

        for (final product in products) {
          final safeProductName = _createSafeFieldName(product.name);
          categoryFields.addAll([
            '${safeProductName}Name',
            '${safeProductName}Qty',
            '${safeProductName}UnitPrice',
            '${safeProductName}Total',
          ]);
        }

        categories['🏠 $categoryName (${products.length} products)'] = categoryFields;
      });
    } else {
      categories['Products (Legacy - 5 slots)'] = [
        'product1Name', 'product1Qty', 'product1UnitPrice', 'product1Total',
        'product2Name', 'product2Qty', 'product2UnitPrice', 'product2Total',
        'product3Name', 'product3Qty', 'product3UnitPrice', 'product3Total',
        'product4Name', 'product4Qty', 'product4UnitPrice', 'product4Total',
        'product5Name', 'product5Qty', 'product5UnitPrice', 'product5Total',
      ];
    }

    return categories;
  }

// 🚀 NEW: Enhanced method that includes custom app data fields
  static Map<String, List<String>> getCategorizedQuoteFieldTypesWithCustomFields(
      List<Product>? availableProducts,
      List<dynamic>? customAppDataFields, // Accept dynamic list from provider
      ) {
    // Start with base categories
    final categories = getCategorizedQuoteFieldTypes(availableProducts);

    // Process custom app data fields if provided
    if (customAppDataFields != null && customAppDataFields.isNotEmpty) {
      final customFieldsByCategory = <String, List<String>>{};

      // Group custom fields by their categories
      for (final field in customAppDataFields) {
        // Handle both CustomAppDataField objects and Map representations
        final String categoryKey;
        final String fieldName;

        if (field is Map<String, dynamic>) {
          categoryKey = field['category'] as String? ?? 'custom';
          fieldName = field['fieldName'] as String? ?? '';
        } else {
          // Assume it has category, fieldName, and displayName properties
          categoryKey = field.category as String? ?? 'custom';
          fieldName = field.fieldName as String? ?? '';
        }

        if (fieldName.isNotEmpty) {
          customFieldsByCategory.putIfAbsent(categoryKey, () => []).add(fieldName);
        }
      }

      // Category mapping: map custom categories to existing ones
      final categoryMappings = {
        'company': 'Company Information',
        'contact': 'Contact Information', // Will create new if doesn't exist
        'legal': 'Legal Information',
        'pricing': 'Pricing Information',
        'custom': 'Fields',
      };

      // Process each custom field category
      customFieldsByCategory.forEach((customCategoryKey, customFields) {
        final targetCategoryName =
            categoryMappings[customCategoryKey] ??
                formatCategoryName(customCategoryKey);

        // Check if target category already exists (case-insensitive)
        String? existingCategoryKey;
        for (final existingKey in categories.keys) {
          if (existingKey.toLowerCase().contains(
              targetCategoryName.toLowerCase()) ||
              targetCategoryName.toLowerCase().contains(
                  existingKey.toLowerCase().replaceAll(
                      RegExp(r'[^\w\s]'), ''))) {
            existingCategoryKey = existingKey;
            break;
          }
        }

        if (existingCategoryKey != null) {
          // Merge into existing category, but avoid duplicates
          final existingFields = categories[existingCategoryKey]!;
          for (final customField in customFields) {
            if (!existingFields.contains(customField)) {
              existingFields.add(customField);
            }
          }
        } else {
          // Create new category
          categories[targetCategoryName] = customFields;
        }
      });

    }

    return categories;
  }


  // 🚀 UPDATED: Enhanced getFieldDisplayName method to handle dynamic product names
  // 🚀 UPDATED: Enhanced getFieldDisplayName method to handle custom fields
  static String getFieldDisplayName(String appDataType, [List<dynamic>? customAppDataFields]) {
    final names = {
      // Customer fields
      'customerName': 'Customer Name',
      'customerStreetAddress': 'Customer Street',
      'customerCity': 'Customer City',
      'customerState': 'Customer State/Pr.',
      'customerZipCode': 'Customer Zip/Postal',
      'customerFullAddress': 'Customer Full Address',
      'customerPhone': 'Customer Phone',
      'customerEmail': 'Customer Email',

      // Company fields
      'companyName': 'Company Name',
      'companyAddress': 'Company Address',
      'companyPhone': 'Company Phone',
      'companyEmail': 'Company Email',

      // Quote basic fields
      'quoteNumber': 'Quote Number',
      'quoteDate': 'Quote Date',
      'validUntil': 'Valid Until',
      'quoteStatus': 'Quote Status',
      'todaysDate': 'Today\'s Date',

      // Level fields (simplified)
      'level1Name': 'Level 1 Name', 'level1Subtotal': 'Level 1 Subtotal',
      'level1Tax': 'Level 1 Tax', 'level1TotalWithTax': 'Level 1 Total',
      'level2Name': 'Level 2 Name', 'level2Subtotal': 'Level 2 Subtotal',
      'level2Tax': 'Level 2 Tax', 'level2TotalWithTax': 'Level 2 Total',
      'level3Name': 'Level 3 Name', 'level3Subtotal': 'Level 3 Subtotal',
      'level3Tax': 'Level 3 Tax', 'level3TotalWithTax': 'Level 3 Total',

      // Legacy product fields
      'product1Name': 'Product 1 Name', 'product1Qty': 'Product 1 Qty',
      'product1UnitPrice': 'Product 1 Unit Price', 'product1Total': 'Product 1 Total',
      'product2Name': 'Product 2 Name', 'product2Qty': 'Product 2 Qty',
      'product2UnitPrice': 'Product 2 Unit Price', 'product2Total': 'Product 2 Total',
      'product3Name': 'Product 3 Name', 'product3Qty': 'Product 3 Qty',
      'product3UnitPrice': 'Product 3 Unit Price', 'product3Total': 'Product 3 Total',
      'product4Name': 'Product 4 Name', 'product4Qty': 'Product 4 Qty',
      'product4UnitPrice': 'Product 4 Unit Price', 'product4Total': 'Product 4 Total',
      'product5Name': 'Product 5 Name', 'product5Qty': 'Product 5 Qty',
      'product5UnitPrice': 'Product 5 Unit Price', 'product5Total': 'Product 5 Total',

      // Totals and calculations
      'subtotal': 'Subtotal', 'discount': 'Discount', 'grandTotal': 'Grand Total',
      'taxRate': 'Tax Rate (%)', 'taxAmount': 'Tax Amount',

      // Text fields
      'notes': 'Notes/Scope', 'terms': 'Terms & Conditions',
      'upgradeQuoteText': 'Upgrade Quote Details',

      // Custom fields
      'customText1': 'Custom Text 1', 'customText2': 'Custom Text 2', 'customText3': 'Custom Text 3',
      'customNumeric1': 'Custom Numeric 1', 'customNumeric2': 'Custom Numeric 2',
      'customDate1': 'Custom Date 1', 'customDate2': 'Custom Date 2',
      'customBoolean1_for_checkbox': 'Custom Checkbox 1', 'customBoolean2_for_checkbox': 'Custom Checkbox 2'
    };

    // First check if it's a known static field
    if (names.containsKey(appDataType)) {
      return names[appDataType]!;
    }

    // 🚀 Check custom app data fields
    if (customAppDataFields != null) {
      for (final field in customAppDataFields) {
        final String fieldName;
        final String currentValue;

        if (field is Map<String, dynamic>) {
          fieldName = field['fieldName'] as String? ?? '';
          currentValue = field['currentValue'] as String? ?? '';
        } else {
          fieldName = field.fieldName as String? ?? '';
          currentValue = field.currentValue as String? ?? '';
        }

        if (fieldName == appDataType) {
          // Show field name + value if value exists, otherwise just field name
          if (currentValue.isNotEmpty) {
            return '$fieldName: $currentValue';
          } else {
            return fieldName;
          }
        }
      }
    }

    // Handle dynamic product field names
    if (appDataType.endsWith('Name')) {
      final productName = appDataType.substring(0, appDataType.length - 4);
      return '$productName - Name';
    } else if (appDataType.endsWith('Qty')) {
      final productName = appDataType.substring(0, appDataType.length - 3);
      return '$productName - Quantity';
    } else if (appDataType.endsWith('UnitPrice')) {
      final productName = appDataType.substring(0, appDataType.length - 9);
      return '$productName - Unit Price';
    } else if (appDataType.endsWith('Total')) {
      final productName = appDataType.substring(0, appDataType.length - 5);
      return '$productName - Total';
    }

    // Fallback: Convert camelCase to readable format
    String pretty = appDataType.replaceAllMapped(RegExp(r'[A-Z]'), (Match m) => ' ${m.group(0)}');
    return pretty.trim();
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

@HiveType(typeId: 20)
class FieldMapping extends HiveObject {
  @HiveField(0)
  late String fieldId;
  @HiveField(1)
  late String appDataType;
  @HiveField(2)
  late String pdfFormFieldName;
  @HiveField(3)
  late PdfFormFieldType detectedPdfFieldType;
  @HiveField(4)
  double? visualX;
  @HiveField(5)
  double? visualY;
  @HiveField(6)
  double? visualWidth;
  @HiveField(7)
  double? visualHeight;
  @HiveField(8)
  late int pageNumber;
  @HiveField(9)
  String? fontFamilyOverride;
  @HiveField(10)
  double? fontSizeOverride;
  @HiveField(11)
  String? fontColorOverride;
  @HiveField(12)
  String? alignmentOverride;
  //@HiveField(13)
  //String? defaultValue; // This will store the "override value"
  @HiveField(14)
  late Map<String, dynamic> additionalProperties;
  //@HiveField(15) // New field for the override toggle
  //late bool overrideValueEnabled;

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

class PdfFormFieldTypeAdapter extends TypeAdapter<PdfFormFieldType> {
  @override
  final int typeId = 22;

  @override
  PdfFormFieldType read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < PdfFormFieldType.values.length) {
      return PdfFormFieldType.values[index];
    }
    return PdfFormFieldType. unknown;
  }

  @override
  void write(BinaryWriter writer, PdfFormFieldType obj) {
    writer.writeByte(obj.index);
  }
}