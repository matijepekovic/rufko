import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../app/theme/rufko_theme.dart';
import 'category_creation_dialog.dart';

class CategorySelectionDialog extends StatefulWidget {
  const CategorySelectionDialog({super.key});

  @override
  State<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  String? selectedCategory;
  late final Map<String, String> categories;

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

  Future<void> _addCategory() async {
    final newName = await showCategoryCreationDialog(
      context: context,
      title: 'Create Template Category',
      description: 'Enter a name for your new template category:',
      hintText: 'e.g., Quotes, Invoices, Reports',
      onCategoryCreated: (name) async {
        final appState = context.read<AppStateProvider>();
        final key = name.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
        await appState.addTemplateCategory('pdf_templates', key, name);
        return name;
      },
    );
    if (newName != null && newName.trim().isNotEmpty && mounted) {
      final key = newName.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      setState(() {
        categories[key] = newName.trim();
        selectedCategory = key;
      });
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
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('New Category'),
              ),
              const Spacer(),
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
