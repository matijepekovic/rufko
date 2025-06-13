import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/settings/custom_app_data.dart';
import '../../../../../data/models/media/inspection_document.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../core/utils/helpers/common_utils.dart';
import '../../../../media/presentation/screens/inspection_viewer_screen.dart';

class InspectionTab extends StatefulWidget {
  final Customer customer;

  const InspectionTab({super.key, required this.customer});

  @override
  State<InspectionTab> createState() => _InspectionTabState();
}

class _InspectionTabState extends State<InspectionTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final allCustomFields = appState.customAppDataFields;
        final inspectionFields = allCustomFields
            .where((field) => field.category == 'inspection')
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (inspectionFields.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No inspection fields configured',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to Templates → Fields\nand create fields with "Inspection" category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigation to Fields coming soon'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Inspection Fields'),
                ),
                const SizedBox(height: 32),
                _buildInspectionDocumentsSection(),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, size: 28, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Site Inspection - ${widget.customer.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Fill out inspection details for this customer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_mode,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  Text(
                    'Auto-saves',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${inspectionFields.length} field${inspectionFields.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Inspection Fields',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: inspectionFields.length,
                        onReorder: (oldIndex, newIndex) => _onInspectionFieldReorder(oldIndex, newIndex, inspectionFields),
                        itemBuilder: (context, index) {
                          final field = inspectionFields[index];
                          return Container(
                            key: ValueKey(field.id),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: _buildFieldWidget(field),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInspectionDocumentsSection(),
            ],
          ),
        );
      },
    );
  }

  void _onInspectionFieldReorder(int oldIndex, int newIndex, List<CustomAppDataField> fields) {
    if (oldIndex < newIndex) {
      newIndex--;
    }

    final movedField = fields.removeAt(oldIndex);
    fields.insert(newIndex, movedField);

    context.read<AppStateProvider>().reorderCustomAppDataFields('inspection', fields);
  }

  Widget _buildInspectionDocumentsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final inspectionDocs = appState.getInspectionDocumentsForCustomer(widget.customer.id);

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Inspection Documents',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${inspectionDocs.length} items',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (inspectionDocs.isEmpty)
                  _buildEmptyInspectionDocuments()
                else
                  _buildInspectionDocumentsList(inspectionDocs),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyInspectionDocuments() {
    final existingDocs = context.read<AppStateProvider>().getInspectionDocumentsForCustomer(widget.customer.id);
    final hasNote = existingDocs.any((doc) => doc.isNote);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No inspection documents yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add notes and PDFs to document your inspection',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddInspectionNoteDialog,
                  icon: Icon(hasNote ? Icons.edit_note : Icons.note_add, size: 16),
                  label: Text(hasNote ? 'Edit Note' : 'Add Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddInspectionPdfDialog,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionDocumentsList(List<InspectionDocument> documents) {
    final hasNote = documents.any((doc) => doc.isNote);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _showAddInspectionNoteDialog,
              icon: Icon(hasNote ? Icons.edit_note : Icons.note_add, size: 16),
              label: Text(hasNote ? 'Edit Note' : 'Add Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showAddInspectionPdfDialog,
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    doc.isNote ? Icons.note : Icons.picture_as_pdf,
                    color: doc.isNote ? Colors.blue : Colors.red,
                    size: 20,
                  ),
                  title: Text(
                    doc.displayTitle,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    doc.isNote
                        ? 'Note • ${DateFormat('MMM dd, yyyy').format(doc.createdAt)}'
                        : 'PDF • ${doc.formattedFileSize} • ${DateFormat('MMM dd, yyyy').format(doc.createdAt)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    final allDocs = context.read<AppStateProvider>().getInspectionDocumentsForCustomer(widget.customer.id);
                    final index = allDocs.indexWhere((d) => d.id == doc.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InspectionViewerScreen(
                          customer: widget.customer,
                          initialIndex: index != -1 ? index : 0,
                        ),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddInspectionNoteDialog() {
    final existingDocs = context.read<AppStateProvider>().getInspectionDocumentsForCustomer(widget.customer.id);
    final existingNote = existingDocs.where((doc) => doc.isNote).toList();

    if (existingNote.isNotEmpty) {
      _showEditInspectionNoteDialog(existingNote.first);
      return;
    }

    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isMobile = screenHeight < 700;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.note_add, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Inspection Note'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: isMobile ? screenHeight * 0.5 : 200,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      hintText: 'Document your inspection findings...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: isMobile ? 6 : 4,
                  ),
                  if (isMobile) const SizedBox(height: 12),
                  if (isMobile)
                    Text(
                      'Quick add:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (isMobile) const SizedBox(height: 4),
                  if (isMobile)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        _buildQuickChip('Good condition', contentController),
                        _buildQuickChip('Minor repairs needed', contentController),
                        _buildQuickChip('Replacement recommended', contentController),
                        _buildQuickChip('No immediate concerns', contentController),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                if (contentController.text.trim().isNotEmpty) {
                  final note = InspectionDocumentHelper.createNote(
                    customerId: widget.customer.id,
                    title: 'Site Inspection',
                    content: contentController.text.trim(),
                  );

                  await context.read<AppStateProvider>().addInspectionDocument(note);
                  navigator.pop();

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Inspection note saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickChip(String text, TextEditingController controller) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 10)),
      onPressed: () {
        if (controller.text.isEmpty) {
          controller.text = text;
        } else {
          controller.text += '\n$text';
        }
      },
      backgroundColor: Colors.blue.shade50,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showEditInspectionNoteDialog(InspectionDocument existingNote) {
    final contentController = TextEditingController(text: existingNote.content);

    showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 700;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit_note, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Edit Note'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? screenHeight * 0.35 : 350,
            ),
            child: SingleChildScrollView(
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: 'Update inspection notes...',
                  border: OutlineInputBorder(),
                ),
                maxLines: isSmallScreen ? 6 : 8,
              ),
            ),
          ),
          actions: [
            if (!isSmallScreen)
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Note'),
                      content: const Text('Delete this inspection note?'),
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

                  if (!context.mounted) return;

                  if (shouldDelete == true) {
                    await context.read<AppStateProvider>().deleteInspectionDocument(existingNote.id);
                    if (!context.mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Note deleted'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                existingNote.updateContent(contentController.text.trim());
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Note updated!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Update'),
            ),
          ],
          actionsPadding: isSmallScreen
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : const EdgeInsets.all(8),
        );
      },
    );
  }

  void _showAddInspectionPdfDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();

        if (!mounted) return;

        final titleController = TextEditingController(text: fileName.replaceAll('.pdf', ''));
        List<String> selectedTags = ['inspection', 'pdf'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Add PDF Document'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatFileSize(fileSize),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    hintText: 'e.g., Roof Inspection Report',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final document = InspectionDocumentHelper.createPdf(
                    customerId: widget.customer.id,
                    title: title,
                    filePath: file.path,
                    fileSizeBytes: fileSize,
                    tags: selectedTags,
                  );

                  await context.read<AppStateProvider>().addInspectionDocument(document);

                  navigator.pop();

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('PDF document added!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Add Document'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error selecting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFieldWidget(dynamic field) {
    final currentValue = widget.customer.getInspectionValue(field.fieldName);

    switch (field.fieldType) {
      case 'text':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.text_fields, color: Colors.blue),
                ),
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );
      case 'multiline':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.notes, color: Colors.blue),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );
      case 'number':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.numbers, color: Colors.green),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numValue = double.tryParse(value);
                  _updateFieldValue(field.fieldName, numValue ?? value);
                },
              ),
            ),
            const SizedBox(width: 48),
          ],
        );
      case 'checkbox':
        final bool checkboxValue = currentValue == true || currentValue == 'true';
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: Text(field.displayName),
                  subtitle: field.description != null ? Text(field.description) : null,
                  value: checkboxValue,
                  onChanged: (value) {
                    _updateFieldValue(field.fieldName, value ?? false);
                  },
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );
      case 'dropdown':
        final options = field.dropdownOptions ?? ['Good', 'Fair', 'Poor'];
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentValue?.toString(),
                decoration: InputDecoration(
                  labelText: field.displayName,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.arrow_drop_down, color: Colors.purple),
                ),
                items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );
      case 'date':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder ?? 'Select date',
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.red),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _selectDate(field.fieldName),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(field.fieldName),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );
      default:
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.help_outline, color: Colors.grey),
                ),
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            const SizedBox(width: 48),
          ],
        );
    }
  }

  void _updateFieldValue(String fieldName, dynamic value) {
    widget.customer.setInspectionValue(fieldName, value);
    setState(() {});
    try {
      context.read<AppStateProvider>().updateCustomer(widget.customer);
      debugPrint('✅ Auto-saved inspection field: $fieldName = $value');
    } catch (e) {
      debugPrint('❌ Error auto-saving inspection data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectDate(String fieldName) async {
    final currentValue = widget.customer.getInspectionValue(fieldName);
    DateTime initialDate = DateTime.now();

    if (currentValue != null && currentValue.toString().isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentValue.toString());
      } catch (e) {
        // Use current date if parsing fails
      }
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      _updateFieldValue(fieldName, date.toIso8601String().split('T')[0]);
    }
  }
}
