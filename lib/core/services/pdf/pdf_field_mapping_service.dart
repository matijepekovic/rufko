// lib/services/pdf_field_mapping_service.dart

import 'package:intl/intl.dart';
import '../../../data/models/business/customer.dart';
import '../../../data/models/business/simplified_quote.dart';
import "../../../data/models/templates/pdf_template.dart";
import '../../../data/providers/state/app_state_provider.dart';

/// Handles mapping of PDF template fields to display names and values.
class PdfFieldMappingService {
  static final PdfFieldMappingService _instance =
      PdfFieldMappingService._internal();
  factory PdfFieldMappingService() => _instance;
  PdfFieldMappingService._internal();

  static PdfFieldMappingService get instance => _instance;

  final Map<String, String> _displayNames = const {
    'customerName': 'Customer Name',
    'customerPhone': 'Phone Number',
    'customerEmail': 'Email Address',
    'quoteNumber': 'Quote Number',
    'quoteDate': 'Quote Date',
    'notes': 'Notes',
    'terms': 'Terms & Conditions',
    'companyName': 'Company Name',
    'companyPhone': 'Company Phone',
    'companyEmail': 'Company Email',
  };

  /// Return a human friendly display name for a template field.
  String getFieldDisplayName(String fieldName) {
    return _displayNames[fieldName] ??
        fieldName.replaceAll('_', ' ').toUpperCase();
  }

  /// Calculate the current value for a template field using the provided data.
  String getCurrentFieldValue(
    String fieldName, {
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
  }) {
    final lower = fieldName.toLowerCase();

    // Customer fields
    if (lower.contains('customer')) {
      if (lower.contains('name')) return customer?.name ?? '';
      if (lower.contains('phone')) return customer?.phone ?? '';
      if (lower.contains('email')) return customer?.email ?? '';
      if (lower.contains('address')) return customer?.fullDisplayAddress ?? '';
      if (lower.contains('street')) return customer?.streetAddress ?? '';
      if (lower.contains('city')) return customer?.city ?? '';
      if (lower.contains('state')) return customer?.stateAbbreviation ?? '';
      if (lower.contains('zip')) return customer?.zipCode ?? '';
    }

    // Quote fields
    if (lower.contains('quote')) {
      if (lower.contains('number')) return quote?.quoteNumber ?? '';
      if (lower.contains('date')) {
        return quote != null
            ? DateFormat('MM/dd/yyyy').format(quote.createdAt)
            : '';
      }
      if (lower.contains('status')) return quote?.status ?? '';
    }

    // Company fields
    if (lower.contains('company')) {
      if (lower.contains('name')) return 'Your Company Name';
      if (lower.contains('phone')) return '(555) 123-4567';
      if (lower.contains('email')) return 'info@yourcompany.com';
      if (lower.contains('address')) return '123 Main St, Your City, ST 12345';
    }

    // Date fields
    if (lower.contains('date')) {
      if (lower.contains('today')) {
        return DateFormat('MM/dd/yyyy').format(DateTime.now());
      }
      if (lower.contains('valid')) {
        return quote != null
            ? DateFormat('MM/dd/yyyy').format(quote.validUntil)
            : '';
      }
    }

    // Generic text fields
    if (lower.contains('note')) return quote?.notes ?? '';
    if (lower.contains('term')) return 'Standard terms and conditions apply...';

    return '';
  }

  /// Return the list of editable field names for the given template.
  List<String> getEditableFields(String templateId, AppStateProvider appState) {
    final template = appState.pdfTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found'),
    );

    return template.fieldMappings
        .where((m) => m.pdfFormFieldName.isNotEmpty)
        .map((m) => m.appDataType)
        .toList();
  }

  /// Link [appDataType] to a PDF field described by [pdfFieldInfo] on [template].
  void performMapping(
    PDFTemplate template,
    String appDataType,
    Map<String, dynamic> pdfFieldInfo,
  ) {
    final pdfFieldName = pdfFieldInfo['name'] as String;

    template.fieldMappings.removeWhere((m) => m.appDataType == appDataType);
    template.fieldMappings.removeWhere((m) => m.pdfFormFieldName == pdfFieldName);

    final mapping = FieldMapping(
      appDataType: appDataType,
      pdfFormFieldName: pdfFieldName,
      detectedPdfFieldType: PdfFormFieldType.values.firstWhere(
        (e) => e.toString() == pdfFieldInfo['type'],
        orElse: () => PdfFormFieldType.unknown,
      ),
      pageNumber: pdfFieldInfo['page'] as int,
    );

    final relRect = pdfFieldInfo['relativeRect'] as List<dynamic>?;
    if (relRect != null && relRect.length == 4) {
      mapping.visualX = relRect[0] as double?;
      mapping.visualY = relRect[1] as double?;
      mapping.visualWidth = relRect[2] as double?;
      mapping.visualHeight = relRect[3] as double?;
    }

    template.addField(mapping);
  }

  /// Remove the mapping information for [mapping] on [template].
  void unlinkField(PDFTemplate template, FieldMapping mapping) {
    mapping
      ..pdfFormFieldName = ''
      ..detectedPdfFieldType = PdfFormFieldType.unknown
      ..visualX = null
      ..visualY = null
      ..visualWidth = null
      ..visualHeight = null;
    template.updateField(mapping);
  }
}
