import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state_provider.dart';
import 'category_creation_dialog.dart';
import '../../../theme/rufko_theme.dart';

class CategorySelectionDialog extends StatefulWidget {
  const CategorySelectionDialog({super.key});

  @override
  State<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  String? selectedCategory;
  late Map<String, String> categories;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    categories = {
      for (final c in appState.templateCategories
          .where((cat) => cat.templateType == 'pdf_templates'))
        c.key: c.name,
    };
    if (categories.isNotEmpty) selectedCategory = categories.keys.first;
  }

  Future<void> _showCreateCategoryDialog() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => const CategoryCreationDialog(),
    );

    if (newName != null && newName.trim().isNotEmpty && mounted) {
      final appState = context.read<AppStateProvider>();
      final categoryName = newName.trim();
      final categoryKey = categoryName.toLowerCase().replaceAll(' ', '_');
      try {
        await appState.addTemplateCategory(
            'pdf_templates', categoryKey, categoryName);
        categories[categoryKey] = categoryName;
        setState(() {
          selectedCategory = categoryKey;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created category: $categoryName'),
            backgroundColor: RufkoTheme.primaryColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
              children: [
                for (final entry in categories.entries)
                  RadioListTile<String>(
                    value: entry.key,
                    groupValue: selectedCategory,
                    title: Text(entry.value),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                  ),
                ListTile(
                  leading: Icon(Icons.add, color: RufkoTheme.primaryColor),
                  title: Text(
                    'Create New Category',
                    style: TextStyle(
                      fontSize: 14,
                      color: RufkoTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: _showCreateCategoryDialog,
                ),
              ],
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
