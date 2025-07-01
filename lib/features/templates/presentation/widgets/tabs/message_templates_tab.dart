import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/templates/message_template.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../dialogs/message_template_editor.dart';
import '../../../../../core/mixins/template_tab_mixin.dart';
import '../../../../../shared/widgets/buttons/rufko_dialog_actions.dart';

class MessageTemplatesTab extends StatefulWidget {
  const MessageTemplatesTab({super.key});

  @override
  State<MessageTemplatesTab> createState() => _MessageTemplatesTabState();
}

class _MessageTemplatesTabState extends State<MessageTemplatesTab> with TemplateTabMixin {

  // Implement required mixin properties
  @override
  Color get primaryColor => Colors.blue;

  @override
  String get itemTypeName => 'template';

  @override
  String get itemTypePlural => 'templates';

  @override
  IconData get tabIcon => Icons.sms;

  @override
  String get searchHintText => 'Search message templates...';

  @override
  String get categoryType => 'message_templates';



  // Implement required data methods
  @override
  List<dynamic> getAllItems() {
    return context.read<AppStateProvider>().messageTemplates;
  }

  @override
  List<dynamic> getFilteredItems() {
    var filtered = getAllItems().cast<MessageTemplate>();

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
          t.messageContent.toLowerCase().contains(q)).toList();
    }

    return filtered..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> deleteItemById(String id) async {
    await context.read<AppStateProvider>().deleteMessageTemplate(id);
  }

  @override
  String getItemId(dynamic item) {
    return (item as MessageTemplate).id;
  }

  @override
  String getItemDisplayName(dynamic item) {
    return (item as MessageTemplate).templateName;
  }

  // Implement required UI/navigation methods
  @override
  void navigateToEditor([dynamic existingItem]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageTemplateEditorScreen(
          existingTemplate: existingItem as MessageTemplate?,
        ),
      ),
    );
  }

  @override
  Widget buildItemTile(dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall) {
    final template = item as MessageTemplate;
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

                  if (template.messageContent.isNotEmpty) ...[
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
                        template.messageContent.length > 50
                            ? '${template.messageContent.substring(0, 50)}...'
                            : template.messageContent,
                        style: TextStyle(
                            fontSize: isVerySmall ? 9 : 10,
                            fontWeight: FontWeight.w500
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
  void _handleTemplateAction(String action, MessageTemplate template) {
    switch (action) {
      case 'edit':
        navigateToEditor(template);
        break;
      case 'toggle_active':
        context.read<AppStateProvider>().toggleMessageTemplateActive(template.id);
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

  void _duplicateTemplate(MessageTemplate template) async {
    // Implementation specific to message templates
    try {
      final duplicatedTemplate = template.copyWith(
        templateName: '${template.templateName} (Copy)',
        updatedAt: DateTime.now(),
      );

      final newTemplate = MessageTemplate(
        templateName: duplicatedTemplate.templateName,
        description: duplicatedTemplate.description,
        category: duplicatedTemplate.category,
        messageContent: duplicatedTemplate.messageContent,
        placeholders: List.from(duplicatedTemplate.placeholders),
        isActive: duplicatedTemplate.isActive,
        sortOrder: duplicatedTemplate.sortOrder,
      );

      await context.read<AppStateProvider>().addMessageTemplate(newTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template duplicated successfully'),
            backgroundColor: Colors.green,
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

  void _deleteTemplate(MessageTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
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
                  Text('Category: ${template.userCategoryKey ?? 'Unknown'}'),
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
          RufkoDialogActions(
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
            confirmText: 'Delete',
            isDangerousAction: true,
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
              backgroundColor: Colors.green,
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