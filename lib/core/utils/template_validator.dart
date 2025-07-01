// lib/utils/template_validator.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For Color and IconData
import '../../data/models/templates/pdf_template.dart'; // Import the updated model

class TemplateValidator {
  static const List<String> _essentialQuoteAppDatas = [
    'customerName',
    'quoteNumber',
    'grandTotal',
  ];

  static const List<String> _recommendedQuoteAppDatas = [
    'customerAddress',
    'quoteDate',
    'companyName',
    'subtotal',
    // 'taxAmount', // Tax is often calculated, so direct mapping might not always be present
  ];

  /// Validate a single PDF template based on the new model structure
  static Future<TemplateValidationResult> validateTemplate(PDFTemplate template) async {
    final result = TemplateValidationResult(template.id, template.templateName);

    try {
      // 1. Check if PDF file exists
      final pdfFile = File(template.pdfFilePath);
      if (!await pdfFile.exists()) {
        result.addError('Physical PDF file not found at: ${template.pdfFilePath}');
      } else {
        result.addSuccess('PDF file exists.');
        final fileSize = await pdfFile.length();
        if (fileSize > 15 * 1024 * 1024) { // 15MB warning
          result.addWarning('PDF file is large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). This might affect performance.');
        }
      }

      // 2. Check template basic properties
      if (template.templateName.trim().isEmpty) {
        result.addError('Template name is empty.');
      }
      if (template.pageWidth <= 0 || template.pageHeight <= 0) {
        result.addError('Invalid page dimensions (Width: ${template.pageWidth}, Height: ${template.pageHeight}). Re-upload PDF.');
      }

      // 3. Check field mappings
      if (template.fieldMappings.isEmpty) {
        result.addWarning('No fields mapped. The generated PDF will likely be mostly blank except for the background.');
      } else {
        final Set<String> mappedAppDataTypes = {};
        final Set<String> mappedPdfFieldNames = {};

        for (final FieldMapping field in template.fieldMappings) {
          // Validate individual field mapping
          _validateFieldMapping(field, template, result);

          if (field.appDataType.isNotEmpty && !field.appDataType.startsWith('unmapped_')) {
            mappedAppDataTypes.add(field.appDataType);
          }
          if (field.pdfFormFieldName.isNotEmpty) {
            if (mappedPdfFieldNames.contains(field.pdfFormFieldName)) {
              result.addWarning('PDF Form Field "${field.pdfFormFieldName}" is mapped multiple times. Ensure this is intended.');
            }
            mappedPdfFieldNames.add(field.pdfFormFieldName);
          }
        }

        // Check for essential application data types being mapped
        for (final essentialAppData in _essentialQuoteAppDatas) {
          if (!mappedAppDataTypes.contains(essentialAppData)) {
            result.addError('Essential app data field "${PDFTemplate.getFieldDisplayName(essentialAppData)}" is not mapped to any PDF field.');
          }
        }

        // Check for recommended application data types being mapped
        for (final recommendedAppData in _recommendedQuoteAppDatas) {
          if (!mappedAppDataTypes.contains(recommendedAppData)) {
            result.addWarning('Recommended app data field "${PDFTemplate.getFieldDisplayName(recommendedAppData)}" is not mapped.');
          }
        }

        // Check if all detected PDF fields (from metadata) are mapped, if that metadata exists
        final detectedFieldsMeta = template.metadata['detectedPdfFields'] as List<dynamic>?;
        if (detectedFieldsMeta != null) {
          int unmappedDetectedFields = 0;
          for (var detectedFieldInfo in detectedFieldsMeta) {
            if (detectedFieldInfo is Map) {
              final detectedName = detectedFieldInfo['name'] as String?;
              if (detectedName != null && !mappedPdfFieldNames.contains(detectedName)) {
                unmappedDetectedFields++;
              }
            }
          }
          if (unmappedDetectedFields > 0) {
            result.addWarning('$unmappedDetectedFields detected PDF form field(s) are not currently mapped to any app data.');
          }
        }


      }
    } catch (e) {
      result.addError('An unexpected error occurred during validation: $e');
      if (kDebugMode) {
        debugPrint('Template Validation Exception for ${template.id}: $e');
      }
    }
    return result;
  }

  /// Validate individual FieldMapping properties
  static void _validateFieldMapping(FieldMapping field, PDFTemplate template, TemplateValidationResult result) {
    if (field.appDataType.isEmpty || field.appDataType.startsWith('unmapped_')) {
      result.addWarning('Field linked to PDF field "${field.pdfFormFieldName}" has no Field Source assigned.');
    }
    if (field.pdfFormFieldName.isEmpty) {
      result.addError('Field Source "${PDFTemplate.getFieldDisplayName(field.appDataType)}" is not linked to any PDF Form Field.');
    }

    // Validate visual hints if they are populated (they are optional now)
    if (field.visualX != null && (field.visualX! < 0 || field.visualX! > 1)) {
      result.addWarning('Field mapping for "${field.pdfFormFieldName}" has visual X hint out of bounds: ${field.visualX}');
    }
    if (field.visualY != null && (field.visualY! < 0 || field.visualY! > 1)) {
      result.addWarning('Field mapping for "${field.pdfFormFieldName}" has visual Y hint out of bounds: ${field.visualY}');
    }
    if (field.visualWidth != null && (field.visualWidth! <= 0 || field.visualWidth! > 1)) {
      result.addWarning('Field mapping for "${field.pdfFormFieldName}" has visual Width hint out of bounds: ${field.visualWidth}');
    }
    if (field.visualHeight != null && (field.visualHeight! <= 0 || field.visualHeight! > 1)) {
      result.addWarning('Field mapping for "${field.pdfFormFieldName}" has visual Height hint out of bounds: ${field.visualHeight}');
    }

    if (field.pageNumber < 0 || field.pageNumber >= template.totalPages) {
      result.addError('Field mapping for "${field.pdfFormFieldName}" has invalid page number: ${field.pageNumber + 1} (Total pages: ${template.totalPages})');
    }

    // Validate override properties if they are set
    if (field.fontSizeOverride != null && (field.fontSizeOverride! < 4 || field.fontSizeOverride! > 100)) {
      result.addWarning('Field mapping for "${field.pdfFormFieldName}" has an unusual font size override: ${field.fontSizeOverride}pt');
    }
    if (field.fontColorOverride != null && !_isValidHexColor(field.fontColorOverride!)) {
      result.addError('Field mapping for "${field.pdfFormFieldName}" has an invalid font color override: ${field.fontColorOverride}');
    }
  }

  static Future<List<TemplateValidationResult>> validateTemplates(List<PDFTemplate> templates) async {
    final results = <TemplateValidationResult>[];
    for (final template in templates) {
      results.add(await validateTemplate(template));
    }
    return results;
  }

  static Future<bool> isTemplateUsable(PDFTemplate template) async {
    final result = await validateTemplate(template);
    return result.isUsable;
  }

  static Future<int> getTemplateHealthScore(PDFTemplate template) async {
    final result = await validateTemplate(template);
    return result.healthScore;
  }

  static bool _isValidHexColor(String color) {
    final hexPattern = RegExp(r'^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$'); // Allow alpha
    return hexPattern.hasMatch(color);
  }

  static List<String> getTemplateRecommendations(PDFTemplate template, TemplateValidationResult validationResult) {
    final recommendations = <String>[];

    if (validationResult.errors.any((e) => e.contains("not mapped to any PDF field"))) {
      recommendations.add('Map all essential app data fields to corresponding PDF form fields in the editor.');
    }
    if (validationResult.warnings.any((w) => w.contains("not currently mapped"))) {
      recommendations.add('Consider mapping more of the detected PDF form fields to make your template more dynamic.');
    }
    if (template.description.isEmpty) {
      recommendations.add('Add a description to this template to clarify its purpose or version.');
    }
    if (validationResult.warnings.any((w) => w.contains("PDF file is large"))) {
      recommendations.add('The PDF file is large. Consider optimizing it for smaller size if possible.');
    }
    if (recommendations.isEmpty && validationResult.isUsable) {
      recommendations.add('Template looks good! Review field mappings for accuracy.');
    }
    if(!validationResult.isUsable){
      recommendations.add('Address critical errors before using this template.');
    }

    return recommendations;
  }
}

class TemplateValidationResult {
  final String templateId;
  final String templateName; // Added for better context in results
  final List<String> errors = [];
  final List<String> warnings = [];
  final List<String> successes = [];

  TemplateValidationResult(this.templateId, this.templateName);

  void addError(String message) {
    errors.add(message);
    if (kDebugMode) debugPrint('❌ Validation Error ($templateName): $message');
  }

  void addWarning(String message) {
    warnings.add(message);
    if (kDebugMode) debugPrint('⚠️ Validation Warning ($templateName): $message');
  }

  void addSuccess(String message) {
    successes.add(message);
    if (kDebugMode) debugPrint('✅ Validation Success ($templateName): $message');
  }

  bool get isUsable => errors.isEmpty;
  bool get isPerfect => errors.isEmpty && warnings.isEmpty;

  int get healthScore {
    if (!isUsable) return 0;
    int score = 100;
    score -= warnings.length * 5; // Each warning deducts 5 points
    return score.clamp(0, 100);
  }

  TemplateStatus get status {
    if (errors.isNotEmpty) return TemplateStatus.error;
    if (warnings.isNotEmpty) return TemplateStatus.warning;
    return TemplateStatus.healthy;
  }

  Color get statusColor {
    switch (status) {
      case TemplateStatus.error: return Colors.red.shade700;
      case TemplateStatus.warning: return Colors.orange.shade700;
      case TemplateStatus.healthy: return Colors.green.shade700;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TemplateStatus.error: return Icons.error_outline;
      case TemplateStatus.warning: return Icons.warning_amber_outlined;
      case TemplateStatus.healthy: return Icons.check_circle_outline;
    }
  }

  String get summary {
    if (errors.isNotEmpty) return '${errors.length} Error(s), ${warnings.length} Warning(s)';
    if (warnings.isNotEmpty) return '${warnings.length} Warning(s)';
    return 'Healthy';
  }

  @override
  String toString() {
    return 'TemplateValidationResult(id: $templateId, name: $templateName, status: $status, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}

enum TemplateStatus { healthy, warning, error }

extension TemplateValidationExtensions on List<TemplateValidationResult> {
  List<TemplateValidationResult> get withErrors => where((r) => r.errors.isNotEmpty).toList();
  List<TemplateValidationResult> get withWarnings => where((r) => r.warnings.isNotEmpty && r.errors.isEmpty).toList();
  List<TemplateValidationResult> get healthy => where((r) => r.isPerfect).toList();
  double get overallHealthPercentage {
    if (isEmpty) return 100.0;
    return fold<double>(0, (sum, r) => sum + r.healthScore) / length;
  }
}