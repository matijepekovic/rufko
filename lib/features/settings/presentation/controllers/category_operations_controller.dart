import 'package:flutter/material.dart';

/// Controller for managing category operations in the CategoryManagerDialog
class CategoryOperationsController extends ChangeNotifier {
  CategoryOperationsController({required List<String> initialCategories})
      : _categories = List.from(initialCategories);

  final TextEditingController addController = TextEditingController();
  final List<String> _categories;

  List<String> get categories => _categories;

  void addCategory(BuildContext context) {
    final newCategory = addController.text.trim();
    if (newCategory.isNotEmpty && !_categories.contains(newCategory)) {
      _categories.add(newCategory);
      addController.clear();
      notifyListeners();
    } else if (_categories.contains(newCategory)) {
      _showSnackBar(
        context,
        'Category already exists',
        Colors.orange,
      );
    }
  }

  void removeCategory(int index, BuildContext context) {
    if (_categories.length > 1) {
      _categories.removeAt(index);
      notifyListeners();
    }
  }

  void updateCategory(int index, String newName, BuildContext context) {
    if (newName == _categories[index]) {
      return; // No change
    }

    if (_categories.contains(newName)) {
      _showSnackBar(
        context,
        'Category name already exists',
        Colors.orange,
      );
      return;
    }

    _categories[index] = newName;
    notifyListeners();

    _showSnackBar(
      context,
      'Category updated to "$newName"',
      Colors.green,
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    addController.dispose();
    super.dispose();
  }
}