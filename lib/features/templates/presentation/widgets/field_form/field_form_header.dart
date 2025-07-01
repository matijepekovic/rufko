import 'package:flutter/material.dart';
import '../../controllers/field_dialog_controller.dart';

/// Reusable header widget for field dialog
/// Extracted from FieldDialog for better maintainability
class FieldFormHeader extends StatelessWidget {
  final FieldDialogMode mode;
  final String? existingFieldName;
  final VoidCallback onClose;

  const FieldFormHeader({
    super.key,
    required this.mode,
    this.existingFieldName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3), // RufkoTheme.primaryColor
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Icon(
            mode == FieldDialogMode.add ? Icons.add_circle : Icons.edit,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mode == FieldDialogMode.add
                  ? 'Add Field'
                  : 'Edit: ${existingFieldName ?? 'Field'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}