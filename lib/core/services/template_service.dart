// lib/services/template_service.dart

import 'dart:io';
// For Uint8List - Keep this, it's used for bytes.
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// Syncfusion PDF library for reading/writing existing PDF forms
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

// Your models
import '../../data/models/templates/pdf_template.dart';
import '../../data/models/business/customer.dart';
import '../../data/models/business/simplified_quote.dart';
import '../../data/models/business/quote.dart' as legacy_quote_model;
import '../../data/models/business/product.dart';
import 'database/database_service.dart';

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static TemplateService get instance => _instance;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  Future<PDFTemplate?> createTemplateFromPDF(String uploadedPdfPath, String templateName) async {
    try {
      final file = File(uploadedPdfPath);
      if (!await file.exists()) {
        throw Exception('Uploaded PDF file not found: $uploadedPdfPath');
      }

      final bytes = await file.readAsBytes();
      syncfusion.PdfDocument? document;
      List<Map<String, dynamic>> detectedPdfFieldsInfo = [];
      List<FieldMapping> initialFieldMappings = [];

      try {
        document = syncfusion.PdfDocument(inputBytes: bytes);

        final page = document.pages[0];
        final pageWidth = page.size.width;
        final pageHeight = page.size.height;
        final totalPages = document.pages.count;

        if (kDebugMode) {
          debugPrint('📄 PDF Template Analysis for: $templateName');
          debugPrint('   Original Path: $uploadedPdfPath');
          debugPrint('   Pages: $totalPages');
          // FIX: Removed unnecessary braces
          debugPrint('   First Page Size: ${pageWidth.toStringAsFixed(1)} x ${pageHeight.toStringAsFixed(1)} pts');
        }

        // FIX: Simplified null check for form and fields
        if (document.form.fields.count > 0) {
          if (kDebugMode) {
            // FIX: Removed unnecessary braces
            debugPrint('   Found ${document.form.fields.count} potential form fields in PDF.');
          }
          for (int i = 0; i < document.form.fields.count; i++) {
            // FIX: Removed '!' as fields collection is not null if form is not null
            final field = document.form.fields[i];
            final fieldName = field.name ?? 'unnamed_field_$i';

            // FIX for pageIndex: PdfPage an index property or can be found via indexOf
            // PdfField has a .page property which is a PdfPage object.
            int pageIndex = 0; // Default
            if (field.page != null) {
              pageIndex = document.pages.indexOf(field.page!); // field.page is non-null if field.page != null
            } else {
              if (kDebugMode) debugPrint("Warning: Could not determine page for field ${field.name}. Defaulting to page 0.");
            }
            if (pageIndex < 0) pageIndex = 0; // Ensure it's a valid index

            final fieldBounds = field.bounds;

            final syncPage = document.pages[pageIndex]; // Use the determined pageIndex
            final sPageWidth = syncPage.size.width;
            final sPageHeight = syncPage.size.height;

            final relativeX = fieldBounds.left / sPageWidth;
            final relativeY = fieldBounds.top / sPageHeight;
            final relativeWidth = fieldBounds.width / sPageWidth;
            final relativeHeight = fieldBounds.height / sPageHeight;

            PdfFormFieldType detectedType = PdfFormFieldType.unknown;
            if (field is syncfusion.PdfTextBoxField) {
              detectedType = PdfFormFieldType.textBox;
            } else if (field is syncfusion.PdfCheckBoxField) {
              detectedType = PdfFormFieldType.checkBox;
            } else if (field is syncfusion.PdfRadioButtonListField) {
              detectedType = PdfFormFieldType.radioButtonGroup;
            } else if (field is syncfusion.PdfComboBoxField) {
              detectedType = PdfFormFieldType.comboBox;
            } else if (field is syncfusion.PdfListBoxField) {
              detectedType = PdfFormFieldType.listBox;
            } else if (field is syncfusion.PdfSignatureField) {
              detectedType = PdfFormFieldType.signatureField;
            }

            detectedPdfFieldsInfo.add({
              'name': fieldName,
              'type': detectedType.toString(),
              'page': pageIndex,
              'rect': [fieldBounds.left, fieldBounds.top, fieldBounds.width, fieldBounds.height],
              'relativeRect': [relativeX, relativeY, relativeWidth, relativeHeight]
            });

            initialFieldMappings.add(FieldMapping(
              appDataType: 'unmapped_${fieldName.replaceAll(RegExp(r'[^\w]'), '')}',
              pdfFormFieldName: fieldName,
              detectedPdfFieldType: detectedType,
              visualX: relativeX,
              visualY: relativeY,
              visualWidth: relativeWidth,
              visualHeight: relativeHeight,
              pageNumber: pageIndex,
            ));

            if (kDebugMode) {
              // FIX: Typo 'AcroForm', unnecessary braces
              debugPrint('     - Detected: "$fieldName" (Type: $detectedType, Page: $pageIndex, Bounds: $fieldBounds)');
            }
          }
        } else {
          if (kDebugMode) debugPrint('   No AcroForm fields detected in this PDF.');
        }

        final appDir = await getApplicationDocumentsDirectory();
        final templatesDir = Directory('${appDir.path}/templates');
        if (!await templatesDir.exists()) {
          await templatesDir.create(recursive: true);
        }

        final sanitizedTemplateName = templateName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
        final newFileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedTemplateName.pdf';
        final newPath = '${templatesDir.path}/$newFileName';
        final newFile = await file.copy(newPath);

        final template = PDFTemplate(
          templateName: templateName,
          description: 'Imported from ${file.path.split('/').last}',
          pdfFilePath: newFile.path,
          pageWidth: pageWidth,
          pageHeight: pageHeight,
          totalPages: totalPages,
          fieldMappings: initialFieldMappings,
          metadata: {
            'originalFileName': file.path.split('/').last,
            'importedAt': DateTime.now().toIso8601String(),
            'fileSize': bytes.length,
            'detectedPdfFields': detectedPdfFieldsInfo,
          },
        );

        await DatabaseService.instance.savePDFTemplate(template);
        if (kDebugMode) debugPrint('✅ PDFTemplate object created and saved: ${template.templateName}');
        return template;

      } finally {
        document?.dispose();
      }

    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in createTemplateFromPDF: $e');
      rethrow;
    }
  }

  Future<String> generatePDFFromTemplate({
    required PDFTemplate template,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    try {
      final templateFile = File(template.pdfFilePath);
      if (!await templateFile.exists()) {
        throw Exception('Template PDF file not found: ${template.pdfFilePath}');
      }

      final templateBytes = await templateFile.readAsBytes();
      final syncfusion.PdfDocument document = syncfusion.PdfDocument(inputBytes: templateBytes);
      final customAppDataFields = await DatabaseService.instance.getAllCustomAppDataFields();
      final dataMap = await _prepareDataMap(quote, customer, selectedLevelId, customData, customAppDataFields);

      // Fill PDF form fields with data
      if (document.form.fields.count > 0) {
        for (final FieldMapping mapping in template.fieldMappings) {
          final pdfFieldName = mapping.pdfFormFieldName;
          if (pdfFieldName.isEmpty) continue;

          // Simple: just get value from dataMap
          final valueToFill = dataMap[mapping.appDataType] ?? '';

          try {
            syncfusion.PdfField? fieldToUpdate;
            for (int i = 0; i < document.form.fields.count; i++) {
              if (document.form.fields[i].name == pdfFieldName) {
                fieldToUpdate = document.form.fields[i];
                break;
              }
            }

            if (fieldToUpdate != null) {
              if (fieldToUpdate is syncfusion.PdfTextBoxField) {
                fieldToUpdate.text = valueToFill;
              } else if (fieldToUpdate is syncfusion.PdfCheckBoxField) {
                bool isChecked = valueToFill.toLowerCase() == 'true' ||
                    valueToFill == '1' ||
                    valueToFill.toLowerCase() == 'yes' ||
                    valueToFill.toLowerCase() == 'on';
                fieldToUpdate.isChecked = isChecked;
              } else if (fieldToUpdate is syncfusion.PdfRadioButtonListField) {
                int selectedIdx = -1;
                for (int j = 0; j < fieldToUpdate.items.count; j++) {
                  final item = fieldToUpdate.items[j];
                  if (item.value == valueToFill) {
                    selectedIdx = j;
                    break;
                  }
                }
                if (selectedIdx != -1) {
                  fieldToUpdate.selectedIndex = selectedIdx;
                }
              } else if (fieldToUpdate is syncfusion.PdfComboBoxField) {
                fieldToUpdate.selectedValue = valueToFill;
              }
            }
          } catch (e) {
            if (kDebugMode) debugPrint('Error setting PDF field "$pdfFieldName": $e');
          }
        }
      }

      final List<int> populatedPdfBytes = document.saveSync();
      document.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final outputFileName = 'populated_${template.templateName.replaceAll(RegExp(r'[^\w\s-]'), '')}_${quote.quoteNumber.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';
      final outputFile = File('${directory.path}/$outputFileName');
      await outputFile.writeAsBytes(populatedPdfBytes);

      return outputFile.path;

    } catch (e) {
      if (kDebugMode) debugPrint('Error in generatePDFFromTemplate: $e');
      rethrow;
    }
  }

  Future<String> generateTemplatePreview(PDFTemplate template) async {
    if (kDebugMode) {
      debugPrint('🎬 PREVIEW DEBUG START');
      debugPrint('   Template: ${template.templateName}');
      debugPrint('   Template mappings: ${template.fieldMappings.length}');
      for (final mapping in template.fieldMappings) {
        debugPrint('      - ${mapping.appDataType} → ${mapping.pdfFormFieldName}');
      }
    }

    final sampleCustomer = Customer(
      name: '[Customer Name]',
      streetAddress: '[123 Sample St]',
      city: '[Sampleville]',
      stateAbbreviation: '[ST]',
      zipCode: '[00000]',
      phone: '[Customer Phone]',
      email: '[customer@email.com]',
    );

    final sampleQuote = SimplifiedMultiLevelQuote(
      customerId: 'sample_customer_id',
      quoteNumber: '[Quote Number]',
      levels: [
        QuoteLevel(id: 'level1', name: '[Builder Grade]', levelNumber: 1, basePrice: 1234.56, baseQuantity: 1.0),
        QuoteLevel(id: 'level2', name: '[Homeowner Grade]', levelNumber: 2, basePrice: 2468.99, baseQuantity: 1.0),
        QuoteLevel(id: 'level3', name: '[Platinum Preferred]', levelNumber: 3, basePrice: 3702.45, baseQuantity: 1.0),
      ],
      addons: [
        legacy_quote_model.QuoteItem(productId: 'addon1', productName: '[Addon Item Name]', quantity: 2, unitPrice: 50.0, unit: 'each')
      ],
      taxRate: 7.5,
      createdAt: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 30)),
      status: 'DRAFT',
    );

    if (sampleQuote.levels.isNotEmpty) {
      sampleQuote.levels.first.calculateSubtotal();
    }

    final customData = <String, String>{
      'preview_mode': 'true',
      'watermark_text': 'TEMPLATE PREVIEW',
    };

    if (kDebugMode) {
      debugPrint('📋 SAMPLE DATA DEBUG:');
      debugPrint('   Customer name: ${sampleCustomer.name}');
      debugPrint('   Quote number: ${sampleQuote.quoteNumber}');
      debugPrint('   Level 1 name: ${sampleQuote.levels.first.name}');
      debugPrint('   Level 1 base price: ${sampleQuote.levels.first.basePrice}');
      debugPrint('   Custom data: $customData');
      debugPrint('👁️ Generating preview for template: ${template.templateName}');
    }

    return generatePDFFromTemplate(
      template: template,
      quote: sampleQuote,
      customer: sampleCustomer,
      selectedLevelId: sampleQuote.levels.isNotEmpty ? sampleQuote.levels.first.id : null,
      customData: customData,
    );
  }

  Future<Map<String, String>> _prepareDataMap(
      SimplifiedMultiLevelQuote quote,
      Customer customer,
      String? selectedLevelId,
      Map<String, String>? customDataOverrides,
      List<dynamic>? customAppDataFields,
      ) async {
    final map = <String, String>{};
    final isPreviewMode = customDataOverrides?['preview_mode'] == 'true';

    if (kDebugMode) {
      debugPrint('🗺️ PREPARE DATA MAP DEBUG START:');
      debugPrint('   Quote: ${quote.quoteNumber}');
      debugPrint('   Customer: ${customer.name}');
      debugPrint('   Selected Level ID: $selectedLevelId');
      debugPrint('   Custom Data Overrides: $customDataOverrides');
      debugPrint('   Custom App Data Fields: ${customAppDataFields?.length ?? 0}');
    }

    // 🔧 GET APP SETTINGS FOR COMPANY INFO
    final appSettings = await DatabaseService.instance.getAppSettings();

    if (kDebugMode) {
      debugPrint('🏢 APP SETTINGS DEBUG:');
      debugPrint('   Company Name: "${appSettings?.companyName ?? 'NULL'}"');
      debugPrint('   Company Address: "${appSettings?.companyAddress ?? 'NULL'}"');
      debugPrint('   Company Phone: "${appSettings?.companyPhone ?? 'NULL'}"');
      debugPrint('   Company Email: "${appSettings?.companyEmail ?? 'NULL'}"');
      debugPrint('   Preview mode: ${customDataOverrides?['preview_mode']}');
    }

    // === CUSTOMER INFORMATION ===
    map['customerName'] = customer.name;
    final nameParts = customer.name.split(' ');
    map['customerFirstName'] = nameParts.isNotEmpty ? nameParts.first : '';
    map['customerLastName'] =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    map['customerStreetAddress'] = customer.streetAddress ?? '[Street Address]';
    map['customerCity'] = customer.city ?? '[City]';
    map['customerState'] = customer.stateAbbreviation ?? '[ST]';
    map['customerZipCode'] = customer.zipCode ?? '[Zip]';
    map['customerFullAddress'] = customer.fullDisplayAddress.isNotEmpty && customer.fullDisplayAddress != 'No address provided'
        ? customer.fullDisplayAddress
        : '[Full Customer Address]';
    map['customerPhone'] = customer.phone ?? '[Customer Phone]';
    map['customerEmail'] = customer.email ?? '[customer@email.com]';

    // === COMPANY INFORMATION ===
    map['companyName'] = appSettings?.companyName ?? '[Your Company Name]';
    map['companyAddress'] = appSettings?.companyAddress ?? '[Your Company Address]';
    map['companyPhone'] = appSettings?.companyPhone ?? '[Your Company Phone]';
    map['companyEmail'] = appSettings?.companyEmail ?? '[your@companyemail.com]';

    if (kDebugMode) {
      debugPrint('🔍 DEBUG 2 - AFTER COMPANY INFO SET:');
      debugPrint('   map[companyPhone]: "${map['companyPhone']}"');
      debugPrint('   map[companyEmail]: "${map['companyEmail']}"');
    }

    // === QUOTE BASIC INFORMATION ===
    map['quoteNumber'] = quote.quoteNumber;
    map['quoteDate'] = _dateFormat.format(quote.createdAt);
    map['validUntil'] = _dateFormat.format(quote.validUntil);
    map['quoteStatus'] = quote.status.toUpperCase();
    map['todaysDate'] = _dateFormat.format(DateTime.now());

    // === NOTES AND TEXT FIELDS ===
    map['notes'] = quote.notes ?? (customDataOverrides?['preview_mode'] == 'true' ? '[Scope of work and notes about the project...]' : '');
    map['terms'] = customDataOverrides?['terms'] ?? '[Standard terms and conditions apply...]';
    map['upgradeQuoteText'] = _extractUpgradeQuoteFromNotes(quote.notes);

    // === LEVEL-SPECIFIC INFORMATION ===
    for (int i = 0; i < 3; i++) {
      final levelNum = i + 1;
      final levelKey = 'level$levelNum';

      if (i < quote.levels.length) {
        final level = quote.levels[i];
        final taxAmount = level.subtotal * (quote.taxRate / 100);
        final totalWithTax = level.subtotal + taxAmount;

        map['${levelKey}Name'] = level.name;
        map['${levelKey}Subtotal'] = _currencyFormat.format(level.subtotal);
        map['${levelKey}Tax'] = _currencyFormat.format(taxAmount);
        map['${levelKey}TotalWithTax'] = _currencyFormat.format(totalWithTax);
      } else {
        map['${levelKey}Name'] = '';
        map['${levelKey}Subtotal'] = '';
        map['${levelKey}Tax'] = '';
        map['${levelKey}TotalWithTax'] = '';
      }
    }

    // === PRODUCT-SPECIFIC INFORMATION ===
    // === PRODUCT-SPECIFIC INFORMATION ===
    final allProducts = <legacy_quote_model.QuoteItem>[];

    QuoteLevel? targetLevel;
    if (selectedLevelId != null && quote.levels.any((l) => l.id == selectedLevelId)) {
      targetLevel = quote.levels.firstWhere((l) => l.id == selectedLevelId);
    } else if (quote.levels.isNotEmpty) {
      targetLevel = quote.levels.first;
    }

    if (targetLevel != null) {
      allProducts.addAll(targetLevel.includedItems);
    }
    allProducts.addAll(quote.addons);


    // Dynamically named product fields based on product names
    final dynamicProducts = <Product>[];
    for (final item in allProducts) {
      final safeName = _createSafeFieldName(item.productName);
      map['${safeName}Name'] = item.productName;
      map['${safeName}Qty'] = item.quantity.toString();
      map['${safeName}UnitPrice'] = _currencyFormat.format(item.unitPrice);
      map['${safeName}Total'] = _currencyFormat.format(item.totalPrice);
      map['${safeName}Description'] = item.description ?? '';

      dynamicProducts.add(Product(
        id: item.productId,
        name: item.productName,
        description: item.description,
        unitPrice: item.unitPrice,
        unit: item.unit,
        category: '',
      ));
    }

    // === OVERALL TOTALS ===
    if (targetLevel != null) {
      final discountSummary = quote.getDiscountSummary(targetLevel.id);
      final levelSubtotal = targetLevel.subtotal;
      final addonSubtotal = quote.addons.fold(0.0, (sum, addon) => sum + addon.totalPrice);
      final combinedSubtotal = levelSubtotal + addonSubtotal;
      final totalDiscountAmount = discountSummary['totalDiscount'] as double? ?? 0.0;
      final subtotalAfterDiscounts = combinedSubtotal - totalDiscountAmount;
      final taxAmount = subtotalAfterDiscounts * (quote.taxRate / 100);
      final grandTotal = subtotalAfterDiscounts + taxAmount;

      map['subtotal'] = _currencyFormat.format(combinedSubtotal);
      map['discount'] = totalDiscountAmount > 0 ? _currencyFormat.format(totalDiscountAmount) : "\$0.00";
      map['taxRate'] = '${quote.taxRate.toStringAsFixed(2)}%';
      map['taxAmount'] = _currencyFormat.format(taxAmount);
      map['grandTotal'] = _currencyFormat.format(grandTotal);

        // Removed legacy itemName fields
      } else {
        map['subtotal'] = _currencyFormat.format(0.00);
        map['discount'] = _currencyFormat.format(0.00);
        map['taxRate'] = '0.00%';
        map['taxAmount'] = _currencyFormat.format(0.00);
        map['grandTotal'] = _currencyFormat.format(0.00);
      }

    // === CUSTOM DATA OVERRIDES ===
    if (customDataOverrides != null) {
      final companyFields = {'companyName', 'companyAddress', 'companyPhone', 'companyEmail'};

      for (final entry in customDataOverrides.entries) {
        final key = entry.key;
        final value = entry.value;

        if (!companyFields.contains(key) || value.isNotEmpty) {
          map[key] = value;
        }
      }

      if (kDebugMode) {
        debugPrint('🔧 CUSTOM OVERRIDES APPLIED:');
        for (final entry in customDataOverrides.entries) {
          final wasApplied = !companyFields.contains(entry.key) || entry.value.isNotEmpty;
          debugPrint('   ${entry.key}: "${entry.value}" ${wasApplied ? "✅ APPLIED" : "❌ SKIPPED (empty company field)"}');
        }
      }
    }

    // ============= CRITICAL FIX =============
    // Store company values before custom fields can override them
    final companyFieldsBackup = {
      'companyName': map['companyName']!,
      'companyAddress': map['companyAddress']!,
      'companyPhone': map['companyPhone']!,
      'companyEmail': map['companyEmail']!,
    };

    if (kDebugMode) {
      debugPrint('💾 BACKUP company fields before custom fields:');
      for (final entry in companyFieldsBackup.entries) {
        debugPrint('   ${entry.key}: "${entry.value}"');
      }
    }
    // =======================================

    // === CUSTOM APP DATA FIELDS ===
    // === CUSTOM APP DATA FIELDS ===
    if (customAppDataFields != null) {
      for (final field in customAppDataFields) {
        final String fieldName;
        final String fieldCategory;
        final String fieldType;

        if (field is Map<String, dynamic>) {
          fieldName = field['fieldName'] as String? ?? '';
          fieldCategory = field['category'] as String? ?? '';
          fieldType = field['fieldType'] as String? ?? '';
        } else {
          fieldName = field.fieldName as String? ?? '';
          fieldCategory = field.category as String? ?? '';
          fieldType = field.fieldType as String? ?? '';
        }

        if (fieldName.isNotEmpty) {
          String valueToUse = '';

          // 🚀 Use customer inspection data for inspection fields
          if (fieldCategory == 'inspection') {
            final inspectionValue = customer.getInspectionValue(fieldName);

            if (inspectionValue != null) {
              if (fieldType == 'checkbox') {
                valueToUse = (inspectionValue == true || inspectionValue == 'true') ? 'true' : 'false';
              } else {
                valueToUse = inspectionValue.toString();
              }
            }
          } else {
            // For non-inspection fields, use the default value
            final String currentValue;
            if (field is Map<String, dynamic>) {
              currentValue = field['currentValue'] as String? ?? '';
            } else {
              currentValue = field.currentValue as String? ?? '';
            }
            valueToUse = currentValue;
          }

          // Don't override company fields with empty values
          final isCompanyField = companyFieldsBackup.containsKey(fieldName);
          if (isCompanyField && valueToUse.isEmpty) {
            continue;
          }

          map[fieldName] = valueToUse.isNotEmpty ? valueToUse :
          (isPreviewMode ? '[${PDFTemplate.getFieldDisplayName(fieldName, customAppDataFields)}]' : '');
        }
      }

      if (kDebugMode) debugPrint('📝 Added ${customAppDataFields.length} custom app data fields to PDF data map');
    }

    // ============= CRITICAL FIX =============
    // Restore company fields from app settings if they were cleared
    for (final entry in companyFieldsBackup.entries) {
      final fieldName = entry.key;
      final backupValue = entry.value;

      if (map[fieldName]?.isEmpty == true && backupValue.isNotEmpty) {
        map[fieldName] = backupValue;
        if (kDebugMode) {
          debugPrint('🔧 RESTORED $fieldName from app settings: "$backupValue"');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✅ FINAL company field check:');
      for (final entry in companyFieldsBackup.entries) {
        debugPrint('   ${entry.key}: "${map[entry.key]}"');
      }
    }
    // =======================================
    String generateSampleValueForField(String fieldType) {
      // Handle specific field patterns
      if (fieldType.contains('Name') && !fieldType.contains('company') && !fieldType.contains('customer')) {
        return '[Sample Product Name]';
      }
      if (fieldType.contains('Qty')) {
        return '5';
      }
      if (fieldType.contains('UnitPrice')) {
        return '\$25.00';
      }
      if (fieldType.contains('Total') && !fieldType.contains('grand')) {
        return '\$125.00';
      }
      if (fieldType.contains('Tax') && fieldType.contains('Rate')) {
        return '8.5%';
      }
      if (fieldType.contains('Tax') && fieldType.contains('Amount')) {
        return '\$85.20';
      }
      if (fieldType.contains('Date')) {
        return _dateFormat.format(DateTime.now());
      }
      if (fieldType.contains('Phone')) {
        return '(555) 123-4567';
      }
      if (fieldType.contains('Email')) {
        return 'sample@company.com';
      }
      if (fieldType.contains('Address')) {
        return '123 Sample Street, Sample City, ST 12345';
      }
      if (fieldType.contains('Boolean') || fieldType.contains('checkbox')) {
        return 'true';
      }
      if (fieldType.contains('Number') || fieldType.contains('Numeric')) {
        return '42';
      }

      // Specific field mappings
      switch (fieldType) {
        case 'subtotal':
          return '\$1,234.56';
        case 'discount':
          return '\$100.00';
        case 'grandTotal':
          return '\$1,219.76';
        case 'quoteNumber':
          return 'Q-2025-001';
        case 'quoteStatus':
          return 'DRAFT';
        case 'notes':
          return 'Sample project notes and scope of work details...';
        case 'terms':
          return 'Standard terms and conditions apply to this estimate.';
        case 'upgradeQuoteText':
          return 'Optional upgrades available - contact us for details.';
        case 'customText1':
        case 'customText2':
        case 'customText3':
          return '[Custom Text Field]';
        case 'customNumeric1':
        case 'customNumeric2':
          return '100';
        case 'customDate1':
        case 'customDate2':
          return _dateFormat.format(DateTime.now().add(const Duration(days: 30)));
        default:
        // Generic fallback
          return '[${PDFTemplate.getFieldDisplayName(fieldType)}]';
      }
    }
    // === ENSURE ALL FIELD TYPES HAVE VALUES ===


    for (final fieldTypeKey in PDFTemplate
        .getFieldDefinitions(dynamicProducts, customAppDataFields)
        .map((d) => d.appDataType)) {
      final existingValue = map[fieldTypeKey];

      // Generate better sample data for preview mode
      String sampleValue = '';
      if (isPreviewMode) {
        sampleValue = generateSampleValueForField(fieldTypeKey);
      }

      final defaultValue = isPreviewMode ? sampleValue : '';

      // Don't override company fields with empty defaults if they have app settings values
      final isCompanyField = companyFieldsBackup.containsKey(fieldTypeKey);
      final hasAppSettingsValue = isCompanyField && companyFieldsBackup[fieldTypeKey]?.isNotEmpty == true;

      if (hasAppSettingsValue && (existingValue?.isEmpty ?? true)) {
        // Keep app settings value for company fields
        map[fieldTypeKey] = companyFieldsBackup[fieldTypeKey]!;
      } else if (existingValue?.isEmpty ?? true) {
        // Use sample data for empty fields
        map[fieldTypeKey] = defaultValue;
      }
    }

    if (kDebugMode) {
      debugPrint('🔍 FINAL DEBUG - BEFORE RETURN:');
      debugPrint('   Final map[companyPhone]: "${map['companyPhone']}"');
      debugPrint('   Final map[companyEmail]: "${map['companyEmail']}"');
      debugPrint('   Total map size: ${map.length}');
    }

    if (kDebugMode) debugPrint('🗺️ Prepared Data Map for PDF with ${map.length} fields');
    return map;
  }

  /// Extract mini upgrade quote from notes section
  String _extractUpgradeQuoteFromNotes(String? notes) {
    if (notes == null || notes.isEmpty) return '';

    // Look for upgrade quote patterns in notes
    final upgradePatterns = [
      RegExp(r'UPGRADE QUOTE:(.*?)(?=\n\n|\n[A-Z]|$)', multiLine: true, dotAll: true),
      RegExp(r'MINI QUOTE:(.*?)(?=\n\n|\n[A-Z]|$)', multiLine: true, dotAll: true),
      RegExp(r'ADDITIONAL WORK:(.*?)(?=\n\n|\n[A-Z]|$)', multiLine: true, dotAll: true),
    ];

    for (final pattern in upgradePatterns) {
      final match = pattern.firstMatch(notes);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }

    return ''; // No upgrade quote found
  }

  Future<bool> deleteTemplate(String templateId) async {
    try {
      final template = await DatabaseService.instance.getPDFTemplate(templateId);
      if (template != null) {
        final file = File(template.pdfFilePath);
        if (await file.exists()) {
          await file.delete();
          if (kDebugMode) debugPrint('🗑️ Deleted PDF file: ${template.pdfFilePath}');
        } else {
          if (kDebugMode) debugPrint('⚠️ PDF file not found for deletion: ${template.pdfFilePath}');
        }
        await DatabaseService.instance.deletePDFTemplate(templateId);
        if (kDebugMode) debugPrint('✅ Template record deleted from DB: ${template.templateName}');
        return true;
      }
      if (kDebugMode) debugPrint('⚠️ Template record not found in DB for deletion: $templateId');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error deleting template $templateId: $e');
      return false;
    }
  }

  Future<List<PDFTemplate>> getAllTemplates() async {
    return await DatabaseService.instance.getAllPDFTemplates();
  }

  Future<List<PDFTemplate>> getActiveTemplates() async {
    final all = await getAllTemplates();
    return all.where((t) => t.isActive).toList();
  }

  Future<bool> validateTemplate(PDFTemplate template) async {
    final file = File(template.pdfFilePath);
    if (!await file.exists()) {
      if (kDebugMode) debugPrint('Validation Fail: PDF file for template "${template.templateName}" not found at ${template.pdfFilePath}');
      return false;
    }
    return true;
  }
}

// Helper to generate a safe field name from a product name
String _createSafeFieldName(String productName) {
  return productName
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAllMapped(RegExp(r'^\w'), (m) => m.group(0)!.toLowerCase())
      .replaceAllMapped(RegExp(r'\s\w'), (m) => m.group(0)!.toUpperCase().replaceAll(' ', ''));
}