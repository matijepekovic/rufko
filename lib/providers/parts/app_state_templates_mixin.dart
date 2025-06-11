part of '../app_state_provider.dart';

extension AppStateTemplatesExtension on AppStateProvider {
  Future<void> addMessageTemplate(MessageTemplate template) async {
    try {
      await _db.saveMessageTemplate(template);
      _messageTemplates.add(template);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('➕ Added message template: ${template.templateName}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding message template: $e');
      }
      rethrow;
    }
  }

  Future<void> updateMessageTemplate(MessageTemplate template) async {
    try {
      debugPrint(
          '🔧 AppState: Updating message template: ${template.templateName}');
      await _db.saveMessageTemplate(template);

      final index = _messageTemplates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _messageTemplates[index] = template;
        debugPrint('✅ AppState: Updated message template in memory');
      } else {
        debugPrint(
            '⚠️ AppState: Message template not found in memory, adding it');
        _messageTemplates.add(template);
      }

      notifyListeners();
      debugPrint('✅ AppState: Message template updated and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error updating message template: $e');
      rethrow;
    }
  }

  Future<void> deleteMessageTemplate(String templateId) async {
    try {
      debugPrint('🗑️ AppState: Deleting message template: $templateId');
      await _db.deleteMessageTemplate(templateId);

      final removedCount = _messageTemplates.length;
      _messageTemplates.removeWhere((t) => t.id == templateId);
      final newCount = _messageTemplates.length;

      debugPrint(
          '✅ AppState: Removed message template ($removedCount -> $newCount)');
      notifyListeners();
      debugPrint('✅ AppState: Message template deleted and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error deleting message template: $e');
      rethrow;
    }
  }

  Future<void> toggleMessageTemplateActive(String templateId) async {
    try {
      debugPrint('🔄 AppState: Toggling message template active: $templateId');
      final index = _messageTemplates.indexWhere((t) => t.id == templateId);
      if (index != -1) {
        final template = _messageTemplates[index];
        final updatedTemplate = template.copyWith(
          isActive: !template.isActive,
          updatedAt: DateTime.now(),
        );

        await _db.saveMessageTemplate(updatedTemplate);
        _messageTemplates[index] = updatedTemplate;
        notifyListeners();
        debugPrint(
            '✅ AppState: Message template toggled and notified: ${updatedTemplate.isActive}');
      } else {
        debugPrint(
            '❌ AppState: Message template not found for toggle: $templateId');
      }
    } catch (e) {
      debugPrint('❌ AppState: Error toggling message template: $e');
      rethrow;
    }
  }

  List<MessageTemplate> getMessageTemplatesByCategory(String category) {
    return _messageTemplates.where((t) => t.category == category).toList();
  }

  List<MessageTemplate> searchMessageTemplates(String query) {
    if (query.isEmpty) return _messageTemplates;
    final lowerQuery = query.toLowerCase();
    return _messageTemplates
        .where((template) =>
            template.templateName.toLowerCase().contains(lowerQuery) ||
            template.description.toLowerCase().contains(lowerQuery) ||
            template.category.toLowerCase().contains(lowerQuery) ||
            template.messageContent.toLowerCase().contains(lowerQuery))
        .toList();
  }

// --- Email Template Operations ---
  Future<void> addEmailTemplate(EmailTemplate template) async {
    try {
      debugPrint(
          '🆕 AppState: Adding email template: ${template.templateName}');
      await _db.saveEmailTemplate(template);
      _emailTemplates.add(template);
      notifyListeners();
      debugPrint('✅ AppState: Email template added and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error adding email template: $e');
      rethrow;
    }
  }

  Future<void> updateEmailTemplate(EmailTemplate template) async {
    try {
      debugPrint(
          '🔧 AppState: Updating email template: ${template.templateName}');
      await _db.saveEmailTemplate(template);

      final index = _emailTemplates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _emailTemplates[index] = template;
        debugPrint('✅ AppState: Updated email template in memory');
      } else {
        debugPrint(
            '⚠️ AppState: Email template not found in memory, adding it');
        _emailTemplates.add(template);
      }

      notifyListeners();
      debugPrint('✅ AppState: Email template updated and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error updating email template: $e');
      rethrow;
    }
  }

  Future<void> deleteEmailTemplate(String templateId) async {
    try {
      debugPrint('🗑️ AppState: Deleting email template: $templateId');
      await _db.deleteEmailTemplate(templateId);

      final removedCount = _emailTemplates.length;
      _emailTemplates.removeWhere((t) => t.id == templateId);
      final newCount = _emailTemplates.length;

      debugPrint(
          '✅ AppState: Removed email template ($removedCount -> $newCount)');
      notifyListeners();
      debugPrint('✅ AppState: Email template deleted and notified');
    } catch (e) {
      debugPrint('❌ AppState: Error deleting email template: $e');
      rethrow;
    }
  }

  Future<void> toggleEmailTemplateActive(String templateId) async {
    try {
      debugPrint('🔄 AppState: Toggling email template active: $templateId');
      final index = _emailTemplates.indexWhere((t) => t.id == templateId);
      if (index != -1) {
        final template = _emailTemplates[index];
        final updatedTemplate = template.copyWith(
          isActive: !template.isActive,
          updatedAt: DateTime.now(),
        );

        await _db.saveEmailTemplate(updatedTemplate);
        _emailTemplates[index] = updatedTemplate;
        notifyListeners();
        debugPrint(
            '✅ AppState: Email template toggled and notified: ${updatedTemplate.isActive}');
      } else {
        debugPrint(
            '❌ AppState: Email template not found for toggle: $templateId');
      }
    } catch (e) {
      debugPrint('❌ AppState: Error toggling email template: $e');
      rethrow;
    }
  }

  List<EmailTemplate> getEmailTemplatesByCategory(String category) {
    return _emailTemplates.where((t) => t.category == category).toList();
  }

  List<EmailTemplate> searchEmailTemplates(String query) {
    if (query.isEmpty) return _emailTemplates;
    final lowerQuery = query.toLowerCase();
    return _emailTemplates
        .where((template) =>
            template.templateName.toLowerCase().contains(lowerQuery) ||
            template.description.toLowerCase().contains(lowerQuery) ||
            template.category.toLowerCase().contains(lowerQuery) ||
            template.subject.toLowerCase().contains(lowerQuery) ||
            template.emailContent.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
