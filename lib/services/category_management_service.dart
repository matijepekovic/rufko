import 'package:flutter/material.dart';
import '../widgets/templates/dialgos/category_selection_dialog.dart';
import '../widgets/templates/dialgos/category_creation_dialog.dart';

class CategoryManagementService {
  Future<String?> selectCategory(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (c) => const CategorySelectionDialog(),
    );
  }

  Future<String?> createCategory(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (c) => const CategoryCreationDialog(),
    );
  }
}
