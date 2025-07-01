import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../data/models/ui/pdf_form_field.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import 'pdf_editing_controller.dart';
import 'pdf_file_operations_controller.dart';
import 'pdf_viewer_ui_builder.dart';
import '../../../templates/presentation/controllers/template_field_dialog_manager.dart';

/// Controller that coordinates all PDF preview operations
/// Manages the state and interactions between different PDF controllers
class PdfPreviewController extends ChangeNotifier {
  final BuildContext context;
  
  late final PdfFileOperationsController _fileOpsController;
  late final PdfViewerUIBuilder _uiBuilder;
  late final TemplateFieldDialogManager _dialogManager;
  late final PdfEditingController _editingController;
  
  final GlobalKey<SfPdfViewerState> pdfViewerKey = GlobalKey();
  final PdfViewerController pdfController = PdfViewerController();
  final GlobalKey pdfViewerContainerKey = GlobalKey();

  final String _currentPdfPath;
  bool _isSaving = false;
  bool _hasEdits = false;
  bool _showEditingTools = false;
  bool _isLoadingFields = false;
  List<PDFFormField> _formFields = [];
  List<String> _editableFields = [];

  // Screen configuration
  final String suggestedFileName;
  final SimplifiedMultiLevelQuote? quote;
  final Customer? customer;
  final String? templateId;
  final String? selectedLevelId;
  final Map<String, String>? originalCustomData;
  final String? title;
  final bool isPreview;

  PdfPreviewController({
    required this.context,
    required String pdfPath,
    required this.suggestedFileName,
    this.quote,
    this.customer,
    this.templateId,
    this.selectedLevelId,
    this.originalCustomData,
    this.title,
    this.isPreview = false,
  }) : _currentPdfPath = pdfPath {
    _initializeControllers();
  }

  // Getters
  String get currentPdfPath => _currentPdfPath;
  bool get isSaving => _isSaving;
  bool get hasEdits => _hasEdits;
  bool get showEditingTools => _showEditingTools;
  bool get isLoadingFields => _isLoadingFields;
  List<PDFFormField> get formFields => _formFields;
  List<String> get editableFields => _editableFields;

  PdfFileOperationsController get fileOpsController => _fileOpsController;
  PdfViewerUIBuilder get uiBuilder => _uiBuilder;
  TemplateFieldDialogManager get dialogManager => _dialogManager;
  PdfEditingController get editingController => _editingController;

  void _initializeControllers() {
    _editingController = PdfEditingController();
    _fileOpsController = PdfFileOperationsController(context);
    _dialogManager = TemplateFieldDialogManager(context, _editingController);
    _uiBuilder = PdfViewerUIBuilder(
      context,
      pdfViewerKey: pdfViewerKey,
      pdfController: pdfController,
      editingController: _editingController,
      getCurrentFieldValue: getCurrentFieldValue,
      showTemplateFieldEditDialog: _dialogManager.showEditDialog,
    );

    _editingController.addListener(() {
      _hasEdits = _editingController.hasEdits;
      notifyListeners();
    });

    _loadEditableFields();
    _loadFormFields();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setLoadingFields(bool loading) {
    _isLoadingFields = loading;
    notifyListeners();
  }

  void toggleEditingTools() {
    _showEditingTools = !_showEditingTools;
    notifyListeners();
  }

  /// Load editable fields for the current template
  Future<void> _loadEditableFields() async {
    if (templateId == null) return;

    try {
      final appState = context.read<AppStateProvider>();
      final template = appState.pdfTemplates
          .where((t) => t.id == templateId)
          .firstOrNull;

      if (template != null) {
        _editableFields = template.fieldMappings.keys.toList();
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently or log if needed
    }
  }

  /// Load form fields from the PDF
  Future<void> _loadFormFields() async {
    _setLoadingFields(true);
    
    try {
      // For now, we'll create empty form fields since the actual extraction method doesn't exist
      // This would be implemented with a proper PDF form field extraction library
      _formFields = [];
    } catch (e) {
      // Handle error silently or log if needed
      _formFields = [];
    } finally {
      _setLoadingFields(false);
    }
  }

  /// Get current field value for display
  String getCurrentFieldValue(String fieldKey) {
    return _editingController.getFieldValue(fieldKey);
  }

  /// Save PDF with current edits
  Future<void> savePdf() async {
    _setSaving(true);
    
    try {
      final success = await _fileOpsController.uiController.savePdf(
        currentPdfPath: _currentPdfPath,
        editedValues: _editingController.getCurrentEdits(),
        formFields: _formFields,
        suggestedFileName: suggestedFileName,
        customer: customer,
        quote: quote,
        templateId: templateId,
      );
      
      if (success) {
        _editingController.clearEdits();
        _hasEdits = false;
      }
    } finally {
      _setSaving(false);
    }
  }

  /// Share PDF
  Future<void> sharePdf() async {
    _setSharing(true);
    
    try {
      await _fileOpsController.uiController.sharePdf(
        currentPdfPath: _currentPdfPath,
        editedValues: _editingController.getCurrentEdits(),
        formFields: _formFields,
        suggestedFileName: suggestedFileName,
        customer: customer,
        shareFileCallback: ({
          required String filePath,
          required String fileName,
          Customer? customer,
        }) async {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF prepared for sharing: $fileName')),
            );
          }
        },
      );
    } finally {
      _setSharing(false);
    }
  }
  
  void _setSharing(bool sharing) {
    // Add sharing state if not already present
    notifyListeners();
  }

  /// Handle back navigation with unsaved changes check
  Future<bool> handleBackNavigation() async {
    if (!_hasEdits) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  void dispose() {
    _editingController.dispose();
    pdfController.dispose();
    super.dispose();
  }
}
