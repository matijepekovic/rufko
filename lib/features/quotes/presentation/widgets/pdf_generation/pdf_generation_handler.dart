import 'package:flutter/material.dart';
import '../../controllers/pdf_generation_ui_controller.dart';
import '../../screens/pdf_preview_screen.dart';
import '../dialogs/template_selection_dialog.dart';
import '../../../../../data/models/templates/pdf_template.dart';

/// Widget that handles UI concerns for PDF generation operations
/// Separates UI concerns from business logic by managing dialogs, navigation, and feedback
class PDFGenerationHandler extends StatefulWidget {
  final PDFGenerationUIController controller;
  final Widget child;

  const PDFGenerationHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<PDFGenerationHandler> createState() => _PDFGenerationHandlerState();
}

class _PDFGenerationHandlerState extends State<PDFGenerationHandler> {
  /// Public methods for backward compatibility
  Future<void> previewExistingPdf() => _previewExistingPdf();
  Future<void> generateAndPreviewPdf() => _generateAndPreviewPdf();
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanges);
    // Load available templates when handler is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadAvailableTemplates(context);
    });
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
              backgroundColor: errorMessage.contains('No saved PDF') 
                  ? Colors.orange 
                  : Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
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
              action: successMessage.contains('Preview generated')
                  ? SnackBarAction(
                      label: 'Open',
                      onPressed: () {
                        // Could trigger preview opening here if needed
                      },
                    )
                  : null,
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }
  }

  /// Show template selection dialog
  Future<String?> showTemplateSelectionDialog() async {
    final templates = widget.controller.availableTemplates ?? [];
    
    return showDialog<String>(
      context: context,
      builder: (_) => TemplateSelectionDialog(
        templates: templates,
        onPreviewTemplate: _previewTemplate,
      ),
    );
  }

  /// Preview PDF from existing file
  Future<void> _previewExistingPdf() async {
    final pdfPath = await widget.controller.checkExistingPdf(context);
    
    if (pdfPath != null) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfPath: pdfPath,
              suggestedFileName: 'existing_quote.pdf',
              quote: widget.controller.quote,
              customer: widget.controller.customer,
              title: 'Saved PDF Preview',
              isPreview: true,
            ),
          ),
        );
      }
    }
  }

  /// Generate and preview new PDF
  Future<void> _generateAndPreviewPdf() async {
    // Show template selection
    final selectedTemplateId = await showTemplateSelectionDialog();
    
    if (selectedTemplateId == 'cancelled') return;
    if (!mounted) return;

    // Show loading dialog
    _showLoadingDialog('Generating PDF...');

    // Generate PDF
    final result = await widget.controller.generatePdf(
      context: context,
      selectedTemplateId: selectedTemplateId,
    );

    // Hide loading dialog
    if (mounted) Navigator.of(context).pop();

    // Navigate to preview if successful
    if (result != null && mounted) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: result.pdfPath,
            suggestedFileName: result.suggestedFileName,
            quote: widget.controller.quote,
            customer: widget.controller.customer,
            templateId: result.templateId,
            selectedLevelId: widget.controller.selectedLevelId,
            originalCustomData: result.customData,
          ),
        ),
      );
    }
  }

  /// Preview template in dialog
  void _previewTemplate(PDFTemplate template) async {
    // Close template selection dialog first
    Navigator.of(context).pop();
    
    // Show loading dialog
    _showLoadingDialog('Generating preview...');

    // Generate preview
    await widget.controller.generatePreview(
      context: context,
      template: template,
    );

    // Hide loading dialog
    if (mounted) Navigator.of(context).pop();

    // The success message with action button will be shown by the controller listener
  }

  /// Show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
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
            if (widget.controller.isGenerating || widget.controller.isLoadingPreview)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
}