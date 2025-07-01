import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/template_upload/template_upload_service.dart';
import 'template_upload_ui_controller.dart';
import '../widgets/template_upload/template_upload_handler.dart';

/// Refactored TemplateUploadController using clean architecture
/// Now acts as a coordinator between UI and business logic
class TemplateUploadController extends ChangeNotifier {
  TemplateUploadController(BuildContext context)
      : _uiController = TemplateUploadUIController.fromContext(context),
        _context = context,
        _uploadService = TemplateUploadService();

  final TemplateUploadUIController _uiController;
  final BuildContext _context;
  final TemplateUploadService _uploadService;

  /// Get the UI controller for use in widgets
  TemplateUploadUIController get uiController => _uiController;

  /// Create a handler widget that manages UI concerns
  Widget createTemplateUploadHandler({
    Key? key,
    required Widget child,
  }) {
    return TemplateUploadHandler(
      key: key,
      controller: _uiController,
      child: child,
    );
  }

  // Legacy getters for backward compatibility
  bool get isUploading => _uiController.isUploading;
  String get uploadMessage => _uiController.uploadMessage ?? '';

  /// Legacy methods for backward compatibility - now delegate to service
  @Deprecated('Use TemplateUploadHandler.uploadAndCreateTemplate() in new architecture')
  Future<PDFTemplate?> uploadAndCreateTemplate({
    required Future<String?> Function(String) onTemplateNameRequired,
  }) async {
    try {
      // Pick PDF file first
      final fileResult = await _uploadService.pickPdfFile();
      if (!fileResult.isSuccess) {
        if (_context.mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            SnackBar(
              content: Text(fileResult.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Get template name from caller
      final templateName = await onTemplateNameRequired(fileResult.filePath!);
      if (templateName == null || templateName.trim().isEmpty) {
        return null;
      }

      // Create template
      if (!_context.mounted) return null;
      final appState = _context.read<AppStateProvider>();
      final createResult = await _uploadService.createTemplateFromFile(
        filePath: fileResult.filePath!,
        templateName: templateName.trim(),
        appState: appState,
      );

      if (!_context.mounted) return null;
      
      if (createResult.isSuccess) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Template "${templateName.trim()}" created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return createResult.template;
      } else {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text(createResult.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    } catch (e) {
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Error uploading template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @Deprecated('Use TemplateUploadHandler.pickPdfFile() in new architecture')
  Future<String?> pickPdfFile() async {
    try {
      final result = await _uploadService.pickPdfFile();
      return result.isSuccess ? result.filePath : null;
    } catch (e) {
      return null;
    }
  }

  @Deprecated('Use TemplateUploadService validation in new architecture')
  bool validatePdfFile(String filePath) {
    // Legacy implementation - validation now handled by service layer
    return filePath.toLowerCase().endsWith('.pdf');
  }

  @Deprecated('Use TemplateUploadUIController state management in new architecture')
  void setUploading(bool isUploading, [String message = '']) {
    // Legacy method - state management now handled by UI controller
    debugPrint('setUploading() called - state management handled by TemplateUploadUIController in new architecture');
  }

  /// Clean up resources
  @override
  void dispose() {
    _uiController.dispose();
    super.dispose();
  }
}