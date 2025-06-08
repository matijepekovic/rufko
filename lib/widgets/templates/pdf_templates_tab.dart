import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/pdf_template.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/rufko_theme.dart';
import '../../screens/template_editor_screen.dart';
import '../../screens/pdf_preview_screen.dart';

class PdfTemplatesTab extends StatefulWidget {
  const PdfTemplatesTab({super.key});

  @override
  State<PdfTemplatesTab> createState() => _PdfTemplatesTabState();
}

class _PdfTemplatesTabState extends State<PdfTemplatesTab> {
  String _searchQuery = '';
  String _selectedCategoryKey = 'all';
  Map<String, String> _categoryNames = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final templates = _filterTemplates(appState.pdfTemplates);
        final grouped = <String, List<PDFTemplate>>{};
        for (final t in templates) {
          final key = t.userCategoryKey ?? 'uncategorized';
          grouped.putIfAbsent(key, () => []).add(t);
        }

        return Column(
          children: [
            _buildSearchAndFilter(appState),
            const SizedBox(height: 16),
            Expanded(
              child: templates.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final key = grouped.keys.elementAt(index);
                        final items = grouped[key]!;
                        return _buildCategorySection(key, items);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search PDF templates...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                    future: appState.getAllTemplateCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 40);
                      }
                      final cats = snapshot.data!['pdf_templates'] ?? [];
                      if (_categoryNames.length != cats.length) {
                        setState(() {
                          _categoryNames = {
                            for (final c in cats) c['key'] as String: c['name'] as String
                          };
                        });
                      }
                      return Row(
                        children: [
                          _buildFilterChip(
                              'All Categories', Icons.view_list, 'all'),
                          ...cats.map((c) => _buildFilterChip(
                              c['name'] as String,
                              Icons.description,
                              c['key'] as String)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, String key) {
    final selected = _selectedCategoryKey == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: selected,
        selectedColor: RufkoTheme.primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
        onSelected: (_) {
          setState(() => _selectedCategoryKey = key);
        },
      ),
    );
  }

  Widget _buildCategorySection(String key, List<PDFTemplate> templates) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor(key).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(_getTypeIcon(key), color: _getTypeColor(key), size: 20),
                const SizedBox(width: 8),
                Text(
                  _getCategoryDisplayName(key),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(key),
                  ),
                ),
                const Spacer(),
                Text('${templates.length} template${templates.length == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          ...templates.map(_buildTemplateCard),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(PDFTemplate template) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editTemplate(template),
        onLongPress: () => _previewTemplate(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: template.isActive
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.isActive ? Icons.check : Icons.close,
                      color:
                          template.isActive ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.templateName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(dateFormat.format(template.updatedAt),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleTemplateAction(action, template),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: Text('Preview'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(template.isActive ? 'Deactivate' : 'Activate'),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  List<PDFTemplate> _filterTemplates(List<PDFTemplate> templates) {
    var filtered = templates;
    if (_selectedCategoryKey != 'all') {
      filtered = filtered
          .where((t) => t.userCategoryKey == _selectedCategoryKey)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.templateName.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.templateType.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  String _getCategoryDisplayName(String key) {
    if (key == 'uncategorized') return 'Uncategorized Templates';
    return _categoryNames[key] ?? '$key Templates';
  }

  Color _getTypeColor(String key) {
    return key == 'uncategorized' ? Colors.grey : Colors.blue;
  }

  IconData _getTypeIcon(String key) {
    return key == 'uncategorized' ? Icons.folder_outlined : Icons.description;
  }

  void _editTemplate(PDFTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _handleTemplateAction(String action, PDFTemplate template) {
    switch (action) {
      case 'edit':
        _editTemplate(template);
        break;
      case 'preview':
        _previewTemplate(template);
        break;
      case 'toggle':
        context.read<AppStateProvider>().togglePDFTemplateActive(template.id);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'delete':
        _showDeleteConfirmation(template);
        break;
    }
  }

  void _duplicateTemplate(PDFTemplate template) async {
    final duplicated = template.clone();
    duplicated.templateName = '${template.templateName} (Copy)';
    await context.read<AppStateProvider>().addPDFTemplate(duplicated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template duplicated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteConfirmation(PDFTemplate template) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
            'Are you sure you want to delete "${template.templateName}"?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();
              await context
                  .read<AppStateProvider>()
                  .deletePDFTemplate(template.id);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Template deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No PDF Templates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first PDF template to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}
