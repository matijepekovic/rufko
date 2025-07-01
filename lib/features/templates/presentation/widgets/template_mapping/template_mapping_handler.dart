import 'package:flutter/material.dart';
import '../../controllers/template_field_mapping_ui_controller.dart';
import '../editor/field_mapping_bottom_sheet.dart';
import '../editor/field_selection_dialog.dart';
import '../../../../../data/models/business/product.dart';

/// Widget that handles UI concerns for template field mapping operations
/// Separates UI concerns from business logic by managing dialogs, bottom sheets, and snackbars
class TemplateMappingHandler extends StatefulWidget {
  final TemplateFieldMappingUIController controller;
  final Widget child;

  const TemplateMappingHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<TemplateMappingHandler> createState() => _TemplateMappingHandlerState();
}

class _TemplateMappingHandlerState extends State<TemplateMappingHandler> {
  /// Public methods for backward compatibility and external access
  void showFieldMappingDialog(Map<String, dynamic> pdfFieldInfo) =>
      _showFieldMappingBottomSheet(pdfFieldInfo);
  
  void showFieldSelectionDialog(Map<String, dynamic> pdfFieldInfo) =>
      _showFieldSelectionDialog(pdfFieldInfo);

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

  /// Show field mapping bottom sheet
  void _showFieldMappingBottomSheet(Map<String, dynamic> pdfFieldInfo) {
    if (widget.controller.currentTemplate == null) return;

    final pdfFieldName = pdfFieldInfo['name'] as String? ?? 'Unknown Field';
    widget.controller.selectPdfField(pdfFieldInfo);

    // Get existing mapping
    final currentMapping = widget.controller.getExistingMapping(pdfFieldName);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FieldMappingBottomSheet(
          pdfFieldName: pdfFieldName,
          currentMapping: currentMapping,
          onUnlink: currentMapping != null
              ? () {
                  Navigator.pop(context);
                  _unlinkField(currentMapping);
                }
              : null,
          onChangeMapping: () {
            Navigator.pop(context);
            _showFieldSelectionDialog(pdfFieldInfo);
          },
        );
      },
    );
  }

  /// Show field selection dialog
  void _showFieldSelectionDialog(Map<String, dynamic> pdfFieldInfo) {
    if (widget.controller.currentTemplate == null) return;

    final pdfFieldName = pdfFieldInfo['name'] as String? ?? "Unknown Field";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => FieldSelectionDialog(
        pdfFieldName: pdfFieldName,
        template: widget.controller.currentTemplate!,
        products: widget.controller.products.cast<Product>(),
        customFields: widget.controller.customFields,
        onSelect: (field) {
          _handleFieldSelection(field, pdfFieldInfo);
        },
      ),
    );
  }

  /// Handle field selection
  void _handleFieldSelection(String appDataType, Map<String, dynamic> pdfFieldInfo) {
    // Check if this field is already mapped and needs replacement confirmation
    if (widget.controller.needsReplacementConfirmation(appDataType)) {
      _showReplacementConfirmationDialog(appDataType, pdfFieldInfo);
    } else {
      // Direct mapping without confirmation
      widget.controller.createFieldMapping(
        appDataType: appDataType,
        pdfFieldInfo: pdfFieldInfo,
        replaceExisting: false,
      );
    }
  }

  /// Show replacement confirmation dialog
  void _showReplacementConfirmationDialog(
    String appDataType,
    Map<String, dynamic> pdfFieldInfo,
  ) {
    final pdfFieldName = pdfFieldInfo['name'] as String;
    final displayName = widget.controller.getFieldDisplayName(appDataType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              widget.controller.createFieldMapping(
                appDataType: appDataType,
                pdfFieldInfo: pdfFieldInfo,
                replaceExisting: true,
              );
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  /// Unlink field mapping
  void _unlinkField(dynamic mapping) {
    widget.controller.removeFieldMapping(mapping);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            if (widget.controller.isProcessing)
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