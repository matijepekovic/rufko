import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state_provider.dart';
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
    final TextEditingController controller = TextEditingController();

    final newCategoryKey = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  decoration: const BoxDecoration(
                    color: RufkoTheme.primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create PDF Category',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter a name for your new PDF template category:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g., Contracts, Inspections',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final categoryName = controller.text.trim();
                          if (categoryName.isNotEmpty) {
                            try {
                              final appState = context.read<AppStateProvider>();
                              final categoryKey = categoryName.toLowerCase().replaceAll(' ', '_');

                              await appState.addTemplateCategory('pdf_templates', categoryKey, categoryName);

                              if (mounted) {
                                Navigator.of(context).pop(categoryKey);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Created category: $categoryName'),
                                    backgroundColor: RufkoTheme.primaryColor,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating category: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RufkoTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newCategoryKey != null && mounted) {
      final appState = context.read<AppStateProvider>();
      categories = {
        for (final c in appState.templateCategories
            .where((cat) => cat.templateType == 'pdf_templates'))
          c.key: c.name,
      };
      setState(() {
        selectedCategory = newCategoryKey;
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
