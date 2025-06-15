import 'package:flutter/material.dart';
import '../../features/templates/presentation/widgets/dialogs/category_selection_dialog.dart';
import '../../features/templates/presentation/widgets/dialogs/category_creation_dialog.dart';

class CategoryManagementService {
  Future<String?> selectCategory(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (c) => const CategorySelectionDialog(),
    );
  }

  Future<String?> createCategory(BuildContext context) async {
    return showCategoryCreationDialog(
      context: context,
      title: 'Create Category',
      description: 'Enter a name for your new category:',
      hintText: 'e.g., General, Important',
      onCategoryCreated: (name) async {
        // This would be handled by the caller
      },
    );
  }
}
