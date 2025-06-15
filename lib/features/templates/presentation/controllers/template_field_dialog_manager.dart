import 'package:flutter/material.dart';

import '../../../quotes/presentation/controllers/pdf_editing_controller.dart';
import '../../../../core/services/pdf/pdf_field_mapping_service.dart';

class TemplateFieldDialogManager {
  TemplateFieldDialogManager(this.context, this.editingController);

  final BuildContext context;
  final PdfEditingController editingController;

  String _displayName(String fieldName) {
    return PdfFieldMappingService.instance.getFieldDisplayName(fieldName);
  }

  void showEditDialog(String fieldName, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit \${_displayName(fieldName)}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _displayName(fieldName),
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
              final oldValue = editingController.editedValues[fieldName] ?? currentValue;
              if (newValue != oldValue) {
                editingController.addEdit(fieldName, oldValue, newValue);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
