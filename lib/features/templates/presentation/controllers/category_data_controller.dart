import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';

class CategoryDataController {
  CategoryDataController(this.context);

  final BuildContext context;

  AppStateProvider get _appState => context.read<AppStateProvider>();

  String getTemplateTypeKey(String templateType) {
    switch (templateType) {
      case 'PDF':
        return 'pdf_templates';
      case 'Message Templates':
        return 'message_templates';
      case 'Email Templates':
        return 'email_templates';
      case 'Fields':
        return 'custom_fields';
      default:
        return templateType.toLowerCase().replaceAll(' ', '_');
    }
  }

  List<Map<String, dynamic>> getCachedCategories(String templateType) {
    try {
      final templateTypeKey = getTemplateTypeKey(templateType);
      final appState = _appState;

      List<Map<String, dynamic>> relevantCategories = [];

      if (templateType == 'Fields') {
        relevantCategories.add({
          'id': 'protected_inspection',
          'key': 'inspection',
          'name': 'Inspection Fields',
          'usageCount': calculateUsageCount(templateType, 'inspection'),
          'isProtected': true,
        });
      }

      final loadedCategories = appState.templateCategories
          .where((cat) => cat.templateType == templateTypeKey)
          .map((cat) {
            if (templateType == 'Fields' && cat.key == 'inspection') {
              return null;
            }
            int usageCount = calculateUsageCount(templateType, cat.key);
            return {
              'id': cat.id,
              'key': cat.key,
              'name': cat.name,
              'usageCount': usageCount,
              'isProtected': false,
            };
          })
          .where((cat) => cat != null)
          .cast<Map<String, dynamic>>()
          .toList();

      relevantCategories.addAll(loadedCategories);
      return relevantCategories;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting cached categories: $e');
      return [];
    }
  }

  int calculateUsageCount(String templateType, String categoryKey) {
    try {
      final appState = _appState;
      switch (templateType) {
        case 'PDF':
          return appState.pdfTemplates
              .where((t) => t.userCategoryKey == categoryKey)
              .length;
        case 'Message Templates':
          return appState.messageTemplates
              .where((t) => t.userCategoryKey == categoryKey)
              .length;
        case 'Email Templates':
          return appState.emailTemplates
              .where((t) => t.userCategoryKey == categoryKey)
              .length;
        case 'Fields':
          return appState.customAppDataFields
              .where((f) => f.category == categoryKey)
              .length;
        default:
          return 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error calculating usage count: $e');
      return 0;
    }
  }
}
