import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/pdf/pdf_field_mapping_service.dart';
import '../widgets/editor/field_mapping_bottom_sheet.dart';
import '../widgets/editor/field_selection_dialog.dart';

/// Controller for PDF field mapping operations
/// Handles field selection, mapping confirmation, and unmapping
class TemplateFieldMappingController extends ChangeNotifier {
  final BuildContext _context;
  
  PDFTemplate? _currentTemplate;

  TemplateFieldMappingController(this._context);

  // Getters
  PDFTemplate? get currentTemplate => _currentTemplate;
  AppStateProvider get _appState => _context.read<AppStateProvider>();
  ScaffoldMessengerState get _messenger => ScaffoldMessenger.of(_context);

  /// Initialize with template
  void initializeWithTemplate(PDFTemplate? template) {
    _currentTemplate = template;
    notifyListeners();
  }

  /// Update current template
  void updateTemplate(PDFTemplate template) {
    _currentTemplate = template;
    notifyListeners();
  }

  /// Show field mapping bottom sheet for PDF field
  void showFieldMappingDialog(Map<String, dynamic> pdfFieldInfo) {
    if (_currentTemplate == null) return;
    
    final pdfFieldName = pdfFieldInfo['name'] as String? ?? 'Unknown Field';

    // Find existing mapping for this PDF field if any
    FieldMapping? currentMapping;
    try {
      currentMapping = _currentTemplate!.fieldMappings.firstWhere(
        (m) => m.pdfFormFieldName == pdfFieldName,
      );
    } catch (e) {
      currentMapping = null;
    }

    showModalBottomSheet(
      context: _context,
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
                  unlinkField(currentMapping!);
                }
              : null,
          onChangeMapping: () {
            Navigator.pop(context);
            showFieldSelectionDialog(pdfFieldInfo);
          },
        );
      },
    );
  }

  /// Show field selection dialog
  void showFieldSelectionDialog(Map<String, dynamic> pdfFieldInfo) {
    if (_currentTemplate == null) return;
    
    final pdfFieldName = pdfFieldInfo['name'] as String? ?? "Unknown Field";
    
    showDialog(
      context: _context,
      barrierDismissible: true,
      builder: (_) => FieldSelectionDialog(
        pdfFieldName: pdfFieldName,
        template: _currentTemplate!,
        products: _appState.products,
        customFields: _appState.customAppDataFields,
        onSelect: (field) {
          confirmMapping(field, pdfFieldInfo, false);
        },
      ),
    );
  }

  /// Confirm field mapping with optional replacement dialog
  void confirmMapping(
      String appDataType, Map<String, dynamic> pdfFieldInfo, bool isReplacing) {
    final pdfFieldName = pdfFieldInfo['name'] as String;

    if (isReplacing) {
      // Show confirmation dialog for replacing existing mapping
      showDialog(
        context: _context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Replace Existing Mapping?'),
            content: Text(
              'This will unlink "$appDataType" from its current PDF field and link it to "$pdfFieldName" instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  performMapping(appDataType, pdfFieldInfo);
                },
                child: const Text('Replace'),
              ),
            ],
          );
        },
      );
    } else {
      performMapping(appDataType, pdfFieldInfo);
    }
  }

  /// Perform the actual field mapping
  void performMapping(String appDataType, Map<String, dynamic> pdfFieldInfo) {
    if (_currentTemplate == null) return;

    PdfFieldMappingService.instance
        .performMapping(_currentTemplate!, appDataType, pdfFieldInfo);

    _currentTemplate!.updatedAt = DateTime.now();
    notifyListeners();

    if (_context.mounted) {
      _messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Linked "${PDFTemplate.getFieldDisplayName(appDataType)}" to "${pdfFieldInfo['name']}"',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Unlink a field mapping
  void unlinkField(FieldMapping mapping) {
    if (!_context.mounted || _currentTemplate == null) return;

    PdfFieldMappingService.instance.unlinkField(_currentTemplate!, mapping);
    notifyListeners();

    _messenger.showSnackBar(
      const SnackBar(
        content: Text('Field mapping removed.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

}