// lib/services/template_management_service.dart

import 'package:flutter/foundation.dart';

import '../../data/models/templates/pdf_template.dart';
import '../../data/providers/state/app_state_provider.dart';
import '../utils/template_validator.dart';

class TemplateManagementService {
  TemplateManagementService._internal();
  static final TemplateManagementService instance =
      TemplateManagementService._internal();

  /// Create a [PDFTemplate] from a picked PDF file path and template name.
  Future<PDFTemplate?> uploadAndCreateTemplate(
    String pdfPath,
    String templateName,
    AppStateProvider appState,
  ) async {
    try {
      return await appState.createPDFTemplateFromFile(pdfPath, templateName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TemplateManagementService upload error: $e');
      }
      rethrow;
    }
  }

  /// Persist updates to a [PDFTemplate].
  Future<void> saveTemplate(
    PDFTemplate template,
    AppStateProvider appState,
  ) async {
    try {
      template.updatedAt = DateTime.now();
      await appState.updatePDFTemplate(template);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TemplateManagementService save error: $e');
      }
      rethrow;
    }
  }

  /// Generate a populated preview PDF for [template].
  Future<String> generateTemplatePreview(
    PDFTemplate template,
    AppStateProvider appState,
  ) async {
    try {
      return await appState.generateTemplatePreview(template);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TemplateManagementService preview error: $e');
      }
      rethrow;
    }
  }

  /// Validate [template] and return the [TemplateValidationResult].
  Future<TemplateValidationResult> validateTemplate(PDFTemplate template) async {
    return TemplateValidator.validateTemplate(template);
  }
}
