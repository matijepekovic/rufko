import 'package:flutter/material.dart';

/// Widget for displaying the list of categories in the CategoryManagerDialog
class CategoryListWidget extends StatelessWidget {
  final List<String> categories;
  final Function(int, String) onEdit;
  final Function(int) onRemove;

  const CategoryListWidget({
    super.key,
    required this.categories,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                'Current Categories (${categories.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (categories.length > 1)
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
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
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
                          onPressed: () => onEdit(index, category),
                          tooltip: 'Edit category',
                        ),
                        // Delete button (only show if more than 1 category)
                        if (categories.length > 1)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                            onPressed: () => onRemove(index),
                            tooltip: 'Delete category',
                          ),
                      ],
                    ),
                    onTap: () => onEdit(index, category),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}