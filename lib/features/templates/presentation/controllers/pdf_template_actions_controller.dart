import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/template_editor_screen.dart';
import '../../../quotes/presentation/screens/pdf_preview_screen.dart';

/// Controller for managing PDF template actions and operations
/// Extracted from PdfTemplatesTab to separate business logic from UI
class PdfTemplateActionsController extends ChangeNotifier {
  final BuildContext context;

  // State variables
  bool _isLoading = false;
  String? _error;

  PdfTemplateActionsController({
    required this.context,
  });

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setters with notification
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Navigate to template editor
  void navigateToEditor([PDFTemplate? existingTemplate]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorScreen(
          existingTemplate: existingTemplate,
          // Don't pass preselectedCategory for existing templates
          // New templates are handled by templates_screen.dart
        ),
      ),
    );
  }

  /// Handle template action from popup menu
  Future<void> handleTemplateAction(String action, PDFTemplate template) async {
    switch (action) {
      case 'edit':
        navigateToEditor(template);
        break;
      case 'preview':
        await previewTemplate(template);
        break;
      case 'toggle_active':
        await toggleTemplateActive(template);
        break;
      case 'rename':
        await renameTemplate(template);
        break;
      case 'delete':
        await deleteTemplate(template);
        break;
    }
  }

  /// Generate and preview template
  Future<void> previewTemplate(PDFTemplate template) async {
    final navigator = Navigator.of(context);
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating preview...'),
            ],
          ),
        ),
      );

      final appState = context.read<AppStateProvider>();
      final previewPath = await appState.generateTemplatePreview(template);

      navigator.pop(); // Close loading dialog

      navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: previewPath,
            suggestedFileName: 'Preview_${template.templateName}.pdf',
            title: 'Template Preview: ${template.templateName}',
            isPreview: true,
          ),
        ),
      );

      debugPrint('👁️ Previewed template: ${template.templateName}');
    } catch (e) {
      navigator.pop(); // Close loading dialog
      _error = 'Error generating preview: $e';
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Preview failed: $e');
    }
  }

  /// Toggle template active status
  Future<void> toggleTemplateActive(PDFTemplate template) async {
    try {
      await context.read<AppStateProvider>().togglePDFTemplateActive(template.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      debugPrint('🔄 Toggled template active: ${template.templateName}');
    } catch (e) {
      _error = 'Error toggling template status: $e';
      notifyListeners();
      debugPrint('❌ Toggle active failed: $e');
    }
  }

  /// Show rename dialog and handle renaming
  Future<void> renameTemplate(PDFTemplate template) async {
    final newName = await _showRenameDialog(template);
    if (newName != null && newName.trim().isNotEmpty && newName.trim() != template.templateName) {
      await _performRename(template, newName.trim());
    }
  }

  /// Show rename dialog
  Future<String?> _showRenameDialog(PDFTemplate template) async {
    final TextEditingController controller = TextEditingController(text: template.templateName);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRenameDialogHeader(),
                _buildRenameDialogContent(template, controller),
                _buildRenameDialogActions(template, controller),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build rename dialog header
  Widget _buildRenameDialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3), // RufkoTheme.primaryColor
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Rename Template',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build rename dialog content
  Widget _buildRenameDialogContent(PDFTemplate template, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current name: ${template.templateName}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'New Template Name',
              hintText: 'Enter a new name for this template',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 14),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (value) {
              // Allow Enter key to submit
              if (value.trim().isNotEmpty && value.trim() != template.templateName) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build rename dialog actions
  Widget _buildRenameDialogActions(PDFTemplate template, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != template.templateName) {
                Navigator.of(context).pop(newName);
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3), // RufkoTheme.primaryColor
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  /// Perform the actual rename operation
  Future<void> _performRename(PDFTemplate template, String newName) async {
    try {
      // Modify the original template directly - DON'T clone
      template.templateName = newName;
      template.updatedAt = DateTime.now();

      // Update in the app state using the same template object
      await context.read<AppStateProvider>().updatePDFTemplate(template);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Renamed template to: $newName'),
            backgroundColor: Colors.green,
          ),
        );
      }
      debugPrint('✏️ Renamed template: ${template.templateName}');
    } catch (e) {
      _error = 'Error renaming template: $e';
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Rename failed: $e');
    }
  }

  /// Show delete confirmation and handle deletion
  Future<void> deleteTemplate(PDFTemplate template) async {
    final confirmed = await _showDeleteConfirmationDialog(template);
    
    if (confirmed == true && context.mounted) {
      try {
        await context.read<AppStateProvider>().deletePDFTemplate(template.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted: ${template.templateName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        debugPrint('🗑️ Deleted template: ${template.templateName}');
      } catch (e) {
        _error = 'Error deleting template: $e';
        notifyListeners();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting template: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        debugPrint('❌ Delete failed: $e');
      }
    }
  }

  /// Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmationDialog(PDFTemplate template) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${template.templateName}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template: ${template.templateName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (template.description.isNotEmpty)
                    Text('Description: ${template.description}'),
                  Text('Type: ${template.templateType}'),
                  Text('Category: ${template.userCategoryKey ?? 'No Category'}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone and will also delete the associated PDF file.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🧹 PdfTemplateActionsController disposed');
    super.dispose();
  }
}