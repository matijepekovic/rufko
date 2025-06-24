import 'package:flutter/material.dart';
import '../../../../../shared/widgets/buttons/rufko_dialog_actions.dart';

/// Dialog for confirming category deletion
class CategoryDeleteDialog extends StatelessWidget {
  final String categoryName;
  final VoidCallback onConfirm;

  const CategoryDeleteDialog({
    super.key,
    required this.categoryName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          const Text('Delete Category'),
        ],
      ),
      content: Text(
        'Are you sure you want to delete "$categoryName"?\n\nProducts in this category will need to be reassigned.',
      ),
      actions: [
        RufkoDialogActions(
          onCancel: () => Navigator.pop(context),
          onConfirm: () {
            Navigator.pop(context);
            onConfirm();
          },
          confirmText: 'Delete',
          isDangerousAction: true,
        ),
      ],
    );
  }
}