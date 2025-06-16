import 'package:flutter/material.dart';

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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}