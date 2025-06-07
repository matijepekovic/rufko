import 'package:flutter/material.dart';
class CategoryManagerDialog extends StatefulWidget {
  final List<String> categories;
  final Function(List<String>) onSave;

  const CategoryManagerDialog({super.key,
    required this.categories,
    required this.onSave,
  });

  @override
  State<CategoryManagerDialog> createState() => CategoryManagerDialogState();
}

class CategoryManagerDialogState extends State<CategoryManagerDialog> {
  late List<String> _categories;
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  @override
  void dispose() {
    _addController.dispose();
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
            child: Icon(Icons.category, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Manage Product Categories'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450, // Increased height to accommodate edit functionality
        child: Column(
          children: [
            // Add new category section
            Container(
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
                      controller: _addController,
                      decoration: InputDecoration(
                        labelText: 'New Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.add, color: Colors.blue.shade600),
                      ),
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addCategory,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Categories list header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Current Categories (${_categories.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  if (_categories.length > 1)
                    Text(
                      'Tap to edit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Categories list
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 20,
                          child: Icon(
                            Icons.category,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600),
                              onPressed: () => _editCategory(index, category),
                              tooltip: 'Edit category',
                            ),
                            // Delete button (only show if more than 1 category)
                            if (_categories.length > 1)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                                onPressed: () => _removeCategory(index),
                                tooltip: 'Delete category',
                              ),
                          ],
                        ),
                        onTap: () => _editCategory(index, category),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_categories);
            Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  void _addCategory() {
    final newCategory = _addController.text.trim();
    if (newCategory.isNotEmpty && !_categories.contains(newCategory)) {
      setState(() {
        _categories.add(newCategory);
        _addController.clear();
      });
    } else if (_categories.contains(newCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Category already exists'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _removeCategory(int index) {
    if (_categories.length > 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Text('Delete Category'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${_categories[index]}"?\n\nProducts in this category will need to be reassigned.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _categories.removeAt(index);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _editCategory(int index, String currentName) {
    final TextEditingController editController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              controller: editController,
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
                  _updateCategory(index, value.trim(), editController);
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
          TextButton(
            onPressed: () {
              editController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                _updateCategory(index, newName, editController);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateCategory(int index, String newName, TextEditingController controller) {
    if (newName == _categories[index]) {
      // No change
      controller.dispose();
      Navigator.pop(context);
      return;
    }

    if (_categories.contains(newName)) {
      // Category name already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Category name already exists'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _categories[index] = newName;
    });

    controller.dispose();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category updated to "$newName"'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

