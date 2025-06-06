// lib/screens/pdf_preview_screen.dart - ENHANCED PDF EDITOR

import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import '../providers/app_state_provider.dart';
import '../models/simplified_quote.dart';
import '../models/customer.dart';
import '../models/project_media.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
// Model for form fields
class PDFFormField {
  final String name;
  final String type;
  final String currentValue;
  final Rect bounds;
  final int pageNumber;
  final bool isRequired;
  final List<String>? options; // For choice fields

  PDFFormField({
    required this.name,
    required this.type,
    required this.currentValue,
    required this.bounds,
    required this.pageNumber,
    this.isRequired = false,
    this.options,
  });

  PDFFormField copyWith({
    String? name,
    String? type,
    String? currentValue,
    Rect? bounds,
    int? pageNumber,
    bool? isRequired,
    List<String>? options,
  }) {
    return PDFFormField(
      name: name ?? this.name,
      type: type ?? this.type,
      currentValue: currentValue ?? this.currentValue,
      bounds: bounds ?? this.bounds,
      pageNumber: pageNumber ?? this.pageNumber,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
    );
  }

  @override
  String toString() => 'PDFFormField($name: $currentValue)';
}

// Model for edit history (undo/redo)
class EditAction {
  final String fieldName;
  final String oldValue;
  final String newValue;
  final DateTime timestamp;

  EditAction({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'Edit: $fieldName "$oldValue" → "$newValue"';
}

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

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfController = PdfViewerController();

  String _currentPdfPath = '';
  bool _isSaving = false;
  bool _isSharing = false;
  bool _hasEdits = false;

  // Enhanced editing features
  final Map<String, String> _editedValues = {};
  List<PDFFormField> _formFields = [];
  bool _showFieldOverlays = false;
  bool _isLoadingFields = false;

  // Undo/Redo system
  final List<EditAction> _editHistory = [];
  int _currentHistoryIndex = -1;

  // Visual editing
  bool _showEditingTools = false;
  bool _isRegenerating = false;
  List<String> _editableFields = [];

  // Form field interaction
  PDFFormField? _selectedField;
  final GlobalKey _pdfViewerContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentPdfPath = widget.pdfPath;
    _loadEditableFields();
    _loadFormFields();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // Load form fields from PDF
  Future<void> _loadFormFields() async {
    if (_isLoadingFields) return;

    setState(() => _isLoadingFields = true);

    try {
      debugPrint('🔍 Loading form fields from: $_currentPdfPath');

      final file = File(_currentPdfPath);
      if (!await file.exists()) {
        debugPrint('❌ PDF file does not exist');
        return;
      }

      final bytes = await file.readAsBytes();
      final document = sf_pdf.PdfDocument(inputBytes: bytes);

      final List<PDFFormField> fields = [];

      debugPrint('📄 PDF loaded, checking for form fields...');
      debugPrint('📊 Form fields count: ${document.form.fields.count}');

      // Extract form fields using Syncfusion PDF
      if (document.form.fields.count > 0) {
        for (int i = 0; i < document.form.fields.count; i++) {
          final field = document.form.fields[i];
          final fieldName = field.name ?? 'field_$i';

          debugPrint('🔍 Processing field $i: "$fieldName" (${field.runtimeType})');

          // Get field bounds (this is approximate - exact positioning needs more work)
          final bounds = Rect.fromLTWH(
            field.bounds.left,
            field.bounds.top,
            field.bounds.width,
            field.bounds.height,
          );

          String fieldType = 'text';
          String currentValue = '';
          List<String>? options;

          // Determine field type and get current value
          if (field is sf_pdf.PdfTextBoxField) {
            fieldType = 'text';
            currentValue = field.text;
            debugPrint('   📝 Text field: "$currentValue"');
          } else if (field is sf_pdf.PdfComboBoxField) {
            fieldType = 'dropdown';
            currentValue = field.selectedValue;
            options = [];
            for (int j = 0; j < field.items.count; j++) {
              options.add(field.items[j].text);
            }
            debugPrint('   📋 Dropdown field: "$currentValue" (${options.length} options)');
          } else if (field is sf_pdf.PdfListBoxField) {
            fieldType = 'listbox';
            currentValue = field.selectedValues.isNotEmpty ? field.selectedValues.first : '';
            options = [];
            for (int j = 0; j < field.items.count; j++) {
              options.add(field.items[j].text);
            }
            debugPrint('   📋 Listbox field: "$currentValue" (${options.length} options)');
          } else if (field is sf_pdf.PdfCheckBoxField) {
            fieldType = 'checkbox';
            currentValue = field.isChecked ? 'true' : 'false';
            debugPrint('   ☑️ Checkbox field: $currentValue');
          } else if (field is sf_pdf.PdfRadioButtonListField) {
            fieldType = 'radio';
            currentValue = field.selectedValue;
            options = [];
            for (int j = 0; j < field.items.count; j++) {
              options.add(field.items[j].value);
            }
            debugPrint('   🔘 Radio field: "$currentValue" (${options.length} options)');
          } else {
            debugPrint('   ❓ Unknown field type: ${field.runtimeType}');
          }

          fields.add(PDFFormField(
            name: fieldName,
            type: fieldType,
            currentValue: currentValue,
            bounds: bounds,
            pageNumber: 0, // Need to determine page number
            isRequired: false, // Syncfusion doesn't expose this directly
            options: options,
          ));
        }
      } else {
        debugPrint('⚠️ No form fields found in PDF');
      }

      document.dispose();

      setState(() {
        _formFields = fields;
      });

      debugPrint('✅ Loaded ${fields.length} form fields:');
      for (final field in fields) {
        debugPrint('   - "${field.name}" (${field.type}) = "${field.currentValue}"');
      }

    } catch (e) {
      debugPrint('❌ Error loading form fields: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
    } finally {
      setState(() => _isLoadingFields = false);
    }
  }

  // Add edit action to history
  void _addEditAction(String fieldName, String oldValue, String newValue) {
    if (oldValue == newValue) return;

    // Remove any history after current index (for branching edits)
    if (_currentHistoryIndex < _editHistory.length - 1) {
      _editHistory.removeRange(_currentHistoryIndex + 1, _editHistory.length);
    }

    // Add new action
    final action = EditAction(
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
    );

    _editHistory.add(action);
    _currentHistoryIndex = _editHistory.length - 1;

    // Limit history size
    if (_editHistory.length > 50) {
      _editHistory.removeAt(0);
      _currentHistoryIndex--;
    }

    setState(() => _hasEdits = true);

    debugPrint('📝 Edit: ${action.fieldName} "${action.oldValue}" → "${action.newValue}"');
  }

  // Undo last edit
  void _undoEdit() {
    if (_currentHistoryIndex < 0) return;

    final action = _editHistory[_currentHistoryIndex];
    _editedValues[action.fieldName] = action.oldValue;
    _currentHistoryIndex--;

    setState(() {
      _hasEdits = _editedValues.values.any((v) => v.isNotEmpty);
    });

    debugPrint('↶ Undo: ${action.fieldName} → "${action.oldValue}"');
  }

  // Redo last undone edit
  void _redoEdit() {
    if (_currentHistoryIndex >= _editHistory.length - 1) return;

    _currentHistoryIndex++;
    final action = _editHistory[_currentHistoryIndex];
    _editedValues[action.fieldName] = action.newValue;

    setState(() => _hasEdits = true);

    debugPrint('↷ Redo: ${action.fieldName} → "${action.newValue}"');
  }

  // Handle form field tap
  void _onFormFieldTapped(PDFFormField field) {
    debugPrint('👆 Form field tapped: "${field.name}" (${field.type})');
    debugPrint('📝 Current value: "${field.currentValue}"');
    debugPrint('🔍 Existing edit: "${_editedValues[field.name] ?? 'none'}"');

    setState(() => _selectedField = field);

    final currentValue = _editedValues[field.name] ?? field.currentValue;
    debugPrint('💡 Opening edit dialog with value: "$currentValue"');

    _showFieldEditDialog(field, currentValue);
  }

  // Show edit dialog for form field - FIXED VERSION
  void _showFieldEditDialog(PDFFormField field, String currentValue) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    String selectedValue = currentValue;
    bool isChecked = currentValue.toLowerCase() == 'true';

    debugPrint('🔧 Opening edit dialog for: "${field.name}" (${field.type}) = "$currentValue"');

    Widget content;

    switch (field.type) {
      case 'checkbox':
        content = StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit ${field.name}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(field.name),
                value: isChecked,
                onChanged: (value) {
                  setDialogState(() => isChecked = value ?? false);
                  debugPrint('🔄 Checkbox changed to: $isChecked');
                },
              ),
            ],
          ),
        );
        break;

      case 'dropdown':
      case 'listbox':
        content = StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select value for ${field.name}:'),
              const SizedBox(height: 16),
              if (field.options != null && field.options!.isNotEmpty)
                ...field.options!.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedValue,
                  onChanged: (value) {
                    setDialogState(() => selectedValue = value ?? '');
                    debugPrint('🔄 Selection changed to: $selectedValue');
                  },
                ))
              else
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: field.name,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    selectedValue = value;
                    debugPrint('🔄 Text changed to: $selectedValue');
                  },
                ),
            ],
          ),
        );
        break;

      case 'radio':
        content = StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select option for ${field.name}:'),
              const SizedBox(height: 16),
              if (field.options != null && field.options!.isNotEmpty)
                ...field.options!.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedValue,
                  onChanged: (value) {
                    setDialogState(() => selectedValue = value ?? '');
                    debugPrint('🔄 Radio changed to: $selectedValue');
                  },
                ))
              else
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: field.name,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    selectedValue = value;
                    debugPrint('🔄 Text changed to: $selectedValue');
                  },
                ),
            ],
          ),
        );
        break;

      default: // text field
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit ${field.name}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: field.name,
                border: const OutlineInputBorder(),
                helperText: field.isRequired ? 'Required field' : null,
              ),
              maxLines: field.name.toLowerCase().contains('note') ? 3 : 1,
              autofocus: true,
              onChanged: (value) {
                debugPrint('🔄 Text field changed to: "$value"');
              },
            ),
          ],
        );
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Field'),
        content: SingleChildScrollView(child: content),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('❌ Edit cancelled for: ${field.name}');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String newValue;

              // Get the new value based on field type
              switch (field.type) {
                case 'checkbox':
                  newValue = isChecked.toString();
                  break;
                case 'dropdown':
                case 'listbox':
                case 'radio':
                  newValue = selectedValue;
                  break;
                default: // text
                  newValue = controller.text;
                  break;
              }

              debugPrint('💾 Saving field edit: "${field.name}" = "$newValue" (was "$currentValue")');

              final oldValue = _editedValues[field.name] ?? field.currentValue;
              if (newValue != oldValue) {
                _addEditAction(field.name, oldValue, newValue);
                setState(() {
                  _editedValues[field.name] = newValue;
                  debugPrint('✅ Edit saved to memory: ${_editedValues.length} total edits');
                  debugPrint('📝 All edits: ${_editedValues.keys.join(', ')}');
                });
              } else {
                debugPrint('⚠️ No change detected, not saving');
              }

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
    return displayNames[fieldName] ?? fieldName.replaceAll('_', ' ').toUpperCase();
  }

  // Get current field value from quote/customer data
  String _getCurrentFieldValue(String fieldName) {
    final quote = widget.quote;
    final customer = widget.customer;

    // Customer fields
    if (fieldName.toLowerCase().contains('customer')) {
      if (fieldName.toLowerCase().contains('name')) return customer?.name ?? '';
      if (fieldName.toLowerCase().contains('phone')) return customer?.phone ?? '';
      if (fieldName.toLowerCase().contains('email')) return customer?.email ?? '';
      if (fieldName.toLowerCase().contains('address')) return customer?.fullDisplayAddress ?? '';
      if (fieldName.toLowerCase().contains('street')) return customer?.streetAddress ?? '';
      if (fieldName.toLowerCase().contains('city')) return customer?.city ?? '';
      if (fieldName.toLowerCase().contains('state')) return customer?.stateAbbreviation ?? '';
      if (fieldName.toLowerCase().contains('zip')) return customer?.zipCode ?? '';
    }

    // Quote fields
    if (fieldName.toLowerCase().contains('quote')) {
      if (fieldName.toLowerCase().contains('number')) return quote?.quoteNumber ?? '';
      if (fieldName.toLowerCase().contains('date')) {
        return quote != null ? DateFormat('MM/dd/yyyy').format(quote.createdAt) : '';
      }
      if (fieldName.toLowerCase().contains('status')) return quote?.status ?? '';
    }

    // Company fields
    if (fieldName.toLowerCase().contains('company')) {
      if (fieldName.toLowerCase().contains('name')) return 'Your Company Name';
      if (fieldName.toLowerCase().contains('phone')) return '(555) 123-4567';
      if (fieldName.toLowerCase().contains('email')) return 'info@yourcompany.com';
      if (fieldName.toLowerCase().contains('address')) return '123 Main St, Your City, ST 12345';
    }

    // Date fields
    if (fieldName.toLowerCase().contains('date')) {
      if (fieldName.toLowerCase().contains('today')) return DateFormat('MM/dd/yyyy').format(DateTime.now());
      if (fieldName.toLowerCase().contains('valid')) {
        return quote != null ? DateFormat('MM/dd/yyyy').format(quote.validUntil) : '';
      }
    }

    // Text fields
    if (fieldName.toLowerCase().contains('note')) return quote?.notes ?? '';
    if (fieldName.toLowerCase().contains('term')) return 'Standard terms and conditions apply...';

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
              final oldValue = _editedValues[fieldName] ?? currentValue;

              if (newValue != oldValue) {
                _addEditAction(fieldName, oldValue, newValue);
                setState(() => _editedValues[fieldName] = newValue);
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _currentHistoryIndex >= 0 ? _undoEdit : null,
            tooltip: 'Undo',
          ),
          // Redo button
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _currentHistoryIndex < _editHistory.length - 1 ? _redoEdit : null,
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
            color: _hasEdits ? Colors.orange.shade100 :
            (_isLoadingFields ? Colors.blue.shade100 : Colors.grey.shade100),
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
                  const Text('Loading form fields...', style: TextStyle(fontSize: 12)),
                ] else ...[
                  Icon(
                    _hasEdits ? Icons.edit :
                    (_showFieldOverlays ? Icons.touch_app : Icons.visibility),
                    size: 16,
                    color: _hasEdits ? Colors.orange.shade700 :
                    (_showFieldOverlays ? Colors.green.shade700 : Colors.blue.shade700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasEdits
                          ? '${_editedValues.length} fields edited - direct PDF mapping active'
                          : _formFields.isNotEmpty
                          ? '${_formFields.length} form fields detected - click directly to edit'
                          : 'No editable form fields detected',
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasEdits ? Colors.orange.shade800 : Colors.blue.shade800,
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
              _editedValues[fieldName] = newValue;
              _hasEdits = true;
            });

            _addEditAction(fieldName, oldValue, newValue);
          },
          onDocumentLoaded: (details) {
            if (kDebugMode) {
              debugPrint('📄 PDF loaded: ${details.document.pages.count} pages');
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

  // Handle tap on form field overlays
  void _handleFormFieldTap(Offset tapPosition) {
    debugPrint('🔍 Checking tap at ${tapPosition.dx}, ${tapPosition.dy} against ${_formFields.length} fields');

    // Get the PDF viewer size for scaling calculations
    final RenderBox? renderBox = _pdfViewerContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('❌ Could not get PDF viewer render box');
      return;
    }

    final viewerSize = renderBox.size;
    debugPrint('📐 PDF viewer size: ${viewerSize.width} x ${viewerSize.height}');

    // Simple scaling based on approximate PDF dimensions
    // This is a rough calculation - in production you'd need proper page-to-screen transformation
    final scaleX = viewerSize.width / 612; // Standard PDF width
    final scaleY = viewerSize.height / 792; // Standard PDF height

    debugPrint('📏 Scale factors: x=$scaleX, y=$scaleY');

    // Check each form field
    for (int i = 0; i < _formFields.length; i++) {
      final field = _formFields[i];

      // Scale the field bounds to screen coordinates
      final scaledBounds = Rect.fromLTWH(
        field.bounds.left * scaleX,
        field.bounds.top * scaleY,
        field.bounds.width * scaleX,
        field.bounds.height * scaleY,
      );

      debugPrint('🔍 Field "${field.name}": PDF bounds=${field.bounds} → Screen bounds=$scaledBounds');

      // Check if tap is within this field
      if (scaledBounds.contains(tapPosition)) {
        debugPrint('✅ HIT! Tapped on field: "${field.name}"');
        _onFormFieldTapped(field);
        return;
      }
    }

    debugPrint('❌ No field hit at tap position');
  }

  // Build quick edit button for template fields
  Widget _buildQuickEditButton(String fieldName, String displayName) {
    final hasEdit = _editedValues.containsKey(fieldName);

    return OutlinedButton.icon(
      onPressed: () {
        String currentValue = _editedValues[fieldName] ?? _getCurrentFieldValue(fieldName);
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

  // Regenerate PDF with template edits
  Future<void> _regeneratePdf() async {
    if (widget.templateId == null || widget.quote == null || widget.customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot regenerate: missing template or quote information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isRegenerating = true);

    try {
      debugPrint('🔄 Starting PDF regeneration with ${_editedValues.length} template edits');

      // Merge original custom data with edited values
      final customDataWithEdits = <String, String>{
        ...?widget.originalCustomData,
        ..._editedValues,
        'regenerated_at': DateTime.now().toIso8601String(),
        'has_edits': 'true',
      };

      final appState = context.read<AppStateProvider>();
      final newPdfPath = await appState.regeneratePDFFromTemplate(
        templateId: widget.templateId!,
        quote: widget.quote!,
        customer: widget.customer!,
        selectedLevelId: widget.selectedLevelId,
        customDataOverrides: customDataWithEdits,
      );

      setState(() {
        _currentPdfPath = newPdfPath;
        _hasEdits = false;
        _editedValues.clear();
        _showEditingTools = false;
        _editHistory.clear();
        _currentHistoryIndex = -1;
      });

      // Reload form fields from new PDF
      _loadFormFields();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('✅ PDF regenerated with template changes!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      debugPrint('❌ Error regenerating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❌ Failed to regenerate PDF'),
              Text('Error: ${e.toString()}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  // Save PDF with form field edits - USE TEMPLATE APPROACH
  Future<void> _savePdf() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      debugPrint('💾 Starting PDF save with ${_editedValues.length} edits');

      File pdfToSave;

      // If we have form field edits, apply them first
      if (_editedValues.isNotEmpty && _formFields.isNotEmpty) {
        debugPrint('🔧 Applying edits using template-style field mapping approach...');
        pdfToSave = await _applyEditsUsingTemplateApproach();
      } else {
        debugPrint('📄 Using original file (no edits to apply)');
        pdfToSave = File(_currentPdfPath);
      }

      // Ensure the file exists before proceeding
      if (!await pdfToSave.exists()) {
        throw Exception('PDF file not found: ${pdfToSave.path}');
      }

      // Save to final location
      // Save to final location AND add to customer media
      // Save to final location AND add to customer media
      Directory? saveDir = await getApplicationDocumentsDirectory();

      String finalFileName = widget.suggestedFileName;
      if (_editedValues.isNotEmpty) {
        final baseName = finalFileName.replaceAll('.pdf', '');
        finalFileName = '${baseName}_edited.pdf';
      }

      int counter = 1;
      File targetFile = File('${saveDir.path}/$finalFileName');
      while (await targetFile.exists()) {
        final baseName = finalFileName.replaceAll('.pdf', '');
        finalFileName = '${baseName}_$counter.pdf';
        targetFile = File('${saveDir.path}/$finalFileName');
        counter++;
      }

      await pdfToSave.copy(targetFile.path);

      // 🚀 NEW: Add PDF to customer media using ProjectMedia
      if (widget.customer != null && mounted) {
        try {
          final appState = context.read<AppStateProvider>();

          // Get file size
          final fileSize = await targetFile.length();

          // Create ProjectMedia object
          final projectMedia = ProjectMedia(
            customerId: widget.customer!.id,
            quoteId: widget.quote?.id, // Link to quote if available
            filePath: targetFile.path,
            fileName: finalFileName,
            fileType: 'pdf',
            description: widget.quote != null
                ? 'Quote PDF: ${widget.quote!.quoteNumber}${_editedValues.isNotEmpty ? ' (edited)' : ''}'
                : 'Generated PDF${_editedValues.isNotEmpty ? ' (edited)' : ''}',
            tags: [
              'quote',
              'pdf',
              if (_editedValues.isNotEmpty) 'edited',
              if (widget.templateId != null) 'template',
            ],
            category: 'document',
            fileSizeBytes: fileSize,
          );

          await appState.addProjectMedia(projectMedia);
          debugPrint('✅ PDF added to customer media: ${widget.customer!.name}');
        } catch (e) {
          debugPrint('⚠️ Failed to add PDF to customer media: $e');
          // Don't fail the save operation if media addition fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF saved${widget.customer != null ? ' and added to customer media' : ''}!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(targetFile.path),
            ),
          ),
        );
        Navigator.pop(context, true);
      }

    } catch (e) {
      debugPrint('❌ Error: $e');
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
  Future<File> _applyEditsUsingTemplateApproach() async {
    debugPrint('🗂️ Applying ${_editedValues.length} field mappings...');

    final originalFile = File(_currentPdfPath);
    final bytes = await originalFile.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    try {
      // Apply field mappings directly (template approach)
      for (int i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        final fieldName = field.name ?? 'field_$i';

        if (_editedValues.containsKey(fieldName)) {
          final value = _editedValues[fieldName]!;
          debugPrint('🗂️ Mapping: $fieldName = "$value"');

          field.readOnly = false;

          if (field is sf_pdf.PdfTextBoxField) {
            field.text = value;
          } else if (field is sf_pdf.PdfCheckBoxField) {
            field.isChecked = value.toLowerCase() == 'true';
          } else if (field is sf_pdf.PdfComboBoxField) {
            field.selectedValue = value;
          } else if (field is sf_pdf.PdfRadioButtonListField) {
            field.selectedValue = value;
          }
        }
      }

      // Set appearance like template system
      document.form.setDefaultAppearance(false);

      // Save mapped PDF
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/mapped_${DateTime.now().millisecondsSinceEpoch}.pdf');

      final pdfBytes = await document.save();
      await tempFile.writeAsBytes(pdfBytes);

      debugPrint('✅ PDF mapping complete');
      return tempFile;

    } finally {
      document.dispose();
    }
  }

  // Apply form field edits to PDF
  Future<File> _applyFormFieldEditsToPdf() async {
    debugPrint('🔧 Applying ${_editedValues.length} form field edits to PDF...');
    debugPrint('📝 Edits to apply: ${_editedValues.keys.join(', ')}');

    final originalFile = File(_currentPdfPath);
    final bytes = await originalFile.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    try {
      debugPrint('📄 PDF has ${document.form.fields.count} form fields');

      int editsApplied = 0;

      // Apply edits to form fields
      for (int i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        final fieldName = field.name ?? 'field_$i';

        debugPrint('🔍 Checking field: "$fieldName" (type: ${field.runtimeType})');

        if (_editedValues.containsKey(fieldName)) {
          final newValue = _editedValues[fieldName]!;
          debugPrint('✏️ Applying edit: $fieldName = "$newValue"');

          bool success = false;

          // Apply the new value based on field type
          if (field is sf_pdf.PdfTextBoxField) {
            field.text = newValue;
            success = true;
            debugPrint('   ✅ Text field updated');
          } else if (field is sf_pdf.PdfComboBoxField) {
            field.selectedValue = newValue;
            success = true;
            debugPrint('   ✅ Combo box updated');
          } else if (field is sf_pdf.PdfCheckBoxField) {
            field.isChecked = newValue.toLowerCase() == 'true';
            success = true;
            debugPrint('   ✅ Checkbox updated to ${field.isChecked}');
          } else if (field is sf_pdf.PdfRadioButtonListField) {
            field.selectedValue = newValue;
            success = true;
            debugPrint('   ✅ Radio button updated');
          } else if (field is sf_pdf.PdfListBoxField) {
            // Handle list box
            field.selectedValues = [newValue];
            success = true;
            debugPrint('   ✅ List box updated');
          } else {
            debugPrint('   ⚠️ Unknown field type: ${field.runtimeType}');
          }

          if (success) {
            editsApplied++;
          }
        }
      }

      debugPrint('✅ Applied $editsApplied edits successfully');

      // IMPORTANT: Set form field properties to ensure changes are saved
      for (int i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        // Make sure the field is not read-only
        field.readOnly = false;
      }

      // Set default appearance at document level (NOT individual field level)
      document.form.setDefaultAppearance(false);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.pdf');

      // Important: Use document.save() to get the bytes with form field changes
      final List<int> pdfBytes = await document.save();
      await tempFile.writeAsBytes(pdfBytes);

      debugPrint('💾 Saved edited PDF to: ${tempFile.path}');
      debugPrint('📊 File size: ${await tempFile.length()} bytes');

      // Verify the changes were saved by re-reading the file
      try {
        final verifyDocument = sf_pdf.PdfDocument(inputBytes: await tempFile.readAsBytes());
        debugPrint('🔍 Verifying saved changes...');

        for (int i = 0; i < verifyDocument.form.fields.count; i++) {
          final field = verifyDocument.form.fields[i];
          final fieldName = field.name ?? 'field_$i';

          if (_editedValues.containsKey(fieldName)) {
            String savedValue = '';
            if (field is sf_pdf.PdfTextBoxField) {
              savedValue = field.text;
            } else if (field is sf_pdf.PdfComboBoxField) {
              savedValue = field.selectedValue;
            } else if (field is sf_pdf.PdfCheckBoxField) {
              savedValue = field.isChecked ? 'true' : 'false';
            } else if (field is sf_pdf.PdfRadioButtonListField) {
              savedValue = field.selectedValue;
            }

            final expectedValue = _editedValues[fieldName]!;
            if (savedValue == expectedValue) {
              debugPrint('   ✅ $fieldName: "$savedValue" (correct)');
            } else {
              debugPrint('   ❌ $fieldName: expected "$expectedValue", got "$savedValue"');
            }
          }
        }

        verifyDocument.dispose();
      } catch (e) {
        debugPrint('⚠️ Could not verify changes: $e');
      }

      return tempFile;

    } catch (e) {
      debugPrint('❌ Error applying form field edits: $e');
      rethrow;
    } finally {
      document.dispose();
    }
  }

  // Share PDF
  // Enhanced unified share functionality
  Future<void> _sharePdf() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      File fileToShare;

      // If we have edits, create a temporary file with edits applied
      if (_editedValues.isNotEmpty && _formFields.isNotEmpty) {
        fileToShare = await _applyFormFieldEditsToPdf();
      } else {
        fileToShare = File(_currentPdfPath);
      }

      if (!await fileToShare.exists()) {
        throw Exception('PDF file not found');
      }

      setState(() => _isSharing = false);

      // Show unified share options dialog
      _showUnifiedShareDialog(fileToShare);

    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error preparing PDF for sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSharing = false);
      }
    }
  }

// Show unified share options dialog
  void _showUnifiedShareDialog(File fileToShare) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView( // Make entire dialog scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.share, size: 24, color: Color(0xFF2E86AB)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share PDF',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.suggestedFileName,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // File info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 40, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileToShare.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<int>(
                            future: fileToShare.length(),
                            builder: (context, snapshot) {
                              return Text(
                                'Size: ${snapshot.hasData ? _formatFileSize(snapshot.data!) : 'Calculating...'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              );
                            },
                          ),
                          if (_editedValues.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_editedValues.length} edits applied',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share options grid
              const Text(
                'Choose sharing method:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Share options in a more responsive grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2; // Account for spacing
                  final cardHeight = cardWidth * 0.7; // Responsive height

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: cardWidth / cardHeight, // Dynamic aspect ratio
                    children: [
                      _buildShareOptionCard(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: 'Send via email',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(fileToShare, 'email');
                        },
                      ),
                      _buildShareOptionCard(
                        icon: Icons.bluetooth,
                        title: 'Bluetooth',
                        subtitle: 'Share via Bluetooth',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(fileToShare, 'bluetooth');
                        },
                      ),
                      _buildShareOptionCard(
                        icon: Icons.folder_open,
                        title: 'Save to Folder',
                        subtitle: 'Choose location',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(fileToShare, 'folder');
                        },
                      ),
                      _buildShareOptionCard(
                        icon: Icons.apps,
                        title: 'More Apps',
                        subtitle: 'Other apps',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(fileToShare, 'system');
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Quick share button for system default
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleShareAction(fileToShare, 'quick');
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Quick Share (System Default)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86AB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],        // Closes children array
          ),          // Closes Column
        ),            // Closes SingleChildScrollView
      ),             // Closes Container
    );              // Closes showModalBottomSheet
  }                 // Closes method

// Build share option card
// Build share option card - FIXED LAYOUT
  Widget _buildShareOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8), // Reduced padding
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Important: minimize height
          children: [
            Icon(icon, color: color, size: 20), // Smaller icon
            const SizedBox(height: 2), // Reduced spacing
            Flexible( // Wrap text in Flexible
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12, // Smaller font
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible( // Wrap subtitle in Flexible
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10, // Smaller font
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Handle different share actions
  Future<void> _handleShareAction(File fileToShare, String action) async {
    setState(() => _isSharing = true);

    try {
      switch (action) {
        case 'email':
          await _shareViaEmail(fileToShare);
          break;
        case 'bluetooth':
          await _shareViaBluetooth(fileToShare);
          break;
        case 'folder':
          await _saveToSpecificFolder(fileToShare);
          break;
        case 'system':
          await _shareViaSystemApps(fileToShare);
          break;
        case 'quick':
        default:
          await _shareViaQuickShare(fileToShare);
          break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in share action "$action": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

// Share via email
  Future<void> _shareViaEmail(File fileToShare) async {
    try {
      final customerName = widget.customer?.name ?? 'Customer';
      final subject = 'Quote PDF: ${widget.suggestedFileName}';
      final body = '''
Hello $customerName,

Please find your quote attached as a PDF document.

${widget.quote != null ? '''
Quote Details:
- Quote Number: ${widget.quote!.quoteNumber}
- Date: ${DateFormat('MM/dd/yyyy').format(widget.quote!.createdAt)}
- Status: ${widget.quote!.status}
''' : ''}

Best regards,
${_getCompanyName()}
    ''';

      await SharePlus.instance.share(
        ShareParams(
          subject: subject,
          text: body,
          files: [XFile(fileToShare.path)],
        ),
      );

      _showShareSuccessMessage('Email app opened');
    } catch (e) {
      throw Exception('Failed to open email app: $e');
    }
  }

// Share via Bluetooth - UPDATED
  Future<void> _shareViaBluetooth(File fileToShare) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'PDF Document: ${widget.suggestedFileName}',
          files: [XFile(fileToShare.path, mimeType: 'application/pdf')],
        ),
      );

      _showShareSuccessMessage('Bluetooth sharing initiated');
    } catch (e) {
      throw Exception('Failed to share via Bluetooth: $e');
    }
  }

// Share via system apps - UPDATED
  Future<void> _shareViaSystemApps(File fileToShare) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'PDF Document: ${widget.suggestedFileName}',
          files: [XFile(fileToShare.path)],
        ),
      );

      _showShareSuccessMessage('Share menu opened');
    } catch (e) {
      throw Exception('Failed to open share menu: $e');
    }
  }

// Quick share (system default) - UPDATED
  Future<void> _shareViaQuickShare(File fileToShare) async {
    try {
      final customerInfo = widget.customer != null ? '\nCustomer: ${widget.customer!.name}' : '';
      final quoteInfo = widget.quote != null ? '\nQuote: ${widget.quote!.quoteNumber}' : '';

      await SharePlus.instance.share(
        ShareParams(
          text: 'PDF: ${widget.suggestedFileName}$customerInfo$quoteInfo',
          subject: widget.suggestedFileName,
          files: [XFile(fileToShare.path)],
        ),
      );

      _showShareSuccessMessage('Shared successfully');
    } catch (e) {
      throw Exception('Failed to share: $e');
    }
  }
// Save to specific folder with folder selection
  Future<void> _saveToSpecificFolder(File fileToShare) async {
    try {
      debugPrint('📁 Starting folder selection for PDF save...');

      // Show folder selection dialog
      final selectedPath = await _showFolderSelectionDialog();

      if (selectedPath == null) {
        _showShareSuccessMessage('Save cancelled');
        return;
      }

      debugPrint('📁 Selected save path: $selectedPath');

      // Save to selected folder
      await _saveFileToDirectory(fileToShare, selectedPath);

    } catch (e) {
      debugPrint('❌ Error saving to folder: $e');
      throw Exception('Failed to save to folder: $e');
    }
  }

// Show folder selection dialog
  Future<String?> _showFolderSelectionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_open, color: Color(0xFF2E86AB)),
            SizedBox(width: 8),
            Text('Choose Save Location'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select where you want to save the PDF:'),
              const SizedBox(height: 16),

              // Common folder options
              _buildFolderOption(
                icon: Icons.download,
                title: 'Downloads',
                subtitle: 'Default downloads folder',
                onTap: () async {
                  try {
                    final directory = await getExternalStorageDirectory();
                    if (directory != null) {
                      final downloadsPath = '${directory.parent.parent.parent.parent.path}/Download';
                      final downloadsDir = Directory(downloadsPath);
                      if (await downloadsDir.exists()) {
                        Navigator.pop(context, downloadsPath);
                      } else {
                        // Fallback to app documents directory
                        final appDir = await getApplicationDocumentsDirectory();
                        Navigator.pop(context, appDir.path);
                      }
                    } else {
                      final appDir = await getApplicationDocumentsDirectory();
                      Navigator.pop(context, appDir.path);
                    }
                  } catch (e) {
                    final appDir = await getApplicationDocumentsDirectory();
                    Navigator.pop(context, appDir.path);
                  }
                },
              ),
              const SizedBox(height: 8),

              _buildFolderOption(
                icon: Icons.folder,
                title: 'Documents',
                subtitle: 'Documents folder',
                onTap: () async {
                  final directory = await getApplicationDocumentsDirectory();
                  Navigator.pop(context, directory.path);
                },
              ),
              const SizedBox(height: 8),

              _buildFolderOption(
                icon: Icons.business,
                title: 'Rufko Quotes',
                subtitle: 'App quotes folder',
                onTap: () async {
                  final directory = await getApplicationDocumentsDirectory();
                  final quotesDir = Directory('${directory.path}/quotes');
                  if (!await quotesDir.exists()) {
                    await quotesDir.create(recursive: true);
                  }
                  Navigator.pop(context, quotesDir.path);
                },
              ),
              const SizedBox(height: 8),

              if (widget.customer != null)
                _buildFolderOption(
                  icon: Icons.person,
                  title: 'Customer Folder',
                  subtitle: 'Folder for ${widget.customer!.name}',
                  onTap: () async {
                    final directory = await getApplicationDocumentsDirectory();
                    final customerName = widget.customer!.name.replaceAll(RegExp(r'[^\w\s-]'), '');
                    final customerDir = Directory('${directory.path}/customers/$customerName');
                    if (!await customerDir.exists()) {
                      await customerDir.create(recursive: true);
                    }
                    Navigator.pop(context, customerDir.path);
                  },
                ),
              const SizedBox(height: 16),

              // Custom folder option
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _selectCustomFolder();
                },
                icon: const Icon(Icons.folder_special),
                label: const Text('Choose Custom Folder'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E86AB),
                  side: const BorderSide(color: Color(0xFF2E86AB)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

// Build folder option widget - FIXED LAYOUT
  Widget _buildFolderOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E86AB), size: 24),
            const SizedBox(width: 12),
            Expanded( // Wrap in Expanded to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

// Select custom folder using file picker
  Future<void> _selectCustomFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        debugPrint('📁 Custom folder selected: $selectedDirectory');

        // Get the file to save again
        File fileToSave;
        if (_editedValues.isNotEmpty && _formFields.isNotEmpty) {
          fileToSave = await _applyFormFieldEditsToPdf();
        } else {
          fileToSave = File(_currentPdfPath);
        }

        // Save to the selected custom directory
        await _saveFileToDirectory(fileToSave, selectedDirectory);
      } else {
        _showShareSuccessMessage('Folder selection cancelled');
      }
    } catch (e) {
      debugPrint('❌ Error selecting custom folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select folder: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Save file to specific directory
  Future<void> _saveFileToDirectory(File sourceFile, String directoryPath) async {
    try {
      String fileName = widget.suggestedFileName;
      if (_editedValues.isNotEmpty && !fileName.contains('_edited')) {
        fileName = fileName.replaceAll('.pdf', '_edited.pdf');
      }

      File targetFile = File('$directoryPath/$fileName');
      int counter = 1;

      while (await targetFile.exists()) {
        final baseName = fileName.replaceAll('.pdf', '');
        final newFileName = '${baseName}_$counter.pdf';
        targetFile = File('$directoryPath/$newFileName');
        counter++;
      }

      await sourceFile.copy(targetFile.path);

      if (mounted) {
        _showSaveSuccessDialog(targetFile.path, directoryPath);
      }
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }
// Show save success dialog with actions - FIXED LAYOUT (NO EXPANDED IN ACTIONS)
  void _showSaveSuccessDialog(String filePath, String directoryPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded( // This Expanded is fine - it's in a Row
              child: Text(
                'PDF Saved Successfully!',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your PDF has been saved to:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'File: ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Expanded( // This Expanded is fine - it's in a Row
                          child: Text(
                            filePath.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded( // This Expanded is fine - it's in a Row
                          child: Text(
                            directoryPath,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_editedValues.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Expanded( // This Expanded is fine - it's in a Row
                        child: Text(
                          '${_editedValues.length} edits were applied to this PDF',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          // REMOVED Expanded wrapper - AlertDialog actions don't support Expanded
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              OpenFilex.open(filePath);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

// Helper method to get company name
  String _getCompanyName() {
    // You can get this from app settings or use a default
    return 'Your Company Name';
  }

// Show share success message
  void _showShareSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('✅ $message'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

// Format file size helper
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Discard PDF
  void _discardPdf() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard PDF?'),
        content: Text(
          _editHistory.isNotEmpty
              ? 'Are you sure you want to discard this PDF and all ${_editHistory.length} edits? This action cannot be undone.'
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
        title: const Text('Clear All Edits?'),
        content: const Text(
          'This will remove all changes you have made to the PDF form fields.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _editedValues.clear();
                _editHistory.clear();
                _currentHistoryIndex = -1;
                _selectedField = null;
                _hasEdits = false;
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

}

// Show field selector dialog - DEBUGGING TOOL

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
    debugPrint('🎨 Painting ${formFields.length} form field overlays on canvas ${size.width}x${size.height}');

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