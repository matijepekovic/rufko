// lib/utils/template_validator.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/pdf_template.dart';

class TemplateValidator {
  static const List<String> _essentialQuoteFields = [
    'customerName',
    'quoteNumber',
    'grandTotal',
  ];

  static const List<String> _recommendedQuoteFields = [
    'customerAddress',
    'quoteDate',
    'companyName',
    'subtotal',
    'taxAmount',
  ];

  /// Validate a single PDF template
  static Future<TemplateValidationResult> validateTemplate(PDFTemplate template) async {
    final result = TemplateValidationResult(template.id);

    try {
      // Check if PDF file exists
      final pdfFile = File(template.pdfFilePath);
      if (!await pdfFile.exists()) {
        result.addError('PDF file not found: ${template.pdfFilePath}');
      } else {
        result.addSuccess('PDF file exists');

        // Check file size (warn if very large)
        final fileSize = await pdfFile.length();
        if (fileSize > 10 * 1024 * 1024) { // 10MB
          result.addWarning('PDF file is large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)');
        }
      }

      // Check template basic properties
      if (template.templateName.trim().isEmpty) {
        result.addError('Template name is empty');
      }

      if (template.fieldMappings.isEmpty) {
        result.addWarning('No fields mapped - template will generate empty PDF');
      }

      // Check for essential quote fields
      final mappedFieldTypes = template.fieldMappings.map((f) => f.fieldType).toSet();

      for (final essentialField in _essentialQuoteFields) {
        if (!mappedFieldTypes.contains(essentialField)) {
          result.addError('Missing essential field: ${PDFTemplate.getFieldDisplayName(essentialField)}');
        }
      }

      // Check for recommended fields
      for (final recommendedField in _recommendedQuoteFields) {
        if (!mappedFieldTypes.contains(recommendedField)) {
          result.addWarning('Missing recommended field: ${PDFTemplate.getFieldDisplayName(recommendedField)}');
        }
      }

      // Validate field mappings
      for (final field in template.fieldMappings) {
        _validateFieldMapping(field, result);
      }

      // Check for duplicate field types (warn if multiple fields of same type)
      final fieldTypeCounts = <String, int>{};
      for (final field in template.fieldMappings) {
        fieldTypeCounts[field.fieldType] = (fieldTypeCounts[field.fieldType] ?? 0) + 1;
      }

      for (final entry in fieldTypeCounts.entries) {
        if (entry.value > 1) {
          result.addWarning('Multiple fields of type "${PDFTemplate.getFieldDisplayName(entry.key)}" (${entry.value} found)');
        }
      }

    } catch (e) {
      result.addError('Validation error: $e');
    }

    return result;
  }

  /// Validate field mapping properties
  static void _validateFieldMapping(FieldMapping field, TemplateValidationResult result) {
    // Check coordinates are within bounds
    if (field.x < 0 || field.x > 1) {
      result.addError('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" X position out of bounds: ${field.x}');
    }

    if (field.y < 0 || field.y > 1) {
      result.addError('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" Y position out of bounds: ${field.y}');
    }

    // Check size is reasonable
    if (field.width <= 0 || field.width > 1) {
      result.addError('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" width out of bounds: ${field.width}');
    }

    if (field.height <= 0 || field.height > 1) {
      result.addError('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" height out of bounds: ${field.height}');
    }

    // Check field doesn't extend beyond page bounds
    if (field.x + field.width > 1) {
      result.addWarning('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" extends beyond right edge');
    }

    if (field.y + field.height > 1) {
      result.addWarning('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" extends beyond bottom edge');
    }

    // Check font size is reasonable
    if (field.fontSize < 6 || field.fontSize > 72) {
      result.addWarning('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" font size may be too ${field.fontSize < 6 ? 'small' : 'large'}: ${field.fontSize}pt');
    }

    // Check color format
    if (!_isValidHexColor(field.fontColor)) {
      result.addError('Field "${PDFTemplate.getFieldDisplayName(field.fieldType)}" has invalid color: ${field.fontColor}');
    }
  }

  /// Validate multiple templates
  static Future<List<TemplateValidationResult>> validateTemplates(List<PDFTemplate> templates) async {
    final results = <TemplateValidationResult>[];

    for (final template in templates) {
      final result = await validateTemplate(template);
      results.add(result);
    }

    return results;
  }

  /// Quick check if template is usable
  static Future<bool> isTemplateUsable(PDFTemplate template) async {
    final result = await validateTemplate(template);
    return result.isUsable;
  }

  /// Get template health score (0-100)
  static Future<int> getTemplateHealthScore(PDFTemplate template) async {
    final result = await validateTemplate(template);
    return result.healthScore;
  }

  /// Check if hex color string is valid
  static bool _isValidHexColor(String color) {
    final hexPattern = RegExp(r'^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexPattern.hasMatch(color);
  }

  /// Get template usage recommendations
  static List<String> getTemplateRecommendations(PDFTemplate template) {
    final recommendations = <String>[];

    // Check field coverage
    final mappedFields = template.fieldMappings.map((f) => f.fieldType).toSet();

    if (!mappedFields.contains('customerName')) {
      recommendations.add('Add customer name field for personalization');
    }

    if (!mappedFields.contains('companyName')) {
      recommendations.add('Add company name field for branding');
    }

    if (template.fieldMappings.length < 5) {
      recommendations.add('Consider adding more fields for comprehensive quotes');
    }

    // Check template metadata
    if (template.description.isEmpty) {
      recommendations.add('Add a description to help identify this template\'s purpose');
    }

    return recommendations;
  }
}

/// Result of template validation
class TemplateValidationResult {
  final String templateId;
  final List<String> errors = [];
  final List<String> warnings = [];
  final List<String> successes = [];

  TemplateValidationResult(this.templateId);

  void addError(String message) {
    errors.add(message);
    if (kDebugMode) {
      print('❌ Template $templateId: $message');
    }
  }

  void addWarning(String message) {
    warnings.add(message);
    if (kDebugMode) {
      print('⚠️ Template $templateId: $message');
    }
  }

  void addSuccess(String message) {
    successes.add(message);
    if (kDebugMode) {
      print('✅ Template $templateId: $message');
    }
  }

  /// Whether template can be used despite issues
  bool get isUsable => errors.isEmpty;

  /// Whether template is in perfect condition
  bool get isPerfect => errors.isEmpty && warnings.isEmpty;

  /// Health score from 0-100
  int get healthScore {
    if (errors.isNotEmpty) {
      return 0; // Unusable
    }

    final maxWarnings = 10; // Assume max reasonable warnings
    final warningPenalty = (warnings.length / maxWarnings * 30).clamp(0, 30);

    return (100 - warningPenalty).round();
  }

  /// Get overall status
  TemplateStatus get status {
    if (errors.isNotEmpty) return TemplateStatus.error;
    if (warnings.isNotEmpty) return TemplateStatus.warning;
    return TemplateStatus.healthy;
  }

  /// Get status color for UI
  Color get statusColor {
    switch (status) {
      case TemplateStatus.error:
        return const Color(0xFFD32F2F); // Red
      case TemplateStatus.warning:
        return const Color(0xFFF57C00); // Orange
      case TemplateStatus.healthy:
        return const Color(0xFF388E3C); // Green
    }
  }

  /// Get status icon for UI
  IconData get statusIcon {
    switch (status) {
      case TemplateStatus.error:
        return Icons.error;
      case TemplateStatus.warning:
        return Icons.warning;
      case TemplateStatus.healthy:
        return Icons.check_circle;
    }
  }

  /// Get human-readable summary
  String get summary {
    if (errors.isNotEmpty) {
      return '${errors.length} error(s), ${warnings.length} warning(s)';
    } else if (warnings.isNotEmpty) {
      return '${warnings.length} warning(s)';
    } else {
      return 'Template is healthy';
    }
  }

  @override
  String toString() {
    return 'TemplateValidationResult(id: $templateId, status: $status, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}

enum TemplateStatus {
  healthy,
  warning,
  error,
}

/// Template validation extensions
extension TemplateValidationExtensions on List<TemplateValidationResult> {
  /// Get all templates with errors
  List<TemplateValidationResult> get withErrors => where((r) => r.errors.isNotEmpty).toList();

  /// Get all templates with warnings
  List<TemplateValidationResult> get withWarnings => where((r) => r.warnings.isNotEmpty).toList();

  /// Get all healthy templates
  List<TemplateValidationResult> get healthy => where((r) => r.isPerfect).toList();

  /// Get overall health percentage
  double get overallHealthPercentage {
    if (isEmpty) return 100.0;
    final totalScore = fold<int>(0, (sum, result) => sum + result.healthScore);
    return totalScore / length;
  }
}