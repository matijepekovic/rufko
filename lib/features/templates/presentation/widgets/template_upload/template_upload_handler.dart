import 'package:flutter/material.dart';
import '../../controllers/template_upload_ui_controller.dart';
import '../../../../../data/models/templates/pdf_template.dart';

/// Widget that handles UI concerns for template upload operations
/// Separates UI concerns from business logic by managing dialogs, snackbars, and loading states
class TemplateUploadHandler extends StatefulWidget {
  final TemplateUploadUIController controller;
  final Widget child;

  const TemplateUploadHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<TemplateUploadHandler> createState() => _TemplateUploadHandlerState();
}

class _TemplateUploadHandlerState extends State<TemplateUploadHandler> {
  /// Public methods for backward compatibility and external access
  Future<PDFTemplate?> uploadAndCreateTemplate({
    required Future<String?> Function(String) onTemplateNameRequired,
  }) => _uploadAndCreateTemplate(onTemplateNameRequired: onTemplateNameRequired);
  
  Future<String?> pickPdfFile() => _pickPdfFile();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanges);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanges);
    super.dispose();
  }

  void _handleControllerChanges() {
    // Handle error messages
    final errorMessage = widget.controller.lastError;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }

    // Handle success messages
    final successMessage = widget.controller.lastSuccess;
    if (successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }
  }

  /// Upload file and create template (legacy compatibility method)
  Future<PDFTemplate?> _uploadAndCreateTemplate({
    required Future<String?> Function(String) onTemplateNameRequired,
  }) async {
    // First pick the file
    final filePath = await widget.controller.pickPdfFile();
    if (filePath == null || !mounted) return null;

    // Extract suggested name and get user input
    final fileName = filePath.split('/').last;
    final suggestedName = widget.controller.getSuggestedTemplateName(fileName);
    
    final templateName = await onTemplateNameRequired(suggestedName);
    if (templateName == null || templateName.trim().isEmpty) {
      return null;
    }

    // Create template from selected file
    return widget.controller.createTemplateFromFile(
      filePath: filePath,
      templateName: templateName.trim(),
    );
  }

  /// Pick PDF file only
  Future<String?> _pickPdfFile() async {
    return widget.controller.pickPdfFile();
  }

  /// Show template name input dialog
  Future<String?> showTemplateNameDialog(String suggestedName) async {
    final controller = TextEditingController(text: suggestedName);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this template:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    ).then((value) {
      controller.dispose();
      return value;
    });
  }

  /// Upload and create template with built-in name dialog
  Future<PDFTemplate?> uploadAndCreateTemplateWithDialog() async {
    return _uploadAndCreateTemplate(
      onTemplateNameRequired: showTemplateNameDialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            if (widget.controller.isUploading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (widget.controller.uploadMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.controller.uploadMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}