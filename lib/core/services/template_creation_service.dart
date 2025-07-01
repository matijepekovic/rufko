import 'package:flutter/material.dart';
import '../../shared/navigation/template_navigation_handler.dart';
import 'category_management_service.dart';

class TemplateCreationService {
  final TemplateNavigationHandler navigationHandler;
  final CategoryManagementService categoryService;

  TemplateCreationService({
    required this.navigationHandler,
    required this.categoryService,
  });

  Future<void> createNewPDFTemplate(BuildContext context) async {
    final category = await categoryService.selectCategory(context);
    if (category != null && context.mounted) {
      navigationHandler.openPdfTemplateEditor(context, category);
    }
  }
}
