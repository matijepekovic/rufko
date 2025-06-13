import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import 'category_data_controller.dart';


class CategoryOperationsController {
  CategoryOperationsController(this.context, this.dataController);

  final BuildContext context;
  final CategoryDataController dataController;

  Future<void> addCategory(String templateType, String categoryName) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppStateProvider>();
      final categoryKey = categoryName
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final templateTypeKey = dataController.getTemplateTypeKey(templateType);

      await appState.addTemplateCategory(
          templateTypeKey, categoryKey, categoryName);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Added "$categoryName" to $templateType successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> editCategory(
      String templateType, String categoryKey, String newName) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppStateProvider>();

      final templateTypeKey = dataController.getTemplateTypeKey(templateType);
      await appState.updateTemplateCategory(
          templateTypeKey, categoryKey, newName);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Updated category to "$newName" successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteCategory(
      String templateType, String categoryKey, String categoryName) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppStateProvider>();

      final templateTypeKey = dataController.getTemplateTypeKey(templateType);
      await appState.deleteTemplateCategory(templateTypeKey, categoryKey);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Deleted "$categoryName" successfully!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
