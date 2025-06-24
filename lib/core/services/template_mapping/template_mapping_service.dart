import '../../../data/models/templates/pdf_template.dart';
import '../pdf/pdf_field_mapping_service.dart';

/// Result object for template field mapping operations
class TemplateMappingResult {
  final bool isSuccess;
  final String? message;
  final PDFTemplate? template;
  final String? fieldName;

  const TemplateMappingResult._({
    required this.isSuccess,
    this.message,
    this.template,
    this.fieldName,
  });

  factory TemplateMappingResult.success({
    String? message,
    PDFTemplate? template,
    String? fieldName,
  }) {
    return TemplateMappingResult._(
      isSuccess: true,
      message: message,
      template: template,
      fieldName: fieldName,
    );
  }

  factory TemplateMappingResult.error(String message) {
    return TemplateMappingResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Service layer for template field mapping operations
/// Contains pure business logic without UI dependencies
class TemplateMappingService {
  /// Create field mapping between app data and PDF field
  TemplateMappingResult createFieldMapping({
    required PDFTemplate template,
    required String appDataType,
    required Map<String, dynamic> pdfFieldInfo,
    required bool replaceExisting,
  }) {
    try {
      final pdfFieldName = pdfFieldInfo['name'] as String?;
      if (pdfFieldName == null || pdfFieldName.isEmpty) {
        return TemplateMappingResult.error('Invalid PDF field name');
      }

      // Check if this app data type is already mapped to another field
      final existingMapping = template.fieldMappings
          .where((m) => m.appDataType == appDataType)
          .firstOrNull;

      if (existingMapping != null && !replaceExisting) {
        return TemplateMappingResult.error(
          'App data field "$appDataType" is already mapped to "${existingMapping.pdfFormFieldName}". '
          'Use replaceExisting=true to replace the mapping.',
        );
      }

      // Perform the mapping using existing service
      PdfFieldMappingService.instance.performMapping(
        template,
        appDataType,
        pdfFieldInfo,
      );

      template.updatedAt = DateTime.now();

      final displayName = PDFTemplate.getFieldDisplayName(appDataType);
      return TemplateMappingResult.success(
        message: 'Linked "$displayName" to "$pdfFieldName"',
        template: template,
        fieldName: pdfFieldName,
      );
    } catch (e) {
      return TemplateMappingResult.error('Failed to create field mapping: $e');
    }
  }

  /// Remove field mapping
  TemplateMappingResult removeFieldMapping({
    required PDFTemplate template,
    required dynamic mapping, // FieldMapping type
  }) {
    try {
      // Use existing service to unlink
      PdfFieldMappingService.instance.unlinkField(template, mapping);

      return TemplateMappingResult.success(
        message: 'Field mapping removed successfully',
        template: template,
      );
    } catch (e) {
      return TemplateMappingResult.error('Failed to remove field mapping: $e');
    }
  }

  /// Get existing mapping for PDF field
  dynamic getExistingMapping({
    required PDFTemplate template,
    required String pdfFieldName,
  }) {
    try {
      return template.fieldMappings.firstWhere(
        (m) => m.pdfFormFieldName == pdfFieldName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if app data field is already mapped
  bool isAppDataFieldMapped({
    required PDFTemplate template,
    required String appDataType,
  }) {
    return template.fieldMappings
        .any((m) => m.appDataType == appDataType);
  }

  /// Get all available app data fields
  List<String> getAvailableAppDataFields({
    required List<dynamic> products,
    required List<dynamic> customFields,
  }) {
    // This would return a comprehensive list of available fields
    // For now, return a basic list
    return [
      'customerName',
      'customerPhone',
      'customerEmail',
      'customerAddress',
      'quoteNumber',
      'quoteDate',
      'quoteTotal',
      'notes',
      'terms',
      'companyName',
      'companyPhone',
      'companyEmail',
    ];
  }

  /// Validate mapping operation
  TemplateMappingResult validateMapping({
    required PDFTemplate template,
    required String appDataType,
    required Map<String, dynamic> pdfFieldInfo,
  }) {
    if (appDataType.isEmpty) {
      return TemplateMappingResult.error('App data type cannot be empty');
    }

    final pdfFieldName = pdfFieldInfo['name'] as String?;
    if (pdfFieldName == null || pdfFieldName.isEmpty) {
      return TemplateMappingResult.error('PDF field name cannot be empty');
    }

    return TemplateMappingResult.success(message: 'Mapping is valid');
  }
}