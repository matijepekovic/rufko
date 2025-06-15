import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/template_management_service.dart';
import '../../../quotes/presentation/screens/pdf_preview_screen.dart';

/// Controller for template operations (save, preview, category management)
/// Extracted from TemplateEditorScreen for better separation of concerns
class TemplateOperationsController extends ChangeNotifier {
  final BuildContext _context;
  
  PDFTemplate? _currentTemplate;
  String? _selectedCategoryKey;
  bool _isLoading = false;
  String _loadingMessage = '';

  TemplateOperationsController(this._context);

  // Getters
  PDFTemplate? get currentTemplate => _currentTemplate;
  String? get selectedCategoryKey => _selectedCategoryKey;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  AppStateProvider get _appState => _context.read<AppStateProvider>();
  ScaffoldMessengerState get _messenger => ScaffoldMessenger.of(_context);
  NavigatorState get _navigator => Navigator.of(_context);

  /// Initialize with existing template or category
  void initialize({PDFTemplate? existingTemplate, String? preselectedCategory}) {
    if (existingTemplate != null) {
      _currentTemplate = existingTemplate;
      _selectedCategoryKey ??= existingTemplate.userCategoryKey;
    } else {
      _selectedCategoryKey = preselectedCategory;
      if (kDebugMode) {
        debugPrint('🔍 Creating new template with category: $_selectedCategoryKey');
      }
    }
    notifyListeners();
  }

  /// Update current template
  void updateTemplate(PDFTemplate template) {
    _currentTemplate = template;
    _selectedCategoryKey ??= template.userCategoryKey;
    notifyListeners();
  }

  /// Update selected category
  void updateCategory(String? categoryKey) {
    _selectedCategoryKey = categoryKey;
    if (_currentTemplate != null) {
      _currentTemplate!.userCategoryKey = categoryKey;
    }
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool isLoading, [String message = '']) {
    if (!_context.mounted) return;
    _isLoading = isLoading;
    _loadingMessage = message;
    notifyListeners();
  }

  /// Save current template
  Future<void> saveTemplate() async {
    if (_currentTemplate == null) {
      if (kDebugMode) debugPrint('❌ No template to save');
      return;
    }
    if (!_context.mounted) return;

    if (kDebugMode) {
      debugPrint('💾 Starting save for template: ${_currentTemplate!.templateName}');
      debugPrint('📍 Template ID: ${_currentTemplate!.id}');
      debugPrint('📍 Field mappings: ${_currentTemplate!.fieldMappings.length}');
    }

    try {
      _currentTemplate!.userCategoryKey = _selectedCategoryKey;
      await TemplateManagementService.instance
          .saveTemplate(_currentTemplate!, _appState);

      if (!_context.mounted) return;
      _messenger.showSnackBar(
        const SnackBar(
          content: Text('Template saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      _navigator.pop();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving template: $e');
      if (_context.mounted) {
        _messenger.showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generate and preview template with sample data
  Future<void> previewTemplate() async {
    if (_currentTemplate == null) return;
    
    setLoading(true, 'Generating preview...');
    
    try {
      final previewPath = await TemplateManagementService.instance
          .generateTemplatePreview(_currentTemplate!, _appState);
      setLoading(false);

      if (!_context.mounted) return;

      // Navigate to PdfPreviewScreen
      _navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: previewPath,
            suggestedFileName: 'Preview_${_currentTemplate!.templateName}.pdf',
            title: 'Template Preview: ${_currentTemplate!.templateName}',
            isPreview: true,
            templateId: _currentTemplate!.id,
          ),
        ),
      );
    } catch (e) {
      setLoading(false);
      if (!_context.mounted) return;
      _messenger.showSnackBar(
        SnackBar(
          content: Text('Error generating preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Update template timestamp and category
  void markTemplateUpdated() {
    if (_currentTemplate != null) {
      _currentTemplate!.updatedAt = DateTime.now();
      _currentTemplate!.userCategoryKey = _selectedCategoryKey;
      notifyListeners();
    }
  }

  /// Show template name input dialog
  Future<String?> showTemplateNameDialog(String defaultName) {
    final controller = TextEditingController(text: defaultName);
    return showDialog<String?>(
      context: _context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Template Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter template name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              } else {
                ScaffoldMessenger.of(_context).showSnackBar(
                  const SnackBar(
                    content: Text("Template name cannot be empty."),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

}