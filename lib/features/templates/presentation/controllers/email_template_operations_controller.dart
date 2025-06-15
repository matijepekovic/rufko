import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/templates/email_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for email template operations (test send, duplicate, delete, toggle active)
/// Extracted from EmailTemplatesTab for better separation of concerns
class EmailTemplateOperationsController extends ChangeNotifier {
  final BuildContext _context;
  
  EmailTemplateOperationsController(this._context);

  AppStateProvider get _appState => _context.read<AppStateProvider>();
  ScaffoldMessengerState get _messenger => ScaffoldMessenger.of(_context);

  /// Handle template menu actions
  void handleTemplateAction(String action, EmailTemplate template, {
    required VoidCallback onEdit,
  }) {
    switch (action) {
      case 'edit':
        onEdit();
        break;
      case 'test_send':
        sendTestEmail(template);
        break;
      case 'toggle_active':
        toggleTemplateActive(template);
        break;
      case 'duplicate':
        duplicateTemplate(template);
        break;
      case 'delete':
        deleteTemplate(template);
        break;
    }
  }

  /// Send test email (placeholder functionality)
  void sendTestEmail(EmailTemplate template) {
    _messenger.showSnackBar(
      SnackBar(
        content: Text('Test email functionality coming soon for "${template.templateName}"'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Toggle template active status
  void toggleTemplateActive(EmailTemplate template) {
    _appState.toggleEmailTemplateActive(template.id);
    _messenger.showSnackBar(
      SnackBar(
        content: Text(
          template.isActive ? 'Template deactivated' : 'Template activated',
        ),
      ),
    );
  }

  /// Duplicate an existing template
  Future<void> duplicateTemplate(EmailTemplate template) async {
    try {
      final duplicatedTemplate = template.copyWith(
        templateName: '${template.templateName} (Copy)',
        updatedAt: DateTime.now(),
      );

      final newTemplate = EmailTemplate(
        templateName: duplicatedTemplate.templateName,
        description: duplicatedTemplate.description,
        category: duplicatedTemplate.category,
        subject: duplicatedTemplate.subject,
        emailContent: duplicatedTemplate.emailContent,
        placeholders: List.from(duplicatedTemplate.placeholders),
        isActive: duplicatedTemplate.isActive,
        isHtml: duplicatedTemplate.isHtml,
        sortOrder: duplicatedTemplate.sortOrder,
      );

      await _appState.addEmailTemplate(newTemplate);

      if (_context.mounted) {
        _messenger.showSnackBar(
          const SnackBar(
            content: Text('Template duplicated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (_context.mounted) {
        _messenger.showSnackBar(
          SnackBar(
            content: Text('Error duplicating template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete template with confirmation dialog
  Future<void> deleteTemplate(EmailTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${template.templateName}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template: ${template.templateName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (template.description.isNotEmpty)
                    Text('Description: ${template.description}'),
                  if (template.subject.isNotEmpty)
                    Text('Subject: ${template.subject}'),
                  Text('Category: ${template.userCategoryKey ?? 'Unknown'}'),
                  if (template.isHtml)
                    const Text('Type: HTML Email'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _context.mounted) {
      try {
        await _appState.deleteEmailTemplate(template.id);
        if (_context.mounted) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Deleted: ${template.templateName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (_context.mounted) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Error deleting template: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}