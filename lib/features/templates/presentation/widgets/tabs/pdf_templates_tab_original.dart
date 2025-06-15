import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/templates/pdf_template.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../screens/template_editor_screen.dart';
import '../../../../quotes/presentation/screens/pdf_preview_screen.dart';
import '../../../../../app/theme/rufko_theme.dart';
import '../../../../../core/mixins/template_tab_mixin.dart';

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
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Rename'),
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
      case 'rename':
        _renameTemplate(template);
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _renameTemplate(PDFTemplate template) {
    final TextEditingController controller = TextEditingController(text: template.templateName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  decoration: const BoxDecoration(
                    color: RufkoTheme.primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rename Template',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current name: ${template.templateName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'New Template Name',
                          hintText: 'Enter a new name for this template',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (value) {
                          // Allow Enter key to submit
                          if (value.trim().isNotEmpty && value.trim() != template.templateName) {
                            Navigator.of(context).pop();
                            _performRename(template, value.trim());
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final newName = controller.text.trim();
                          if (newName.isNotEmpty && newName != template.templateName) {
                            Navigator.of(context).pop();
                            _performRename(template, newName);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RufkoTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text('Rename'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// ADD this helper method to handle the actual rename operation:
  void _performRename(PDFTemplate template, String newName) async {
    try {
      // Modify the original template directly - DON'T clone
      template.templateName = newName;
      template.updatedAt = DateTime.now();

      // Update in the app state using the same template object
      await context.read<AppStateProvider>().updatePDFTemplate(template);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Renamed template to: $newName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renaming template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteTemplate(PDFTemplate template) async {
    final confirmed = await showDialog<bool>(
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