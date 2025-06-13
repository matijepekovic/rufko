import 'package:flutter/foundation.dart';

import '../../models/templates/message_template.dart';
import '../../../core/services/database/database_service.dart';

class MessageTemplateHelper {
  static Future<void> addMessageTemplate({
    required DatabaseService db,
    required List<MessageTemplate> templates,
    required MessageTemplate template,
  }) async {
    await db.saveMessageTemplate(template);
    templates.add(template);
    if (kDebugMode) {
      debugPrint('➕ Added message template: ${template.templateName}');
    }
  }

  static Future<void> updateMessageTemplate({
    required DatabaseService db,
    required List<MessageTemplate> templates,
    required MessageTemplate template,
  }) async {
    await db.saveMessageTemplate(template);
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      templates[index] = template;
      if (kDebugMode) {
        debugPrint('✅ Updated message template in memory');
      }
    } else {
      templates.add(template);
      if (kDebugMode) {
        debugPrint('⚠️ Message template not found in memory, adding it');
      }
    }
  }

  static Future<void> deleteMessageTemplate({
    required DatabaseService db,
    required List<MessageTemplate> templates,
    required String templateId,
  }) async {
    await db.deleteMessageTemplate(templateId);
    templates.removeWhere((t) => t.id == templateId);
    if (kDebugMode) {
      debugPrint('🗑️ Deleted message template: $templateId');
    }
  }

  static Future<void> toggleMessageTemplateActive({
    required DatabaseService db,
    required List<MessageTemplate> templates,
    required String templateId,
  }) async {
    final index = templates.indexWhere((t) => t.id == templateId);
    if (index != -1) {
      final template = templates[index];
      final updated = template.copyWith(
        isActive: !template.isActive,
        updatedAt: DateTime.now(),
      );
      await db.saveMessageTemplate(updated);
      templates[index] = updated;
      if (kDebugMode) {
        debugPrint('🔄 Toggled message template active: ${updated.isActive}');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ Message template not found for toggle: $templateId');
      }
    }
  }

  static List<MessageTemplate> getByCategory(
      List<MessageTemplate> templates, String category) {
    return templates.where((t) => t.category == category).toList();
  }

  static List<MessageTemplate> search(
      List<MessageTemplate> templates, String query) {
    if (query.isEmpty) return templates;
    final lower = query.toLowerCase();
    return templates
        .where((template) =>
            template.templateName.toLowerCase().contains(lower) ||
            template.description.toLowerCase().contains(lower) ||
            template.category.toLowerCase().contains(lower) ||
            template.messageContent.toLowerCase().contains(lower))
        .toList();
  }
}
