import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../shared/widgets/common/loading_overlay.dart';
import '../widgets/editor/template_upload_widget.dart';
import '../widgets/template_editor/template_editor_app_bar.dart';
import '../widgets/template_editor/template_pdf_viewer_section.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../controllers/template_pdf_controller.dart';
import '../controllers/template_operations_controller.dart';
import '../controllers/template_field_mapping_controller.dart';
import '../controllers/template_upload_controller.dart';

/// Refactored TemplateEditorScreen with extracted controllers and components
/// Original 509-line critical file broken down with ALL functionality preserved
/// Controllers handle PDF interaction, template operations, field mapping, and file upload
class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({
    super.key,
    this.existingTemplate,
    this.preselectedCategory,
  });

  final PDFTemplate? existingTemplate;
  final String? preselectedCategory;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late TemplatePdfController _pdfController;
  late TemplateOperationsController _operationsController;
  late TemplateFieldMappingController _fieldMappingController;
  late TemplateUploadController _uploadController;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _pdfController = TemplatePdfController();
    _operationsController = TemplateOperationsController(context);
    _fieldMappingController = TemplateFieldMappingController(context);
    _uploadController = TemplateUploadController(context);

    // Initialize with existing template or preselected category
    _operationsController.initialize(
      existingTemplate: widget.existingTemplate,
      preselectedCategory: widget.preselectedCategory,
    );

    // Initialize PDF controller with template
    _pdfController.initializeWithTemplate(widget.existingTemplate);
    _fieldMappingController.initializeWithTemplate(widget.existingTemplate);

    // Listen to template changes from operations controller
    _operationsController.addListener(_onTemplateChanged);
  }

  @override
  void dispose() {
    _operationsController.removeListener(_onTemplateChanged);
    _pdfController.dispose();
    _operationsController.dispose();
    _fieldMappingController.dispose();
    _uploadController.dispose();
    super.dispose();
  }

  /// Handle template changes from operations controller
  void _onTemplateChanged() {
    final template = _operationsController.currentTemplate;
    if (template != null) {
      _pdfController.updateTemplate(template);
      _fieldMappingController.updateTemplate(template);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: TemplateEditorAppBar(
        currentTemplate: _operationsController.currentTemplate,
        onSave: _operationsController.saveTemplate,
        onPreview: _operationsController.previewTemplate,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _operationsController,
          _uploadController,
        ]),
        builder: (context, child) {
          // Show loading overlay if either controller is loading
          if (_operationsController.isLoading || _uploadController.isUploading) {
            final message = _operationsController.isLoading
                ? _operationsController.loadingMessage
                : _uploadController.uploadMessage;
            return LoadingOverlay(message: message);
          }

          // Show upload widget if no template is loaded
          if (_operationsController.currentTemplate == null) {
            return TemplateUploadWidget(onUpload: _handleTemplateUpload);
          }

          // Show PDF viewer with template
          return _buildPdfViewer();
        },
      ),
    );
  }

  /// Build PDF viewer section with field mapping
  Widget _buildPdfViewer() {
    return ListenableBuilder(
      listenable: _pdfController,
      builder: (context, child) {
        return TemplatePdfViewerSection(
          pdfFile: _pdfController.pdfFile,
          controller: _pdfController.pdfController,
          onTap: _handlePdfTap,
          onPageChanged: _pdfController.onPageChanged,
        );
      },
    );
  }

  /// Handle PDF tap events for field mapping
  void _handlePdfTap(PdfGestureDetails details) {
    final tappedFieldInfo = _pdfController.handlePdfTap(details);
    if (tappedFieldInfo != null) {
      _fieldMappingController.showFieldMappingDialog(tappedFieldInfo);
    }
  }

  /// Handle template upload and creation
  Future<void> _handleTemplateUpload() async {
    final template = await _uploadController.uploadAndCreateTemplate(
      onTemplateNameRequired: _operationsController.showTemplateNameDialog,
    );

    if (template != null) {
      _operationsController.updateTemplate(template);
    }
  }
}
