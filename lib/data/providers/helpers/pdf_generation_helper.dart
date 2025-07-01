import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/business/customer.dart';
import '../../models/business/simplified_quote.dart';
import '../../models/templates/pdf_template.dart';
import '../../../core/services/pdf/pdf_service.dart';
import '../../../core/services/template_service.dart';

class PdfGenerationHelper {
  static Future<String> generateSimplifiedQuotePdf(
    PdfService pdfService,
    SimplifiedMultiLevelQuote quote,
    Customer customer, {
    String? selectedLevelId,
    List<String>? selectedAddonIds,
  }) async {
    return await pdfService.generateSimplifiedMultiLevelQuotePdf(
      quote,
      customer,
      selectedLevelId: selectedLevelId,
      selectedAddonIds: selectedAddonIds,
    );
  }

  static Future<String> generatePDFFromTemplate({
    required List<PDFTemplate> templates,
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    final template = templates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found: $templateId'),
    );
    if (!template.isActive) {
      throw Exception('Template is not active: ${template.templateName}');
    }
    final pdfPath = await TemplateService.instance.generatePDFFromTemplate(
      template: template,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customData: customData,
    );
    if (kDebugMode) {
      debugPrint('📄 Generated PDF from template: ${template.templateName}');
    }
    return pdfPath;
  }

  static Future<String> regeneratePDFFromTemplate({
    required List<PDFTemplate> templates,
    required String templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customDataOverrides,
  }) async {
    final overrides = <String, String>{
      'regenerated_at': DateTime.now().toIso8601String(),
      'has_edits': 'true',
      ...?customDataOverrides,
    };
    return await generatePDFFromTemplate(
      templates: templates,
      templateId: templateId,
      quote: quote,
      customer: customer,
      selectedLevelId: selectedLevelId,
      customData: overrides,
    );
  }

  static Future<Map<String, dynamic>> generatePDFForPreview({
    required PdfService pdfService,
    List<PDFTemplate>? templates,
    String? templateId,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
    String? selectedLevelId,
    Map<String, String>? customData,
  }) async {
    String pdfPath;
    String generationMethod;
    String? usedTemplateId;

    if (templateId != null && templates != null) {
      pdfPath = await generatePDFFromTemplate(
        templates: templates,
        templateId: templateId,
        quote: quote,
        customer: customer,
        selectedLevelId: selectedLevelId,
        customData: customData,
      );
      generationMethod = 'template';
      usedTemplateId = templateId;
    } else {
      pdfPath = await generateSimplifiedQuotePdf(
        pdfService,
        quote,
        customer,
        selectedLevelId: selectedLevelId,
      );
      generationMethod = 'standard';
    }

    return {
      'pdfPath': pdfPath,
      'generationMethod': generationMethod,
      'templateId': usedTemplateId,
      'selectedLevelId': selectedLevelId,
      'customData': customData ?? {},
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<bool> validatePDFFile(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        if (kDebugMode) debugPrint('PDF file does not exist: $pdfPath');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        if (kDebugMode) debugPrint('PDF file is empty: $pdfPath');
        return false;
      }

      final bytes = await file.openRead(0, 100).toList();
      final firstBytes = bytes.expand((x) => x).take(10).toList();
      final header = String.fromCharCodes(firstBytes);

      if (!header.startsWith('%PDF')) {
        if (kDebugMode) debugPrint('Invalid PDF header: $pdfPath');
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error validating PDF file: $e');
      return false;
    }
  }
}
