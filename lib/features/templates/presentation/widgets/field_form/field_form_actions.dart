import 'package:flutter/material.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../controllers/field_dialog_controller.dart';

/// Reusable action buttons for field dialog
/// Extracted from FieldDialog for better maintainability
class FieldFormActions extends StatelessWidget {
  final FieldDialogController controller;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const FieldFormActions({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RufkoSecondaryButton(
            onPressed: controller.isLoading ? null : onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return RufkoPrimaryButton(
                onPressed: controller.isLoading ? null : onSave,
                child: controller.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(controller.mode == FieldDialogMode.add
                        ? 'Add Field'
                        : 'Save'),
              );
            },
          ),
        ],
      ),
    );
  }
}