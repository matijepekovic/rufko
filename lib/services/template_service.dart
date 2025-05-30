// lib/services/template_service.dart

import 'dart:io';
import 'dart:typed_data'; // For Uint8List - Keep this, it's used for bytes.
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// Syncfusion PDF library for reading/writing existing PDF forms
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

// Your models
import '../models/pdf_template.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart';
import '../models/quote.dart' as legacy_quote_model;
import 'database_service.dart';
import '../models/app_settings.dart';

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
          print('📄 PDF Template Analysis for: $templateName');
          print('   Original Path: $uploadedPdfPath');
          print('   Pages: $totalPages');
          // FIX: Removed unnecessary braces
          print('   First Page Size: ${pageWidth.toStringAsFixed(1)} x ${pageHeight.toStringAsFixed(1)} pts');
        }

        // FIX: Simplified null check for form and fields
        if (document.form.fields.count > 0) {
          if (kDebugMode) {
            // FIX: Removed unnecessary braces
            print('   Found ${document.form.fields.count} potential form fields in PDF.');
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
              if (kDebugMode) print("Warning: Could not determine page for field ${field.name}. Defaulting to page 0.");
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

            PdfFormFieldType detectedType = PdfFormFieldType.UNKNOWN;
            if (field is syncfusion.PdfTextBoxField) {
              detectedType = PdfFormFieldType.TEXT_BOX;
            } else if (field is syncfusion.PdfCheckBoxField) {
              detectedType = PdfFormFieldType.CHECK_BOX;
            } else if (field is syncfusion.PdfRadioButtonListField) {
              detectedType = PdfFormFieldType.RADIO_BUTTON_GROUP;
            } else if (field is syncfusion.PdfComboBoxField) {
              detectedType = PdfFormFieldType.COMBO_BOX;
            } else if (field is syncfusion.PdfListBoxField) {
              detectedType = PdfFormFieldType.LIST_BOX;
            } else if (field is syncfusion.PdfSignatureField) {
              detectedType = PdfFormFieldType.SIGNATURE_FIELD;
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
              print('     - Detected: "$fieldName" (Type: $detectedType, Page: $pageIndex, Bounds: $fieldBounds)');
            }
          }
        } else {
          if (kDebugMode) print('   No AcroForm fields detected in this PDF.');
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
        if (kDebugMode) print('✅ PDFTemplate object created and saved: ${template.templateName}');
        return template;

      } finally {
        document?.dispose();
      }

    } catch (e) {
      if (kDebugMode) print('❌ Error in createTemplateFromPDF: $e');
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
      if (kDebugMode) {
        print('🔄 Generating PDF by filling form fields for template: ${template.templateName}');
        print('🔍 DEBUG: generatePDFFromTemplate method called');
      }

      final templateFile = File(template.pdfFilePath);
      if (!await templateFile.exists()) {
        throw Exception('Template PDF file not found: ${template.pdfFilePath}');
      }
      final templateBytes = await templateFile.readAsBytes();
      final syncfusion.PdfDocument document = syncfusion.PdfDocument(inputBytes: templateBytes);
      final customAppDataFields = await DatabaseService.instance.getAllCustomAppDataFields();
      final dataMap = await _prepareDataMap(quote, customer, selectedLevelId, customData, customAppDataFields);

      // FIX: Simplified null check
      if (document.form.fields.count > 0) {
        for (final FieldMapping mapping in template.fieldMappings) {
          final pdfFieldName = mapping.pdfFormFieldName;
          if (pdfFieldName.isEmpty) { // Check if pdfFieldName is empty
            if (kDebugMode) print('   ⚠️ Skipping AppData "${mapping.appDataType}" as its pdfFormFieldName is empty.');
            continue; // Skip this mapping if no PDF field is associated
          }

          String valueToFill;
          if (kDebugMode) {
            print('🔍 FIELD MAPPING DEBUG:');
            print('   appDataType: "${mapping.appDataType}"');
            print('   pdfFormFieldName: "${pdfFieldName}"');
            print('   overrideEnabled: ${mapping.overrideValueEnabled}');
            print('   defaultValue: "${mapping.defaultValue ?? 'null'}"');

            // Check if the key exists in dataMap
            if (dataMap.containsKey(mapping.appDataType)) {
              print('   ✅ Found in dataMap: "${dataMap[mapping.appDataType]}"');
            } else {
              print('   ❌ NOT found in dataMap');
              print('   📋 Available dataMap keys:');
              for (final key in dataMap.keys.take(10)) { // Show first 10 keys
                print('      - "$key"');
              }
            }
          }

          if (mapping.overrideValueEnabled && mapping.defaultValue != null && mapping.defaultValue!.isNotEmpty) {
            valueToFill = mapping.defaultValue!;
            if (kDebugMode) {
              print('   📎 Using OVERRIDE for ${mapping.appDataType} (PDF: $pdfFieldName): "$valueToFill"');
            }
          } else {
            valueToFill = dataMap[mapping.appDataType] ?? '';
            if (kDebugMode) {
              print('   ⚙️ Using RESOLVED data for ${mapping.appDataType} (PDF: $pdfFieldName): "$valueToFill" (from dataMap, fallback to empty)');
            }
          }
          // ------------ CORE FIX START ------------
          if (mapping.overrideValueEnabled && mapping.defaultValue != null && mapping.defaultValue!.isNotEmpty) {
            valueToFill = mapping.defaultValue!; // Use the stored override value
            if (kDebugMode) {
              print('   📎 Using OVERRIDE for ${mapping.appDataType} (PDF: $pdfFieldName): "$valueToFill"');
            }
          } else {
            // Override not enabled or is empty, so use the value from dataMap,
            // or an empty string if not found in dataMap.
            valueToFill = dataMap[mapping.appDataType] ?? ''; // Get from _prepareDataMap result, default to empty
            if (kDebugMode) {
              print('   ⚙️ Using RESOLVED data for ${mapping.appDataType} (PDF: $pdfFieldName): "$valueToFill" (from dataMap, fallback to empty)');
            }
          }

          final appDataValue = valueToFill;

          try {
            syncfusion.PdfField? fieldToUpdate;
            // FIX: Removed '!'
            for(int i=0; i < document.form.fields.count; i++){
              if(document.form.fields[i].name == pdfFieldName){
                fieldToUpdate = document.form.fields[i];
                break;
              }
            }

            if (fieldToUpdate != null) {
              if (fieldToUpdate is syncfusion.PdfTextBoxField) {
                fieldToUpdate.text = appDataValue;
              } else if (fieldToUpdate is syncfusion.PdfCheckBoxField) {
                bool isChecked = appDataValue.toLowerCase() == 'true' ||
                    appDataValue == '1' ||
                    appDataValue.toLowerCase() == 'yes' ||
                    appDataValue.toLowerCase() == 'on';
                fieldToUpdate.isChecked = isChecked;
              } else if (fieldToUpdate is syncfusion.PdfRadioButtonListField) {
                // For radio button lists, set the selected index or value on the parent field
                int selectedIdx = -1;
                for (int j = 0; j < fieldToUpdate.items.count; j++) {
                  final item = fieldToUpdate.items[j];
                  // Compare against the item's value (or potentially item.text if that's how you've mapped it)
                  if (item.value == appDataValue) {
                    selectedIdx = j;
                    break;
                  }
                }
                if (selectedIdx != -1) {
                  fieldToUpdate.selectedIndex = selectedIdx;
                  // Alternatively, if your appDataValue directly matches one of the radio button values:
                  // fieldToUpdate.selectedValue = appDataValue;
                  // Using selectedIndex is often safer if values might not be exact string matches.
                } else {
                  if (kDebugMode) print('   ⚠️ Radio button value "$appDataValue" not found in options for field "$pdfFieldName".');
                }
              } else if (fieldToUpdate is syncfusion.PdfComboBoxField) {
                fieldToUpdate.selectedValue = appDataValue;
              }
              if (kDebugMode) print('   -> Populated PDF field "$pdfFieldName" with value for "${mapping.appDataType}"');
            } else {
              if (kDebugMode) print('   ⚠️ PDF field "$pdfFieldName" (for app data "${mapping.appDataType}") not found in template.');
            }
          } catch (e) {
            if (kDebugMode) print('   ❌ Error setting value for PDF field "$pdfFieldName": $e');
          }
        }
      } else {
        if (kDebugMode) print('   ⚠️ Template PDF has no detectable form or fields to populate.');
      }

      final List<int> populatedPdfBytes = document.saveSync();
      document.dispose();

      final directory = await getApplicationDocumentsDirectory();
      // FIX: Removed unnecessary braces
      final outputFileName = 'populated_${template.templateName.replaceAll(RegExp(r'[^\w\s-]'), '')}_${quote.quoteNumber.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';
      final outputFile = File('${directory.path}/$outputFileName');
      await outputFile.writeAsBytes(populatedPdfBytes);

      if (kDebugMode) print('✅ Populated PDF saved to: ${outputFile.path}');
      return outputFile.path;

    } catch (e) {
      if (kDebugMode) print('❌ Error in generatePDFFromTemplate (form filling): $e');
      rethrow;
    }
  }

  Future<String> generateTemplatePreview(PDFTemplate template) async {
    final sampleCustomer = Customer(
      name: '[Customer Name]',
      // Provide sample structured address
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
        QuoteLevel(id: 'level1', name: '[Level 1 Name]', levelNumber: 1, basePrice: 1234.56, baseQuantity: 1.0)
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

    if (kDebugMode) print('👁️ Generating preview for template: ${template.templateName}');
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

    // 🔧 GET APP SETTINGS FOR COMPANY INFO
    final appSettings = await DatabaseService.instance.getAppSettings();

    if (kDebugMode) {
      print('🏢 APP SETTINGS DEBUG:');
      print('   Company Name: "${appSettings?.companyName ?? 'NULL'}"');
      print('   Company Address: "${appSettings?.companyAddress ?? 'NULL'}"');
      print('   Company Phone: "${appSettings?.companyPhone ?? 'NULL'}"');
      print('   Company Email: "${appSettings?.companyEmail ?? 'NULL'}"');
    }

    // === CUSTOMER INFORMATION ===
    map['customerName'] = customer.name;
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
      print('🔍 DEBUG 2 - AFTER COMPANY INFO SET:');
      print('   map[companyPhone]: "${map['companyPhone']}"');
      print('   map[companyEmail]: "${map['companyEmail']}"');
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

    for (int i = 0; i < 5; i++) {
      final productNum = i + 1;
      final productKey = 'product$productNum';

      if (i < allProducts.length) {
        final product = allProducts[i];
        map['${productKey}Name'] = product.productName;
        map['${productKey}Qty'] = product.quantity.toString();
        map['${productKey}UnitPrice'] = _currencyFormat.format(product.unitPrice);
        map['${productKey}Total'] = _currencyFormat.format(product.totalPrice);
      } else {
        map['${productKey}Name'] = '';
        map['${productKey}Qty'] = '';
        map['${productKey}UnitPrice'] = '';
        map['${productKey}Total'] = '';
      }
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

      if (allProducts.isNotEmpty) {
        final firstProduct = allProducts.first;
        map['itemName'] = firstProduct.productName;
        map['itemQuantity'] = firstProduct.quantity.toString();
        map['itemUnitPrice'] = _currencyFormat.format(firstProduct.unitPrice);
        map['itemTotal'] = _currencyFormat.format(firstProduct.totalPrice);
      } else {
        map['itemName'] = '';
        map['itemQuantity'] = '';
        map['itemUnitPrice'] = '';
        map['itemTotal'] = '';
      }
    } else {
      map['subtotal'] = _currencyFormat.format(0.00);
      map['discount'] = _currencyFormat.format(0.00);
      map['taxRate'] = '0.00%';
      map['taxAmount'] = _currencyFormat.format(0.00);
      map['grandTotal'] = _currencyFormat.format(0.00);
      map['itemName'] = '';
      map['itemQuantity'] = '';
      map['itemUnitPrice'] = '';
      map['itemTotal'] = '';
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
        print('🔧 CUSTOM OVERRIDES APPLIED:');
        for (final entry in customDataOverrides.entries) {
          final wasApplied = !companyFields.contains(entry.key) || entry.value.isNotEmpty;
          print('   ${entry.key}: "${entry.value}" ${wasApplied ? "✅ APPLIED" : "❌ SKIPPED (empty company field)"}');
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
      print('💾 BACKUP company fields before custom fields:');
      for (final entry in companyFieldsBackup.entries) {
        print('   ${entry.key}: "${entry.value}"');
      }
    }
    // =======================================

    // === CUSTOM APP DATA FIELDS ===
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

        if (fieldName.isNotEmpty) {
          // ============= CRITICAL FIX =============
          // Don't override company fields from app settings with empty custom field values
          final isCompanyField = companyFieldsBackup.containsKey(fieldName);
          final hasNonEmptyValue = currentValue.isNotEmpty;
          final isPreviewMode = customDataOverrides?['preview_mode'] == 'true';

          if (isCompanyField && !hasNonEmptyValue) {
            // Skip empty custom company fields - keep app settings value
            if (kDebugMode) {
              print('   🚫 SKIPPING custom field "$fieldName" (empty value, keeping app settings)');
            }
            continue;
          }
          // =======================================

          map[fieldName] = currentValue.isNotEmpty ? currentValue :
          (isPreviewMode ? '[${PDFTemplate.getFieldDisplayName(fieldName, customAppDataFields)}]' : '');
        }
      }

      if (kDebugMode) print('📝 Added ${customAppDataFields.length} custom app data fields to PDF data map');
    }

    // ============= CRITICAL FIX =============
    // Restore company fields from app settings if they were cleared
    for (final entry in companyFieldsBackup.entries) {
      final fieldName = entry.key;
      final backupValue = entry.value;

      if (map[fieldName]?.isEmpty == true && backupValue.isNotEmpty) {
        map[fieldName] = backupValue;
        if (kDebugMode) {
          print('🔧 RESTORED $fieldName from app settings: "$backupValue"');
        }
      }
    }

    if (kDebugMode) {
      print('✅ FINAL company field check:');
      for (final entry in companyFieldsBackup.entries) {
        print('   ${entry.key}: "${map[entry.key]}"');
      }
    }
    // =======================================

    // === ENSURE ALL FIELD TYPES HAVE VALUES ===
    for (final fieldTypeKey in PDFTemplate.getQuoteFieldTypes()) {
      final existingValue = map[fieldTypeKey];
      final defaultValue = customDataOverrides?['preview_mode'] == 'true' ? '[${PDFTemplate.getFieldDisplayName(fieldTypeKey)}]' : '';

      // ============= CRITICAL FIX =============
      // Don't override company fields with empty defaults if they have app settings values
      final isCompanyField = companyFieldsBackup.containsKey(fieldTypeKey);
      final hasAppSettingsValue = isCompanyField && companyFieldsBackup[fieldTypeKey]?.isNotEmpty == true;

      if (hasAppSettingsValue && (existingValue?.isEmpty ?? true)) {
        // Use app settings value instead of empty default
        map[fieldTypeKey] = companyFieldsBackup[fieldTypeKey]!;
        if (kDebugMode) {
          print('🔧 ENSURED $fieldTypeKey has app settings value: "${map[fieldTypeKey]}"');
        }
      } else {
        map.putIfAbsent(fieldTypeKey, () => defaultValue);
      }
      // =======================================
    }

    if (kDebugMode) {
      print('🔍 FINAL DEBUG - BEFORE RETURN:');
      print('   Final map[companyPhone]: "${map['companyPhone']}"');
      print('   Final map[companyEmail]: "${map['companyEmail']}"');
      print('   Total map size: ${map.length}');
    }

    if (kDebugMode) print('🗺️ Prepared Data Map for PDF with ${map.length} fields');
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
          if (kDebugMode) print('🗑️ Deleted PDF file: ${template.pdfFilePath}');
        } else {
          if (kDebugMode) print('⚠️ PDF file not found for deletion: ${template.pdfFilePath}');
        }
        await DatabaseService.instance.deletePDFTemplate(templateId);
        if (kDebugMode) print('✅ Template record deleted from DB: ${template.templateName}');
        return true;
      }
      if (kDebugMode) print('⚠️ Template record not found in DB for deletion: $templateId');
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting template $templateId: $e');
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
      if (kDebugMode) print('Validation Fail: PDF file for template "${template.templateName}" not found at ${template.pdfFilePath}');
      return false;
    }
    return true;
  }
}