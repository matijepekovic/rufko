import 'package:flutter/material.dart';
import '../../../theme/rufko_theme.dart';

class CategoryCreationDialog extends StatefulWidget {
  const CategoryCreationDialog({super.key});

  @override
  State<CategoryCreationDialog> createState() => _CategoryCreationDialogState();
}

class _CategoryCreationDialogState extends State<CategoryCreationDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: controller.text.isNotEmpty
                      ? () => Navigator.of(context).pop(controller.text)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RufkoTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
