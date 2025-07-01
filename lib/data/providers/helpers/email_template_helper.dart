import 'package:flutter/foundation.dart';

import '../../models/templates/email_template.dart';
import '../../../core/services/database/database_service.dart';

class EmailTemplateHelper {
  static Future<void> addEmailTemplate({
    required DatabaseService db,
    required List<EmailTemplate> templates,
    required EmailTemplate template,
  }) async {
    await db.saveEmailTemplate(template);
    templates.add(template);
    if (kDebugMode) {
      debugPrint('➕ Added email template: ${template.templateName}');
    }
  }

  static Future<void> updateEmailTemplate({
    required DatabaseService db,
    required List<EmailTemplate> templates,
    required EmailTemplate template,
  }) async {
    await db.saveEmailTemplate(template);
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      templates[index] = template;
      if (kDebugMode) {
        debugPrint('✅ Updated email template in memory');
      }
    } else {
      templates.add(template);
      if (kDebugMode) {
        debugPrint('⚠️ Email template not found in memory, adding it');
      }
    }
  }

  static Future<void> deleteEmailTemplate({
    required DatabaseService db,
    required List<EmailTemplate> templates,
    required String templateId,
  }) async {
    await db.deleteEmailTemplate(templateId);
    templates.removeWhere((t) => t.id == templateId);
    if (kDebugMode) {
      debugPrint('🗑️ Deleted email template: $templateId');
    }
  }

  static Future<void> toggleEmailTemplateActive({
    required DatabaseService db,
    required List<EmailTemplate> templates,
    required String templateId,
  }) async {
    final index = templates.indexWhere((t) => t.id == templateId);
    if (index != -1) {
      final template = templates[index];
      final updated = template.copyWith(
        isActive: !template.isActive,
        updatedAt: DateTime.now(),
      );
      await db.saveEmailTemplate(updated);
      templates[index] = updated;
      if (kDebugMode) {
        debugPrint('🔄 Toggled email template active: ${updated.isActive}');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ Email template not found for toggle: $templateId');
      }
    }
  }

  static List<EmailTemplate> getByCategory(
      List<EmailTemplate> templates, String category) {
    return templates.where((t) => t.category == category).toList();
  }

  static List<EmailTemplate> search(
      List<EmailTemplate> templates, String query) {
    if (query.isEmpty) return templates;
    final lower = query.toLowerCase();
    return templates
        .where((template) =>
            template.templateName.toLowerCase().contains(lower) ||
            template.description.toLowerCase().contains(lower) ||
            template.category.toLowerCase().contains(lower) ||
            template.subject.toLowerCase().contains(lower) ||
            template.emailContent.toLowerCase().contains(lower))
        .toList();
  }
}
