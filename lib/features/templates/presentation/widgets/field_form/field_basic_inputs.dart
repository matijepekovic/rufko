import 'package:flutter/material.dart';
import '../../controllers/field_dialog_controller.dart';

/// Reusable basic input fields (field name, display name)
/// Extracted from FieldDialog for better maintainability
class FieldBasicInputs extends StatelessWidget {
  final FieldDialogController controller;

  const FieldBasicInputs({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Field Name Input
        TextFormField(
          controller: controller.fieldNameController,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            hintText: 'no_spaces_allowed',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: controller.mode == FieldDialogMode.add
              ? controller.onFieldNameChanged
              : null,
          validator: controller.validateFieldName,
        ),
        const SizedBox(height: 12),
        
        // Display Name Input
        TextFormField(
          controller: controller.displayNameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'User Friendly Name',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 14),
          validator: controller.validateDisplayName,
        ),
      ],
    );
  }
}