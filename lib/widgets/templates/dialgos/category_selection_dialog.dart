import 'package:flutter/material.dart';
import '../../../theme/rufko_theme.dart';

class CategorySelectionDialog extends StatefulWidget {
  const CategorySelectionDialog({super.key});

  @override
  State<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  String? selectedCategory;
  final List<String> categories = const ['general'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: RufkoTheme.primaryColor,
            child: Row(
              children: const [
                Icon(Icons.folder, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Category',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: categories.map((c) {
                return RadioListTile<String>(
                  value: c,
                  groupValue: selectedCategory,
                  title: Text(c),
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedCategory != null
                    ? () => Navigator.of(context).pop(selectedCategory)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RufkoTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Select'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
