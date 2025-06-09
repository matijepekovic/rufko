import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/pdf_template.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/template_editor_screen.dart';
import '../../screens/pdf_preview_screen.dart';
import '../../theme/rufko_theme.dart';
import '../../mixins/template_tab_mixin.dart';

class PdfTemplatesTab extends StatefulWidget {
  const PdfTemplatesTab({super.key});

  @override
  State<PdfTemplatesTab> createState() => _PdfTemplatesTabState();
}

class _PdfTemplatesTabState extends State<PdfTemplatesTab> with TemplateTabMixin {

  // Implement required mixin properties
  @override
  Color get primaryColor => RufkoTheme.primaryColor;

  @override
  String get itemTypeName => 'template';

  @override
  String get itemTypePlural => 'templates';

  @override
  IconData get tabIcon => Icons.description;

  @override
  String get searchHintText => 'Search PDF templates...';

  @override
  String get categoryType => 'pdf_templates';

  // Implement required data methods
  @override
  List<dynamic> getAllItems() {
    return context.read<AppStateProvider>().pdfTemplates;
  }

  @override
  List<dynamic> getFilteredItems() {
    var filtered = getAllItems().cast<PDFTemplate>();

    if (selectedCategory != 'all') {
      filtered = filtered.where((t) => t.userCategoryKey == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
      t.templateName.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.templateType.toLowerCase().contains(q)).toList();
    }

    return filtered..sort((a, b) => a.templateName.compareTo(b.templateName));
  }

  @override
  Future<void> deleteItemById(String id) async {
    await context.read<AppStateProvider>().deletePDFTemplate(id);
  }

  @override
  String getItemId(dynamic item) {
    return (item as PDFTemplate).id;
  }

  @override
  String getItemDisplayName(dynamic item) {
    return (item as PDFTemplate).templateName;
  }

  // Implement required UI/navigation methods
  @override
  void navigateToEditor([dynamic existingItem]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorScreen(
          existingTemplate: existingItem as PDFTemplate?,
          // Don't pass preselectedCategory for existing templates
          // New templates are handled by templates_screen.dart
        ),
      ),
    );
  }

  @override
  Widget buildItemTile(dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall) {
    final template = item as PDFTemplate;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return InkWell(
      onTap: isSelectionMode
          ? () => toggleSelection(getItemId(template))
          : () => navigateToEditor(template),
      onLongPress: !isSelectionMode ? () => _previewTemplate(template) : null,
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
                color: template.isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                template.isActive ? Icons.check : Icons.close,
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

                  // Show category instead of template type
                  if (template.userCategoryKey != null && template.userCategoryKey!.isNotEmpty) ...[
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
                        'Category: ${template.userCategoryKey}',
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
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.preview, size: 16),
                        SizedBox(width: 8),
                        Text('Preview'),
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
        // Note: No floating action button here - it's handled by templates_screen.dart
      },
    );
  }

  // Template-specific action handler
  void _handleTemplateAction(String action, PDFTemplate template) {
    switch (action) {
      case 'edit':
        navigateToEditor(template);
        break;
      case 'preview':
        _previewTemplate(template);
        break;
      case 'toggle_active':
        context.read<AppStateProvider>().togglePDFTemplateActive(template.id);
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

  void _previewTemplate(PDFTemplate template) async {
    final navigator = Navigator.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating preview...'),
            ],
          ),
        ),
      );

      final appState = context.read<AppStateProvider>();
      final previewPath = await appState.generateTemplatePreview(template);

      navigator.pop();

      navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: previewPath,
            suggestedFileName: 'Preview_${template.templateName}.pdf',
            title: 'Template Preview: ${template.templateName}',
            isPreview: true,
          ),
        ),
      );
    } catch (e) {
      navigator.pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _duplicateTemplate(PDFTemplate template) async {
    try {
      final duplicatedTemplate = template.clone();
      duplicatedTemplate.templateName = '${template.templateName} (Copy)';

      await context.read<AppStateProvider>().addPDFTemplate(duplicatedTemplate);

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

  void _deleteTemplate(PDFTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF Template'),
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
                  Text('Type: ${template.templateType}'),
                  Text('Category: ${template.userCategoryKey ?? 'No Category'}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone and will also delete the associated PDF file.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
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
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}