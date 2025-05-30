// lib/screens/templates_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../models/pdf_template.dart';
import '../providers/app_state_provider.dart';
import '../services/template_service.dart';
import 'template_editor_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('PDF Templates'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppStateProvider>().loadPDFTemplates(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Templates list
          Expanded(
            child: Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                final templates = _filterTemplates(appState.pdfTemplates);

                if (appState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (templates.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => appState.loadPDFTemplates(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _buildTemplateCard(template, appState);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTemplate,
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
        backgroundColor: const Color(0xFF2E86AB),
      ),
    );
  }

  List<PDFTemplate> _filterTemplates(List<PDFTemplate> templates) {
    if (_searchQuery.isEmpty) return templates;

    final lowerQuery = _searchQuery.toLowerCase();
    return templates.where((template) =>
    template.templateName.toLowerCase().contains(lowerQuery) ||
        template.description.toLowerCase().contains(lowerQuery) ||
        template.templateType.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No PDF Templates' : 'No templates found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Create your first PDF template to get started'
                : 'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateCard(PDFTemplate template, AppStateProvider appState) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Template icon and name
                Expanded(
                  child: Row(
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
                          Icons.picture_as_pdf,
                          color: template.isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.templateName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (template.description.isNotEmpty)
                              Text(
                                template.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: template.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Template details
            Row(
              children: [
                Expanded(
                  child: _buildDetailChip(
                    Icons.layers,
                    'Type: ${template.templateType.toUpperCase()}',
                  ),
                ),
                Expanded(
                  child: _buildDetailChip(
                    Icons.text_fields,
                    '${template.fieldMappings.length} fields',
                  ),
                ),
                Expanded(
                  child: _buildDetailChip(
                    Icons.calendar_today,
                    dateFormat.format(template.updatedAt),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editTemplate(template),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previewTemplate(template),
                    icon: const Icon(Icons.preview, size: 18),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleTemplateAction(action, template, appState),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            template.isActive ? Icons.visibility_off : Icons.visibility,
                            size: 18,
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
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _createNewTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TemplateEditorScreen(),
      ),
    );
  }

  void _editTemplate(PDFTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _previewTemplate(PDFTemplate template) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating preview...'),
            ],
          ),
        ),
      );

      final previewPath = await TemplateService.instance.generateTemplatePreview(template);

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preview generated: ${previewPath.split('/').last}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // TODO: Open PDF with default app or internal viewer
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleTemplateAction(String action, PDFTemplate template, AppStateProvider appState) {
    switch (action) {
      case 'toggle_active':
        appState.togglePDFTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive
                  ? 'Template deactivated'
                  : 'Template activated',
            ),
          ),
        );
        break;

      case 'duplicate':
        _duplicateTemplate(template, appState);
        break;

      case 'delete':
        _showDeleteConfirmation(template, appState);
        break;
    }
  }

  void _duplicateTemplate(PDFTemplate template, AppStateProvider appState) async {
    try {
      final duplicatedTemplate = PDFTemplate(
        templateName: '${template.templateName} (Copy)',
        description: template.description,
        // IMPORTANT: For a true duplicate that can be independently edited later,
        // you might want to also copy the physical PDF file (template.pdfFilePath)
        // to a new unique path and update pdfFilePath here. For now, it points to the same PDF.
        pdfFilePath: template.pdfFilePath,
        fieldMappings: template.fieldMappings.map((originalField) {
          // Create a new FieldMapping, preserving the core linked data
          // and visual hints if they exist.
          return FieldMapping(
            // fieldId will be new via default constructor Uuid().v4()
            appDataType: originalField.appDataType,
            pdfFormFieldName: originalField.pdfFormFieldName, // Keep the link to the same PDF field
            detectedPdfFieldType: originalField.detectedPdfFieldType,
            visualX: originalField.visualX,
            visualY: originalField.visualY,
            visualWidth: originalField.visualWidth,
            visualHeight: originalField.visualHeight,
            pageNumber: originalField.pageNumber,
            fontFamilyOverride: originalField.fontFamilyOverride,
            fontSizeOverride: originalField.fontSizeOverride,
            fontColorOverride: originalField.fontColorOverride,
            alignmentOverride: originalField.alignmentOverride,
            defaultValue: originalField.defaultValue,
            additionalProperties: Map.from(originalField.additionalProperties), // Deep copy
          );
        }).toList(),
        templateType: template.templateType,
        pageWidth: template.pageWidth,
        pageHeight: template.pageHeight,
        totalPages: template.totalPages,
        metadata: Map.from(template.metadata), // Deep copy metadata
        isActive: true, // Typically a duplicated template starts as active
        // createdAt and updatedAt will be new via default constructor
      );

      await appState.addPDFTemplate(duplicatedTemplate);

      if (mounted) { // Good practice to check if mounted before ScaffoldMessenger
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
      if (kDebugMode) {
        print("Error duplicating template: $e");
      }
    }
  }

  void _showDeleteConfirmation(PDFTemplate template, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?\n\n'
              'This action cannot be undone and will also delete the associated PDF file.',
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
                await appState.deletePDFTemplate(template.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Template deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting template: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}