import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/templates/email_template.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../dialogs/email_template_editor.dart';
import '../../../../../core/mixins/template_tab_mixin.dart';

class EmailTemplatesTab extends StatefulWidget {
  const EmailTemplatesTab({super.key});

  @override
  State<EmailTemplatesTab> createState() => _EmailTemplatesTabState();
}

class _EmailTemplatesTabState extends State<EmailTemplatesTab> with TemplateTabMixin {

  // Implement required mixin properties
  @override
  Color get primaryColor => Colors.orange;

  @override
  String get itemTypeName => 'template';

  @override
  String get itemTypePlural => 'templates';

  @override
  IconData get tabIcon => Icons.email;

  @override
  String get searchHintText => 'Search email templates...';

  @override
  String get categoryType => 'email_templates';



  // Implement required data methods
  @override
  List<dynamic> getAllItems() {
    return context.read<AppStateProvider>().emailTemplates;
  }

  @override
  List<dynamic> getFilteredItems() {
    var filtered = getAllItems().cast<EmailTemplate>();

    // Always exclude templates without valid categories
    filtered = filtered.where((t) =>
    t.userCategoryKey != null &&
        t.userCategoryKey!.isNotEmpty
    ).toList();

    // Then filter by selected category if not 'all'
    if (selectedCategory != 'all') {
      filtered = filtered.where((t) => t.userCategoryKey == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
      t.templateName.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.subject.toLowerCase().contains(q) ||
          t.emailContent.toLowerCase().contains(q)).toList();
    }

    // Sort by sortOrder if available, otherwise by name
    return filtered..sort((a, b) {
      try {
        return a.sortOrder.compareTo(b.sortOrder);
      } catch (e) {
        return a.templateName.compareTo(b.templateName);
      }
    });
  }

  @override
  Future<void> deleteItemById(String id) async {
    await context.read<AppStateProvider>().deleteEmailTemplate(id);
  }

  @override
  String getItemId(dynamic item) {
    return (item as EmailTemplate).id;
  }

  @override
  String getItemDisplayName(dynamic item) {
    return (item as EmailTemplate).templateName;
  }

  // Implement required UI/navigation methods
  @override
  void navigateToEditor([dynamic existingItem]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailTemplateEditorScreen(
          existingTemplate: existingItem as EmailTemplate?,
        ),
      ),
    );
  }

  @override
  Widget buildItemTile(dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall) {
    final template = item as EmailTemplate;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return InkWell(
      onTap: isSelectionMode
          ? () => toggleSelection(getItemId(template))
          : () => navigateToEditor(template),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmall ? 8 : 12,
          vertical: isVerySmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
          border: isSelected
              ? Border.all(color: primaryColor, width: 1)
              : const Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: Row(
          children: [
            // Active status indicator
            Container(
              width: isVerySmall ? 24 : 28,
              height: isVerySmall ? 24 : 28,
              decoration: BoxDecoration(
                color: template.isActive ? primaryColor : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                tabIcon,
                color: Colors.white,
                size: isVerySmall ? 12 : 14,
              ),
            ),

            SizedBox(width: isVerySmall ? 8 : 12),

            // Template info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.templateName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isVerySmall ? 13 : 14,
                      color: isSelected ? primaryColor : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: isVerySmall ? 2 : 3),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.description.isNotEmpty
                              ? template.description
                              : 'No description',
                          style: TextStyle(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.7)
                                : Colors.grey[600],
                            fontSize: isVerySmall ? 10 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Text(
                        dateFormat.format(template.updatedAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: isVerySmall ? 9 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  if (template.subject.isNotEmpty || template.emailContent.isNotEmpty) ...[
                    SizedBox(height: isVerySmall ? 2 : 3),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isVerySmall ? 4 : 6,
                          vertical: isVerySmall ? 1 : 2
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        template.subject.isNotEmpty
                            ? 'Subject: ${template.subject.length > 30 ? '${template.subject.substring(0, 30)}...' : template.subject}'
                            : template.emailContent.length > 50
                            ? '${template.emailContent.substring(0, 50)}...'
                            : template.emailContent,
                        style: TextStyle(
                            fontSize: isVerySmall ? 9 : 10,
                            fontWeight: FontWeight.w500
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  // HTML indicator
                  if (template.isHtml) ...[
                    SizedBox(height: isVerySmall ? 2 : 3),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isVerySmall ? 3 : 4,
                          vertical: isVerySmall ? 1 : 1
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HTML',
                        style: TextStyle(
                            fontSize: isVerySmall ? 8 : 9,
                            fontWeight: FontWeight.bold,
                            color: primaryColor
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator or menu
            if (isSelectionMode)
              Container(
                width: isVerySmall ? 20 : 24,
                height: isVerySmall ? 20 : 24,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: isVerySmall ? 12 : 14)
                    : null,
              )
            else
              PopupMenuButton<String>(
                onSelected: (action) => _handleTemplateAction(action, template),
                icon: Icon(
                  Icons.more_vert,
                  size: isVerySmall ? 16 : 18,
                  color: Colors.grey[600],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test_send',
                    child: Row(
                      children: [
                        Icon(Icons.send, size: 16),
                        SizedBox(width: 8),
                        Text('Test Send'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_active',
                    child: Row(
                      children: [
                        Icon(
                          template.isActive ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(template.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return buildMainLayout(); // This comes from the mixin!
      },
    );
  }

  // Template-specific action handler
  void _handleTemplateAction(String action, EmailTemplate template) {
    switch (action) {
      case 'edit':
        navigateToEditor(template);
        break;
      case 'test_send':
        _sendTestEmail(template);
        break;
      case 'toggle_active':
        context.read<AppStateProvider>().toggleEmailTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
          ),
        );
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  void _sendTestEmail(EmailTemplate template) {
    // Placeholder for test email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test email functionality coming soon for "${template.templateName}"'),
        backgroundColor: primaryColor,
      ),
    );
  }

  void _duplicateTemplate(EmailTemplate template) async {
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

      await context.read<AppStateProvider>().addEmailTemplate(newTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template duplicated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteTemplate(EmailTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
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
    
    if (confirmed == true && mounted) {
      try {
        await deleteItemById(template.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted: ${template.templateName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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