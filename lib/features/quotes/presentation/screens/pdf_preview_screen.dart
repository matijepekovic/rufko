// lib/screens/pdf_preview_screen.dart - ENHANCED PDF EDITOR

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../controllers/pdf_document_controller.dart';
import '../controllers/pdf_editing_controller.dart';
import '../controllers/pdf_file_operations_controller.dart';
import '../controllers/pdf_viewer_ui_builder.dart';
import '../controllers/pdf_preview_controller.dart';
import '../../../templates/presentation/controllers/template_field_dialog_manager.dart';
import '../../../../data/models/ui/pdf_form_field.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../../core/mixins/business/file_sharing_mixin.dart';
import '../../../../core/services/pdf/pdf_field_mapping_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String pdfPath;
  final String suggestedFileName;
  final SimplifiedMultiLevelQuote? quote;
  final Customer? customer;
  final String? templateId;
  final String? selectedLevelId;
  final Map<String, String>? originalCustomData;
  final String? title;
  final bool isPreview;

  const PdfPreviewScreen({
    super.key,
    required this.pdfPath,
    required this.suggestedFileName,
    this.quote,
    this.customer,
    this.templateId,
    this.selectedLevelId,
    this.originalCustomData,
    this.title,
    this.isPreview = false,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen>
    with FileSharingMixin {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfController = PdfViewerController();

  String _currentPdfPath = '';
  bool _isSaving = false;
  bool _hasEdits = false;

  // Enhanced editing features
  final PdfEditingController _editingController = PdfEditingController();
  List<PDFFormField> _formFields = [];
  bool _isLoadingFields = false;

  late PdfFileOperationsController _fileOpsController;
  late PdfViewerUIBuilder _uiBuilder;
  late TemplateFieldDialogManager _dialogManager;
  late PdfPreviewController _previewController;

  // Undo/Redo system managed by controller

  // Visual editing
  bool _showEditingTools = false;
  List<String> _editableFields = [];

  // Form field interaction
  final GlobalKey _pdfViewerContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentPdfPath = widget.pdfPath;
    _fileOpsController = PdfFileOperationsController(context);
    _dialogManager = TemplateFieldDialogManager(context, _editingController);
    _previewController = PdfPreviewController(context);
    _uiBuilder = PdfViewerUIBuilder(
      context,
      pdfViewerKey: _pdfViewerKey,
      pdfController: _pdfController,
      editingController: _editingController,
      getCurrentFieldValue: _getCurrentFieldValue,
      showTemplateFieldEditDialog: _dialogManager.showEditDialog,
    );
    _loadEditableFields();
    _loadFormFields();
    _editingController.addListener(() {
      setState(() {
        _hasEdits = _editingController.hasEdits;
      });
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  // Load form fields from PDF
  Future<void> _loadFormFields() async {
    if (_isLoadingFields) return;
    setState(() => _isLoadingFields = true);
    try {
      final controller = PdfDocumentController(_currentPdfPath);
      final fields = await controller.loadFormFields();
      setState(() => _formFields = fields);
    } catch (e) {
      debugPrint('❌ Error loading form fields: $e');
    } finally {
      setState(() => _isLoadingFields = false);
    }
  }


  // Undo last edit
  void _undoEdit() {
    _editingController.undo();
  }

  // Redo last undone edit
  void _redoEdit() {
    _editingController.redo();
  }

  // Load information about which fields can be edited from templates
  void _loadEditableFields() {
    if (widget.templateId != null) {
      _editableFields =
          _previewController.loadEditableFields(widget.templateId!);
      debugPrint('🔍 Found ${_editableFields.length} editable template fields');
    }
  }

  // Get current field value from quote/customer data using service
  String _getCurrentFieldValue(String fieldName) {
    return PdfFieldMappingService.instance.getCurrentFieldValue(
      fieldName,
      customer: widget.customer,
      quote: widget.quote,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDF Editor', style: TextStyle(fontSize: 18)),
            Text(
              widget.suggestedFileName,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: RufkoTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed:
                _editingController.currentHistoryIndex >= 0 ? _undoEdit : null,
            tooltip: 'Undo',
          ),
          // Redo button
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _editingController.currentHistoryIndex <
                    _editingController.history.length - 1
                ? _redoEdit
                : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _discardPdf,
            tooltip: 'Discard PDF',
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Share PDF',
          ),
          // Save button
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _savePdf,
            tooltip: 'Save PDF',
          ),
          // Discard button
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          _uiBuilder.buildStatusBar(
            hasEdits: _hasEdits,
            isLoadingFields: _isLoadingFields,
            formFields: _formFields,
            discardEdits: _discardEdits,
          ),

          // PDF Viewer - Takes all remaining space
          Expanded(
            child: Container(
              key: _pdfViewerContainerKey,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPdfViewerWithOverlays(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build PDF viewer with form field overlays
  Widget _buildPdfViewerWithOverlays() {
    return _uiBuilder.buildPdfViewerWithOverlays(
      currentPdfPath: _currentPdfPath,
      showEditingTools: _showEditingTools,
      exitTemplateMode: () => setState(() => _showEditingTools = false),
      quickEditButton: _uiBuilder.buildQuickEditButton,
    );
  }

  // Build form field overlays - FIXED VISUAL SYSTEM

  // Build action buttons

  // Save PDF with form field edits - USE TEMPLATE APPROACH
  Future<void> _savePdf() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _fileOpsController.savePdf(
        currentPdfPath: _currentPdfPath,
        editedValues: _editingController.editedValues,
        formFields: _formFields,
        suggestedFileName: widget.suggestedFileName,
        customer: widget.customer,
        quote: widget.quote,
        templateId: widget.templateId,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Apply edits using PDF mapping (same as template system)
// Show folder selection dialog

// Build folder option widget - FIXED LAYOUT

// Select custom folder using file picker

// Save file to specific directory
// Show save success dialog with actions - FIXED LAYOUT (NO EXPANDED IN ACTIONS)

// Show share success message

  // Discard PDF
  Future<void> _sharePdf() async {
    await _fileOpsController.sharePdf(
      currentPdfPath: _currentPdfPath,
      editedValues: _editingController.editedValues,
      formFields: _formFields,
      suggestedFileName: widget.suggestedFileName,
      customer: widget.customer,
      shareFile: (
          {required File file,
          required String fileName,
          Customer? customer}) async {
        await shareFile(file: file, fileName: fileName, customer: customer);
      },
    );
  }

  void _discardPdf() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard PDF?'),
        content: Text(
          _editingController.history.isNotEmpty
              ? 'Are you sure you want to discard this PDF and all ${_editingController.history.length} edits? This action cannot be undone.'
              : 'Are you sure you want to discard this PDF? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close preview, return false
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  // Clear all form field edits
  void _discardEdits() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Edits?"),
        content: const Text(
            "This will remove all changes you have made to the PDF form fields."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editingController.clearAll();
                setState(() => _hasEdits = false);
              },
              child: const Text("Clear")),
        ],
      ),
    );
  }
}

// Custom painter for form field overlays - IMPROVED
class FormFieldOverlayPainter extends CustomPainter {
  final List<PDFFormField> formFields;
  final Function(PDFFormField) onFieldTapped;
  final PDFFormField? selectedField;
  final Map<String, String> editedValues;

  FormFieldOverlayPainter({
    required this.formFields,
    required this.onFieldTapped,
    this.selectedField,
    required this.editedValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint(
        '🎨 Painting ${formFields.length} form field overlays on canvas ${size.width}x${size.height}');

    // Calculate scale factors based on standard PDF dimensions
    final scaleX = size.width / 612; // Standard PDF width
    final scaleY = size.height / 792; // Standard PDF height

    for (int i = 0; i < formFields.length; i++) {
      final field = formFields[i];
      final hasEdit = editedValues.containsKey(field.name);
      final isSelected = selectedField?.name == field.name;

      // Scale bounds to fit the viewer
      final scaledBounds = Rect.fromLTWH(
        field.bounds.left * scaleX,
        field.bounds.top * scaleY,
        field.bounds.width * scaleX,
        field.bounds.height * scaleY,
      );

      // Choose color based on field state
      Color overlayColor;
      Color borderColor;

      if (isSelected) {
        overlayColor = Colors.blue.withValues(alpha: 0.3);
        borderColor = Colors.blue;
      } else if (hasEdit) {
        overlayColor = Colors.green.withValues(alpha: 0.2);
        borderColor = Colors.green;
      } else if (field.isRequired) {
        overlayColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.red;
      } else {
        overlayColor = Colors.purple.withValues(alpha: 0.15);
        borderColor = Colors.purple;
      }

      // Draw field background
      final backgroundPaint = Paint()
        ..color = overlayColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(scaledBounds, backgroundPaint);

      // Draw field border
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : (hasEdit ? 2 : 1);

      canvas.drawRect(scaledBounds, borderPaint);

      // Draw field type indicator
      final textSpan = TextSpan(
        text: field.type.toUpperCase(),
        style: TextStyle(
          color: borderColor.withValues(alpha: 0.8),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();

      // Only draw text if there's enough space
      if (scaledBounds.width > textPainter.width + 4 &&
          scaledBounds.height > textPainter.height + 4) {
        textPainter.paint(
          canvas,
          Offset(
            scaledBounds.left + 2,
            scaledBounds.top + 2,
          ),
        );
      }

      // Draw edit indicator
      if (hasEdit) {
        final editPaint = Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(scaledBounds.right - 6, scaledBounds.top + 6),
          4,
          editPaint,
        );

        // Draw checkmark
        final checkPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        final checkPath = Path();
        checkPath.moveTo(scaledBounds.right - 8, scaledBounds.top + 6);
        checkPath.lineTo(scaledBounds.right - 6, scaledBounds.top + 8);
        checkPath.lineTo(scaledBounds.right - 4, scaledBounds.top + 4);

        canvas.drawPath(checkPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(FormFieldOverlayPainter oldDelegate) {
    return oldDelegate.formFields != formFields ||
        oldDelegate.selectedField != selectedField ||
        oldDelegate.editedValues != editedValues;
  }
}
