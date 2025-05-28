// lib/services/template_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:intl/intl.dart';

import '../models/pdf_template.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart';
import 'database_service.dart';

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static TemplateService get instance => _instance;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  /// Load PDF template and analyze its dimensions
  Future<PDFTemplate?> createTemplateFromPDF(String pdfPath, String templateName) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      syncfusion.PdfDocument? document;

      try {
        document = syncfusion.PdfDocument(inputBytes: bytes);

        // Get PDF dimensions
        final page = document.pages[0];
        final pageWidth = page.size.width;
        final pageHeight = page.size.height;
        final totalPages = document.pages.count;

        if (kDebugMode) {
          print('📄 PDF Template Analysis:');
          print('   File: ${file.path.split('/').last}');
          print('   Pages: $totalPages');
          print('   Size: ${pageWidth.toStringAsFixed(1)} x ${pageHeight.toStringAsFixed(1)} pts');
        }

        // Copy PDF to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final templatesDir = Directory('${appDir.path}/templates');
        if (!await templatesDir.exists()) {
          await templatesDir.create(recursive: true);
        }

        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${templateName.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';
        final newPath = '${templatesDir.path}/$fileName';
        final newFile = await file.copy(newPath);

        final template = PDFTemplate(
          templateName: templateName,
          description: 'Imported from ${file.path.split('/').last}',
          pdfFilePath: newFile.path,
          pageWidth: pageWidth,
          pageHeight: pageHeight,
          totalPages: totalPages,
          metadata: {
            'originalFileName': file.path.split('/').last,
            'importedAt': DateTime.now().toIso8601String(),
            'fileSize': bytes.length,
          },
        );

        // Save to database
        await DatabaseService.instance.savePDFTemplate(template);

        if (kDebugMode) {
          print('✅ Template created successfully: ${template.templateName}');
        }

        return template;

      } finally {
        document?.dispose();
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating template from PDF: $e');
      }
      rethrow;
    }
  }

  /// Generate populated PDF from template
  Future<String> generatePDFFromTemplate({
    required PDFTemplate template,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 Generating PDF from template: ${template.templateName}');
      }

      // Load the template PDF
      final templateFile = File(template.pdfFilePath);
      if (!await templateFile.exists()) {
        throw Exception('Template PDF not found: ${template.pdfFilePath}');
      }

      final templateBytes = await templateFile.readAsBytes();

      // Create new PDF document
      final pdf = pw.Document();

      // Prepare data map
      final dataMap = _prepareDataMap(quote, customer, selectedLevelId, customData);

      // Add pages with overlaid text
      final pageImage = await _convertPDFPageToImage(templateBytes, 0);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(template.pageWidth, template.pageHeight),
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Background PDF page as image
                if (pageImage != null)
                  pw.Image(pw.MemoryImage(pageImage)),

                // Overlay text fields
                ...template.fieldMappings.map((field) => _buildTextField(field, dataMap, template)),
              ],
            );
          },
        ),
      );

      // Save the generated PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'quote_${quote.quoteNumber.replaceAll(RegExp(r'[^\w\s]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputFile = File('${directory.path}/$fileName');
      await outputFile.writeAsBytes(await pdf.save());

      if (kDebugMode) {
        print('✅ PDF generated successfully: ${outputFile.path}');
      }

      return outputFile.path;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating PDF from template: $e');
      }
      rethrow;
    }
  }

  /// Preview template with sample data
  Future<String> generateTemplatePreview(PDFTemplate template) async {
    // Create sample quote and customer for preview
    final sampleCustomer = Customer(
      name: 'John Smith',
      address: '123 Main Street, Anytown, ST 12345',
      phone: '(555) 123-4567',
      email: 'john.smith@email.com',
    );

    final sampleQuote = SimplifiedMultiLevelQuote(
      customerId: sampleCustomer.id,
      levels: [
        QuoteLevel(
          id: 'basic',
          name: 'Basic Package',
          levelNumber: 1,
          basePrice: 5000.0,
          baseQuantity: 25.0,
        ),
      ],
      taxRate: 8.5,
    );

    return generatePDFFromTemplate(
      template: template,
      quote: sampleQuote,
      customer: sampleCustomer,
      selectedLevelId: 'basic',
      customData: {'preview': 'true'},
    );
  }

  /// Prepare data map for field population
  Map<String, String> _prepareDataMap(
      SimplifiedMultiLevelQuote quote,
      Customer customer,
      String? selectedLevelId,
      Map<String, String>? customData,
      ) {
    final map = <String, String>{};

    // Customer data
    map['customerName'] = customer.name;
    map['customerAddress'] = customer.address ?? '';
    map['customerPhone'] = customer.phone ?? '';
    map['customerEmail'] = customer.email ?? '';

    // Quote data
    map['quoteNumber'] = quote.quoteNumber;
    map['quoteDate'] = _dateFormat.format(quote.createdAt);
    map['validUntil'] = _dateFormat.format(quote.validUntil);
    map['quoteStatus'] = quote.status.toUpperCase();

    // Company data (from app settings - you might need to pass this)
    map['companyName'] = 'Your Company Name'; // TODO: Get from AppSettings
    map['companyAddress'] = '123 Business St, City, ST 12345'; // TODO: Get from AppSettings
    map['companyPhone'] = '(555) 123-4567'; // TODO: Get from AppSettings
    map['companyEmail'] = 'info@yourcompany.com'; // TODO: Get from AppSettings

    // Selected level data
    if (selectedLevelId != null) {
      final level = quote.levels.firstWhere(
            (l) => l.id == selectedLevelId,
        orElse: () => quote.levels.first,
      );

      map['levelName'] = level.name;
      map['levelPrice'] = _currencyFormat.format(level.subtotal);

      final total = quote.getDisplayTotalForLevel(selectedLevelId);
      map['grandTotal'] = _currencyFormat.format(total);

      // Calculate components
      final subtotal = level.subtotal + quote.addons.fold(0.0, (sum, addon) => sum + addon.totalPrice);
      final discountSummary = quote.getDiscountSummary(selectedLevelId);
      final totalDiscount = discountSummary['totalDiscount'] as double;
      final discountedSubtotal = subtotal - totalDiscount;
      final tax = discountedSubtotal * (quote.taxRate / 100);

      map['subtotal'] = _currencyFormat.format(subtotal);
      map['discount'] = totalDiscount > 0 ? '-${_currencyFormat.format(totalDiscount)}' : '\$0.00';
      map['taxRate'] = '${quote.taxRate.toStringAsFixed(1)}%';
      map['taxAmount'] = _currencyFormat.format(tax);
    }

    // Add custom data
    if (customData != null) {
      map.addAll(customData);
    }

    // Default values for missing fields
    for (final fieldType in PDFTemplate.getQuoteFieldTypes()) {
      map.putIfAbsent(fieldType, () => '[${PDFTemplate.getFieldDisplayName(fieldType)}]');
    }

    return map;
  }

  /// Convert PDF page to image for background
  Future<Uint8List?> _convertPDFPageToImage(Uint8List pdfBytes, int pageIndex) async {
    try {
      // This is a simplified approach - in practice, you might want to use
      // a more sophisticated PDF-to-image conversion method
      // For now, we'll return null and use a white background
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not convert PDF page to image: $e');
      }
      return null;
    }
  }

  /// Build text field widget for PDF
  pw.Widget _buildTextField(FieldMapping field, Map<String, String> dataMap, PDFTemplate template) {
    final text = dataMap[field.fieldType] ?? field.placeholder ?? '';

    // Convert relative coordinates to absolute
    final x = field.x * template.pageWidth;
    final y = field.y * template.pageHeight;
    final fieldWidth = field.width * template.pageWidth;
    final fieldHeight = field.height * template.pageHeight;

    // Convert color
    final color = _hexToColor(field.fontColor);

    // Determine alignment
    pw.TextAlign alignment;
    switch (field.alignment) {
      case 'center':
        alignment = pw.TextAlign.center;
        break;
      case 'right':
        alignment = pw.TextAlign.right;
        break;
      default:
        alignment = pw.TextAlign.left;
    }

    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Container(
        width: fieldWidth,
        height: fieldHeight,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: field.fontSize,
            color: color,
            fontWeight: field.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: field.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
          ),
          textAlign: alignment,
          maxLines: (fieldHeight / field.fontSize).floor(),
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }

  /// Convert hex color string to PdfColor
  PdfColor _hexToColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      final intValue = int.parse(hexCode, radix: 16);
      final r = (intValue >> 16) & 0xFF;
      final g = (intValue >> 8) & 0xFF;
      final b = intValue & 0xFF;
      return PdfColor(r / 255.0, g / 255.0, b / 255.0);
    } catch (e) {
      return PdfColors.black;
    }
  }

  /// Delete template and its PDF file
  Future<bool> deleteTemplate(String templateId) async {
    try {
      final template = await DatabaseService.instance.getPDFTemplate(templateId);
      if (template != null) {
        // Delete PDF file
        final file = File(template.pdfFilePath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete from database
        await DatabaseService.instance.deletePDFTemplate(templateId);

        if (kDebugMode) {
          print('✅ Template deleted: ${template.templateName}');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting template: $e');
      }
      return false;
    }
  }

  /// Get all available templates
  Future<List<PDFTemplate>> getAllTemplates() async {
    return await DatabaseService.instance.getAllPDFTemplates();
  }

  /// Get active templates only
  Future<List<PDFTemplate>> getActiveTemplates() async {
    final templates = await getAllTemplates();
    return templates.where((t) => t.isActive).toList();
  }

  /// Validate template (check if PDF file exists)
  Future<bool> validateTemplate(PDFTemplate template) async {
    final file = File(template.pdfFilePath);
    return await file.exists();
  }
}