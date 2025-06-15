import 'package:flutter/material.dart';
import '../../controllers/field_dialog_controller.dart';

/// Reusable advanced options section for field dialog
/// Extracted from FieldDialog for better maintainability
class FieldAdvancedOptions extends StatelessWidget {
  final FieldDialogController controller;

  const FieldAdvancedOptions({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Advanced Options',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          children: [
            const SizedBox(height: 8),
            _buildValueInput(),
            const SizedBox(height: 12),
            _buildRequiredCheckbox(),
          ],
        );
      },
    );
  }

  /// Build value input (checkbox or text field based on field type)
  Widget _buildValueInput() {
    if (controller.selectedFieldType == 'checkbox') {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CheckboxListTile(
          title: Text(
            controller.mode == FieldDialogMode.add
                ? 'Default State'
                : 'Current State',
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            controller.mode == FieldDialogMode.add
                ? 'Initial checkbox value'
                : 'Current checkbox value',
            style: const TextStyle(fontSize: 12),
          ),
          value: controller.checkboxValue,
          onChanged: (bool? value) {
            controller.checkboxValue = value ?? false;
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    } else {
      return TextFormField(
        controller: controller.valueTextController,
        decoration: InputDecoration(
          labelText: controller.mode == FieldDialogMode.add
              ? 'Default Value'
              : 'Current Value',
          hintText: controller.mode == FieldDialogMode.add
              ? 'Enter default value'
              : 'Enter current value',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: const OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 14),
        maxLines: controller.selectedFieldType == 'multiline' ? 2 : 1,
        keyboardType: _getKeyboardType(),
        validator: controller.validateValue,
      );
    }
  }

  /// Build required field checkbox
  Widget _buildRequiredCheckbox() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CheckboxListTile(
        title: const Text('Required Field', style: TextStyle(fontSize: 14)),
        subtitle: const Text('Must be filled for PDFs', style: TextStyle(fontSize: 12)),
        value: controller.isRequired,
        onChanged: (bool? value) {
          controller.isRequired = value ?? false;
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  /// Get appropriate keyboard type based on field type
  TextInputType _getKeyboardType() {
    switch (controller.selectedFieldType) {
      case 'number':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }
}