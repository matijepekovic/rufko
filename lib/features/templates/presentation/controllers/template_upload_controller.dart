import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/template_management_service.dart';

/// Controller for template file upload operations
/// Handles PDF file selection, processing, and template creation
class TemplateUploadController extends ChangeNotifier {
  final BuildContext _context;
  
  bool _isUploading = false;
  String _uploadMessage = '';

  TemplateUploadController(this._context);

  // Getters
  bool get isUploading => _isUploading;
  String get uploadMessage => _uploadMessage;

  AppStateProvider get _appState => _context.read<AppStateProvider>();
  ScaffoldMessengerState get _messenger => ScaffoldMessenger.of(_context);

  /// Set upload loading state
  void setUploading(bool isUploading, [String message = '']) {
    if (!_context.mounted) return;
    _isUploading = isUploading;
    _uploadMessage = message;
    notifyListeners();
  }

  /// Upload PDF file and create template
  Future<PDFTemplate?> uploadAndCreateTemplate({
    required Future<String?> Function(String) onTemplateNameRequired,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setUploading(true, 'Processing PDF & Detecting Fields...');

        final filePath = result.files.single.path!;
        final originalFileName = result.files.single.name;

        // Get template name from callback
        final templateName = await onTemplateNameRequired(
            originalFileName.replaceAll('.pdf', ''));
        if (templateName == null || templateName.trim().isEmpty) {
          setUploading(false);
          return null;
        }

        // Create template using service
        final template = await TemplateManagementService.instance
            .uploadAndCreateTemplate(filePath, templateName.trim(), _appState);
        setUploading(false);

        if (!_context.mounted) return template;
        
        if (template != null) {
          _messenger.showSnackBar(
            const SnackBar(
              content: Text('Template created!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          return template;
        } else {
          _messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to create template.'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
      }
      return null;
    } catch (e) {
      setUploading(false);
      if (!_context.mounted) return null;
      
      _messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      if (kDebugMode) debugPrint('Error uploading/creating template: $e');
      return null;
    }
  }

  /// Pick PDF file only (without creating template)
  Future<String?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking PDF file: $e');
      if (_context.mounted) {
        _messenger.showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Validate PDF file
  bool validatePdfFile(String filePath) {
    try {
      // Basic validation - check if file exists and has .pdf extension
      return filePath.toLowerCase().endsWith('.pdf');
    } catch (e) {
      if (kDebugMode) debugPrint('Error validating PDF file: $e');
      return false;
    }
  }

}