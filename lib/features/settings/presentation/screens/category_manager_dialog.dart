import 'package:flutter/material.dart';
import '../controllers/category_operations_controller.dart';
import '../widgets/category_manager/add_category_widget.dart';
import '../widgets/category_manager/category_list_widget.dart';
import '../widgets/category_manager/category_edit_dialog.dart';
import '../widgets/category_manager/category_delete_dialog.dart';

class CategoryManagerDialog extends StatefulWidget {
  final List<String> categories;
  final Function(List<String>) onSave;

  const CategoryManagerDialog({
    super.key,
    required this.categories,
    required this.onSave,
  });

  @override
  State<CategoryManagerDialog> createState() => CategoryManagerDialogState();
}

class CategoryManagerDialogState extends State<CategoryManagerDialog> {
  late CategoryOperationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CategoryOperationsController(initialCategories: widget.categories);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: _buildHeader(),
          content: _buildContent(),
          actions: _buildActions(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
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
        const Text('Categories'),
      ],
    );
  }

  Widget _buildContent() {
    return SizedBox(
      width: double.maxFinite,
      height: 450,
      child: Column(
        children: [
          // Add new category section
          AddCategoryWidget(
            controller: _controller.addController,
            onAdd: () => _controller.addCategory(context),
          ),
          const SizedBox(height: 16),

          // Categories list
          Expanded(
            child: CategoryListWidget(
              categories: _controller.categories,
              onEdit: _editCategory,
              onRemove: _removeCategory,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          widget.onSave(_controller.categories);
          Navigator.pop(context);
        },
        child: const Text('Save Changes'),
      ),
    ];
  }

  void _editCategory(int index, String currentName) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        currentName: currentName,
        onUpdate: (newName) => _controller.updateCategory(index, newName, context),
      ),
    );
  }

  void _removeCategory(int index) {
    if (_controller.categories.length > 1) {
      showDialog(
        context: context,
        builder: (context) => CategoryDeleteDialog(
          categoryName: _controller.categories[index],
          onConfirm: () => _controller.removeCategory(index, context),
        ),
      );
    }
  }
}