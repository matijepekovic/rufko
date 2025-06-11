// lib/screens/pdf_preview_screen.dart - ENHANCED PDF EDITOR

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import '../controllers/pdf_document_controller.dart';
import '../controllers/pdf_editing_controller.dart';
import '../controllers/pdf_file_operations_controller.dart';
import '../models/pdf_form_field.dart';
import '../models/edit_action.dart';
import '../providers/app_state_provider.dart';
import '../models/simplified_quote.dart';
import '../models/customer.dart';
import '../models/project_media.dart';
import '../theme/rufko_theme.dart';
import 'package:intl/intl.dart';
import '../mixins/file_sharing_mixin.dart';

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
  final bool _showFieldOverlays = false;
  bool _isLoadingFields = false;

  late PdfFileOperationsController _fileOpsController;

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

  // Add edit action to history
  void _addEditAction(String fieldName, String oldValue, String newValue) {
    _editingController.addEdit(fieldName, oldValue, newValue);
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
      final appState = context.read<AppStateProvider>();
      final template = appState.pdfTemplates.firstWhere(
        (t) => t.id == widget.templateId!,
        orElse: () => throw Exception('Template not found'),
      );

      _editableFields = template.fieldMappings
          .where((mapping) => mapping.pdfFormFieldName.isNotEmpty)
          .map((mapping) => mapping.appDataType)
          .toList();

      debugPrint('🔍 Found ${_editableFields.length} editable template fields');
    }
  }

  // Get display name for field
  String _getFieldDisplayName(String fieldName) {
    final displayNames = {
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
    return displayNames[fieldName] ??
        fieldName.replaceAll('_', ' ').toUpperCase();
  }

  // Get current field value from quote/customer data
  String _getCurrentFieldValue(String fieldName) {
    final quote = widget.quote;
    final customer = widget.customer;

    // Customer fields
    if (fieldName.toLowerCase().contains('customer')) {
      if (fieldName.toLowerCase().contains('name')) return customer?.name ?? '';
      if (fieldName.toLowerCase().contains('phone'))
        return customer?.phone ?? '';
      if (fieldName.toLowerCase().contains('email'))
        return customer?.email ?? '';
      if (fieldName.toLowerCase().contains('address'))
        return customer?.fullDisplayAddress ?? '';
      if (fieldName.toLowerCase().contains('street'))
        return customer?.streetAddress ?? '';
      if (fieldName.toLowerCase().contains('city')) return customer?.city ?? '';
      if (fieldName.toLowerCase().contains('state'))
        return customer?.stateAbbreviation ?? '';
      if (fieldName.toLowerCase().contains('zip'))
        return customer?.zipCode ?? '';
    }

    // Quote fields
    if (fieldName.toLowerCase().contains('quote')) {
      if (fieldName.toLowerCase().contains('number'))
        return quote?.quoteNumber ?? '';
      if (fieldName.toLowerCase().contains('date')) {
        return quote != null
            ? DateFormat('MM/dd/yyyy').format(quote.createdAt)
            : '';
      }
      if (fieldName.toLowerCase().contains('status'))
        return quote?.status ?? '';
    }

    // Company fields
    if (fieldName.toLowerCase().contains('company')) {
      if (fieldName.toLowerCase().contains('name')) return 'Your Company Name';
      if (fieldName.toLowerCase().contains('phone')) return '(555) 123-4567';
      if (fieldName.toLowerCase().contains('email'))
        return 'info@yourcompany.com';
      if (fieldName.toLowerCase().contains('address'))
        return '123 Main St, Your City, ST 12345';
    }

    // Date fields
    if (fieldName.toLowerCase().contains('date')) {
      if (fieldName.toLowerCase().contains('today'))
        return DateFormat('MM/dd/yyyy').format(DateTime.now());
      if (fieldName.toLowerCase().contains('valid')) {
        return quote != null
            ? DateFormat('MM/dd/yyyy').format(quote.validUntil)
            : '';
      }
    }

    // Text fields
    if (fieldName.toLowerCase().contains('note')) return quote?.notes ?? '';
    if (fieldName.toLowerCase().contains('term'))
      return 'Standard terms and conditions apply...';

    return '';
  }

  // Show edit dialog for template fields
  void _showTemplateFieldEditDialog(String fieldName, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${_getFieldDisplayName(fieldName)}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _getFieldDisplayName(fieldName),
            border: const OutlineInputBorder(),
          ),
          maxLines: fieldName == 'notes' || fieldName == 'terms' ? 3 : 1,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text.trim();
              final oldValue =
                  _editingController.editedValues[fieldName] ?? currentValue;

              if (newValue != oldValue) {
                _addEditAction(fieldName, oldValue, newValue);
                setState(() =>
                    _editingController.editedValues[fieldName] = newValue);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
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
          Container(
            color: _hasEdits
                ? Colors.orange.shade100
                : (_isLoadingFields
                    ? Colors.blue.shade100
                    : Colors.grey.shade100),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_isLoadingFields) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('Loading form fields...',
                      style: TextStyle(fontSize: 12)),
                ] else ...[
                  Icon(
                    _hasEdits
                        ? Icons.edit
                        : (_showFieldOverlays
                            ? Icons.touch_app
                            : Icons.visibility),
                    size: 16,
                    color: _hasEdits
                        ? Colors.orange.shade700
                        : (_showFieldOverlays
                            ? Colors.green.shade700
                            : Colors.blue.shade700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasEdits
                          ? '${_editingController.editedValues.length} fields edited - direct PDF mapping active'
                          : _formFields.isNotEmpty
                              ? '${_formFields.length} form fields detected - click directly to edit'
                              : 'No editable form fields detected',
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasEdits
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
                if (_hasEdits) ...[
                  TextButton(
                    onPressed: _discardEdits,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
    final file = File(_currentPdfPath);

    if (!file.existsSync()) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'PDF file not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The PDF file may have been moved or deleted.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // PDF Viewer with Direct Form Field Mapping (No Dialogs)
        SfPdfViewer.file(
          file,
          key: _pdfViewerKey,
          controller: _pdfController,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          onFormFieldValueChanged: (PdfFormFieldValueChangedDetails details) {
            // Direct field mapping like template system
            final fieldName = details.formField.name;
            final newValue = details.newValue?.toString() ?? '';
            final oldValue = details.oldValue?.toString() ?? '';

            debugPrint('📝 Direct field edit: "$fieldName" = "$newValue"');

            setState(() {
              _editingController.editedValues[fieldName] = newValue;
              _hasEdits = true;
            });

            _addEditAction(fieldName, oldValue, newValue);
          },
          onDocumentLoaded: (details) {
            if (kDebugMode) {
              debugPrint(
                  '📄 PDF loaded: ${details.document.pages.count} pages');
            }
          },
          onDocumentLoadFailed: (details) {
            if (kDebugMode) {
              debugPrint('❌ PDF load failed: ${details.error}');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load PDF: ${details.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),

        // Template Edit Mode Overlay
        if (_showEditingTools)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.orange.shade600.withValues(alpha: 0.9),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Template Edit Mode: Use buttons below to edit template fields',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _showEditingTools = false);
                    },
                    child: const Text(
                      'Exit Template Mode',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Template Quick Edit Buttons
        if (_showEditingTools)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Quick Edit Template Fields:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickEditButton('customerName', 'Customer Name'),
                      _buildQuickEditButton('customerPhone', 'Phone'),
                      _buildQuickEditButton('customerEmail', 'Email'),
                      _buildQuickEditButton('notes', 'Notes'),
                      _buildQuickEditButton('terms', 'Terms'),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Build form field overlays - FIXED VISUAL SYSTEM

  // Build quick edit button for template fields
  Widget _buildQuickEditButton(String fieldName, String displayName) {
    final hasEdit = _editingController.editedValues.containsKey(fieldName);

    return OutlinedButton.icon(
      onPressed: () {
        String currentValue = _editingController.editedValues[fieldName] ??
            _getCurrentFieldValue(fieldName);
        _showTemplateFieldEditDialog(fieldName, currentValue);
      },
      icon: Icon(
        hasEdit ? Icons.edit : Icons.edit_outlined,
        size: 16,
        color: hasEdit ? Colors.green : null,
      ),
      label: Text(
        displayName,
        style: TextStyle(
          color: hasEdit ? Colors.green : null,
          fontWeight: hasEdit ? FontWeight.bold : null,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: hasEdit ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

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
