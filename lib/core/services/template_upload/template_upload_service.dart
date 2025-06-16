import 'package:file_picker/file_picker.dart';
import '../../../data/models/templates/pdf_template.dart';
import '../../../data/providers/state/app_state_provider.dart';
import '../template_management_service.dart';

/// Result object for template upload operations
class TemplateUploadResult {
  final bool isSuccess;
  final String? message;
  final PDFTemplate? template;
  final String? filePath;

  const TemplateUploadResult._({
    required this.isSuccess,
    this.message,
    this.template,
    this.filePath,
  });

  factory TemplateUploadResult.success({
    String? message,
    PDFTemplate? template,
    String? filePath,
  }) {
    return TemplateUploadResult._(
      isSuccess: true,
      message: message,
      template: template,
      filePath: filePath,
    );
  }

  factory TemplateUploadResult.error(String message) {
    return TemplateUploadResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Service layer for template upload operations
/// Contains pure business logic without UI dependencies
class TemplateUploadService {
  /// Pick PDF file from device
  Future<TemplateUploadResult> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        if (_validatePdfFile(filePath)) {
          return TemplateUploadResult.success(
            message: 'PDF file selected: $fileName',
            filePath: filePath,
          );
        } else {
          return TemplateUploadResult.error('Invalid PDF file selected');
        }
      } else {
        return TemplateUploadResult.error('No file selected');
      }
    } catch (e) {
      return TemplateUploadResult.error('Error selecting file: $e');
    }
  }

  /// Create template from uploaded PDF file
  Future<TemplateUploadResult> createTemplateFromFile({
    required String filePath,
    required String templateName,
    required AppStateProvider appState,
  }) async {
    try {
      if (templateName.trim().isEmpty) {
        return TemplateUploadResult.error('Template name cannot be empty');
      }

      if (!_validatePdfFile(filePath)) {
        return TemplateUploadResult.error('Invalid PDF file');
      }

      // Create template using existing service
      final template = await TemplateManagementService.instance
          .uploadAndCreateTemplate(filePath, templateName.trim(), appState);

      if (template != null) {
        return TemplateUploadResult.success(
          message: 'Template created successfully',
          template: template,
        );
      } else {
        return TemplateUploadResult.error('Failed to create template');
      }
    } catch (e) {
      return TemplateUploadResult.error('Error creating template: $e');
    }
  }

  /// Upload and create template in one operation
  Future<TemplateUploadResult> uploadAndCreateTemplate({
    required String templateName,
    required AppStateProvider appState,
  }) async {
    // First pick the file
    final pickResult = await pickPdfFile();
    if (!pickResult.isSuccess) {
      return pickResult;
    }

    // Then create template from picked file
    return createTemplateFromFile(
      filePath: pickResult.filePath!,
      templateName: templateName,
      appState: appState,
    );
  }

  /// Extract suggested template name from file name
  String extractSuggestedName(String fileName) {
    return fileName.replaceAll('.pdf', '').replaceAll('_', ' ').trim();
  }

  /// Validate PDF file
  bool _validatePdfFile(String filePath) {
    try {
      // Basic validation - check if file has .pdf extension
      return filePath.toLowerCase().endsWith('.pdf');
    } catch (e) {
      return false;
    }
  }

  /// Get file name from path
  String getFileNameFromPath(String filePath) {
    return filePath.split('/').last;
  }
}