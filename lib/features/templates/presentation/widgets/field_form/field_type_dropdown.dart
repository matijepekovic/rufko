import 'package:flutter/material.dart';
import '../../../../../core/mixins/field_type_mixin.dart';
import '../../controllers/field_dialog_controller.dart';

/// Reusable field type dropdown widget
/// Extracted from FieldDialog for better maintainability
class FieldTypeDropdown extends StatelessWidget with FieldTypeMixin {
  final FieldDialogController controller;

  const FieldTypeDropdown({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return DropdownButtonFormField<String>(
          value: controller.selectedFieldType,
          decoration: const InputDecoration(
            labelText: 'Type',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: fieldTypes.map((String fieldType) {
            return DropdownMenuItem<String>(
              value: fieldType,
              child: Text(
                fieldTypeNames[fieldType] ?? fieldType,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.selectedFieldType = newValue;
            }
          },
          validator: controller.validateFieldType,
        );
      },
    );
  }
}