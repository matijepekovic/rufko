import 'package:flutter/material.dart';
import '../../features/templates/presentation/screens/template_editor_screen.dart';
import '../../features/templates/presentation/screens/category_management_screen.dart';

class TemplateNavigationHandler {
  void openPdfTemplateEditor(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(preselectedCategory: category),
      ),
    );
  }

  void openCategoryManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CategoryManagementScreen(),
      ),
    );
  }
}
