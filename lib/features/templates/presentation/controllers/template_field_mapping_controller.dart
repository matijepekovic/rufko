import 'package:flutter/material.dart';
import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/models/business/product.dart';
import 'template_field_mapping_ui_controller.dart';
import '../widgets/template_mapping/template_mapping_handler.dart';
import '../widgets/editor/field_selection_dialog.dart';

/// Refactored TemplateFieldMappingController using clean architecture
/// Now acts as a coordinator between UI and business logic
class TemplateFieldMappingController extends ChangeNotifier {
  TemplateFieldMappingController(BuildContext context, {this.onTemplateUpdated})
      : _uiController = TemplateFieldMappingUIController.fromContext(context),
        _context = context;

  final TemplateFieldMappingUIController _uiController;
  final BuildContext _context;
  final VoidCallback? onTemplateUpdated;

  /// Get the UI controller for use in widgets
  TemplateFieldMappingUIController get uiController => _uiController;

  /// Create a handler widget that manages UI concerns
  Widget createTemplateMappingHandler({
    Key? key,
    required Widget child,
  }) {
    return TemplateMappingHandler(
      key: key,
      controller: _uiController,
      child: child,
    );
  }

  // Legacy getters for backward compatibility
  PDFTemplate? get currentTemplate => _uiController.currentTemplate;

  /// Legacy methods for backward compatibility - now delegate to handler
  void initializeWithTemplate(PDFTemplate? template) {
    _uiController.initializeWithTemplate(template);
  }

  void updateTemplate(PDFTemplate template) {
    _uiController.updateTemplate(template);
  }

  @Deprecated('Use TemplateMappingHandler.showFieldMappingDialog() in new architecture')
  void showFieldMappingDialog(Map<String, dynamic> pdfFieldInfo) {
    if (_uiController.currentTemplate == null) {
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text('No template loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdfFieldName = pdfFieldInfo['name'] as String? ?? 'Unknown Field';
    _uiController.selectPdfField(pdfFieldInfo);

    // Get existing mapping
    final currentMapping = _uiController.getExistingMapping(pdfFieldName);

    // If there's an existing mapping, show quick action to unlink or change
    if (currentMapping != null) {
      _showQuickMappingActions(pdfFieldInfo, currentMapping);
    } else {
      // No existing mapping, go directly to field selection
      _showFieldSelectionDirectly(pdfFieldInfo);
    }
  }

  /// Show quick actions for existing mappings (unlink or change)
  void _showQuickMappingActions(Map<String, dynamic> pdfFieldInfo, dynamic currentMapping) {
    final pdfFieldName = pdfFieldInfo['name'] as String? ?? 'Unknown Field';

    showDialog(
      context: _context,
      builder: (context) => ListenableBuilder(
        listenable: _uiController,
        builder: (context, child) {
          // Get fresh mapping data on each rebuild
          final freshMapping = _uiController.getExistingMapping(pdfFieldName);
          
          // If mapping was removed, close dialog
          if (freshMapping == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const SizedBox.shrink();
          }

          final displayName = freshMapping.appDataType != null 
              ? PDFTemplate.getFieldDisplayName(freshMapping.appDataType)
              : 'Unknown Field';

          return AlertDialog(
            title: Text('Field: $pdfFieldName'),
            content: Text('Currently linked to: $displayName'),
            actions: [
              TextButton(
                onPressed: () async {
                  await _unlinkField(freshMapping);
                  // Dialog will auto-close due to ListenableBuilder detecting the change
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Unlink'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showFieldSelectionDirectly(pdfFieldInfo);
                },
                child: const Text('Change'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Internal method to show field selection dialog without deprecation warning
  void _showFieldSelectionDirectly(Map<String, dynamic> pdfFieldInfo) {
    if (_uiController.currentTemplate == null) return;

    final pdfFieldName = pdfFieldInfo['name'] as String? ?? "Unknown Field";

    showDialog(
      context: _context,
      barrierDismissible: true,
      builder: (_) => ListenableBuilder(
        listenable: _uiController,
        builder: (context, child) {
          // Check if template still exists
          if (_uiController.currentTemplate == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const SizedBox.shrink();
          }

          return FieldSelectionDialog(
            pdfFieldName: pdfFieldName,
            template: _uiController.currentTemplate!,
            products: _uiController.products.cast<Product>(),
            customFields: _uiController.customFields,
            onSelect: (field) {
              Navigator.pop(context); // Close dialog immediately
              _handleFieldSelection(field, pdfFieldInfo);
            },
          );
        },
      ),
    );
  }

  @Deprecated('Use TemplateMappingHandler.showFieldSelectionDialog() in new architecture')
  void showFieldSelectionDialog(Map<String, dynamic> pdfFieldInfo) {
    if (_uiController.currentTemplate == null) return;

    final pdfFieldName = pdfFieldInfo['name'] as String? ?? "Unknown Field";

    showDialog(
      context: _context,
      barrierDismissible: true,
      builder: (_) => ListenableBuilder(
        listenable: _uiController,
        builder: (context, child) {
          // Check if template still exists
          if (_uiController.currentTemplate == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const SizedBox.shrink();
          }

          return FieldSelectionDialog(
            pdfFieldName: pdfFieldName,
            template: _uiController.currentTemplate!,
            products: _uiController.products.cast<Product>(),
            customFields: _uiController.customFields,
            onSelect: (field) {
              Navigator.pop(context); // Close dialog immediately
              _handleFieldSelection(field, pdfFieldInfo);
            },
          );
        },
      ),
    );
  }

  Future<void> _unlinkField(dynamic mapping) async {
    try {
      // Clear any existing messages to prevent conflicts
      _uiController.clearMessages();
      
      await _uiController.removeFieldMapping(mapping);
      
      // Clear the success message from UI controller to prevent handler conflicts
      _uiController.clearMessages();
      
      // Force UI update to reflect changes immediately
      notifyListeners();
      
      // Notify parent that template was updated (for PDF viewer refresh)
      onTemplateUpdated?.call();
      
      // Show success feedback without causing navigation
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Field mapping removed successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Error removing field mapping: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle field selection from dialog
  void _handleFieldSelection(String appDataType, Map<String, dynamic> pdfFieldInfo) {
    // Check if this field is already mapped and needs replacement confirmation
    if (_uiController.needsReplacementConfirmation(appDataType)) {
      _showReplacementConfirmationDialog(appDataType, pdfFieldInfo);
    } else {
      // Direct mapping without confirmation
      _createFieldMappingWithFeedback(
        appDataType: appDataType,
        pdfFieldInfo: pdfFieldInfo,
        replaceExisting: false,
      );
    }
  }

  /// Create field mapping with user feedback
  Future<void> _createFieldMappingWithFeedback({
    required String appDataType,
    required Map<String, dynamic> pdfFieldInfo,
    required bool replaceExisting,
  }) async {
    try {
      // Clear any existing messages to prevent conflicts
      _uiController.clearMessages();
      
      await _uiController.createFieldMapping(
        appDataType: appDataType,
        pdfFieldInfo: pdfFieldInfo,
        replaceExisting: replaceExisting,
      );
      
      // Clear the success message from UI controller to prevent handler conflicts
      _uiController.clearMessages();
      
      // Force UI update to reflect changes immediately
      notifyListeners();
      
      // Notify parent that template was updated (for PDF viewer refresh)
      onTemplateUpdated?.call();
      
      final pdfFieldName = pdfFieldInfo['name'] as String? ?? 'Unknown Field';
      final displayName = PDFTemplate.getFieldDisplayName(appDataType);
      
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Linked "$displayName" to "$pdfFieldName"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Error creating field mapping: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show replacement confirmation dialog
  void _showReplacementConfirmationDialog(
    String appDataType,
    Map<String, dynamic> pdfFieldInfo,
  ) {
    final pdfFieldName = pdfFieldInfo['name'] as String;

    showDialog(
      context: _context,
      builder: (context) => ListenableBuilder(
        listenable: _uiController,
        builder: (context, child) {
          final displayName = _uiController.getFieldDisplayName(appDataType);
          
          // Check if we still need replacement confirmation
          if (!_uiController.needsReplacementConfirmation(appDataType)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const SizedBox.shrink();
          }

          return AlertDialog(
            title: const Text('Replace Existing Mapping?'),
            content: Text(
              'This will unlink "$displayName" from its current PDF field and link it to "$pdfFieldName" instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _createFieldMappingWithFeedback(
                    appDataType: appDataType,
                    pdfFieldInfo: pdfFieldInfo,
                    replaceExisting: true,
                  );
                },
                child: const Text('Replace'),
              ),
            ],
          );
        },
      ),
    );
  }

  @Deprecated('Use TemplateFieldMappingUIController.createFieldMapping() in new architecture')
  void confirmMapping(String appDataType, Map<String, dynamic> pdfFieldInfo, bool isReplacing) {
    debugPrint('confirmMapping() called - use TemplateFieldMappingUIController.createFieldMapping() in new architecture');
  }

  @Deprecated('Use TemplateFieldMappingUIController.createFieldMapping() in new architecture')
  void performMapping(String appDataType, Map<String, dynamic> pdfFieldInfo) {
    debugPrint('performMapping() called - use TemplateFieldMappingUIController.createFieldMapping() in new architecture');
  }

  @Deprecated('Use TemplateFieldMappingUIController.removeFieldMapping() in new architecture')
  void unlinkField(dynamic mapping) {
    debugPrint('unlinkField() called - use TemplateFieldMappingUIController.removeFieldMapping() in new architecture');
  }

  /// Clean up resources
  @override
  void dispose() {
    _uiController.dispose();
    super.dispose();
  }
}