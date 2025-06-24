import 'package:flutter/material.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

/// Widget for adding new categories in the CategoryManagerDialog
class AddCategoryWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const AddCategoryWidget({
    super.key,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'New Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.add, color: Colors.blue.shade600),
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 12),
          RufkoIconButton(
            onPressed: onAdd,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }
}