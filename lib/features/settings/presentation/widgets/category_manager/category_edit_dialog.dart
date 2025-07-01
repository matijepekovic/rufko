import 'package:flutter/material.dart';
import '../../../../../shared/widgets/buttons/rufko_dialog_actions.dart';

/// Dialog for editing category names
class CategoryEditDialog extends StatefulWidget {
  final String currentName;
  final Function(String) onUpdate;

  const CategoryEditDialog({
    super.key,
    required this.currentName,
    required this.onUpdate,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Edit Category'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _editController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              prefixIcon: Icon(Icons.category, color: Colors.blue.shade600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _updateCategory();
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Existing products with this category will be updated automatically.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        RufkoDialogActions(
          onCancel: () => Navigator.pop(context),
          onConfirm: _updateCategory,
          confirmText: 'Update',
        ),
      ],
    );
  }

  void _updateCategory() {
    final newName = _editController.text.trim();
    if (newName.isNotEmpty) {
      widget.onUpdate(newName);
      Navigator.pop(context);
    }
  }
}