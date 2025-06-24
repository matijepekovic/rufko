import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/settings/custom_app_data.dart';
import '../../../../../data/models/media/inspection_document.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../controllers/inspection_tab_controller.dart';
import '../inspection/inspection_field_widget.dart';
import '../inspection/inspection_documents_section.dart';
import '../inspection/inspection_dialogs.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

/// Refactored InspectionTab with extracted components
/// Original 944-line monolithic file broken down into manageable components
/// All original functionality preserved with improved maintainability
class InspectionTab extends StatefulWidget {
  final Customer customer;

  const InspectionTab({super.key, required this.customer});

  @override
  State<InspectionTab> createState() => _InspectionTabState();
}

class _InspectionTabState extends State<InspectionTab> 
    with ResponsiveBreakpointsMixin, ResponsiveSpacingMixin, ResponsiveDimensionsMixin {
  late InspectionTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InspectionTabController(
      context: context,
      customer: widget.customer,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.error != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                InspectionDialogs.showErrorSnackbar(
                  context: context,
                  message: _controller.error!,
                );
                _controller.clearError();
              });
            }

            final inspectionFields = _controller.getInspectionFields();

            if (inspectionFields.isEmpty) {
              return _buildEmptyFieldsState();
            }

            // Use Stack to add fixed bottom buttons
            return Stack(
              children: [
                _buildInspectionContent(inspectionFields),
                _buildBottomActionBar(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyFieldsState() {
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
              InspectionDialogs.showErrorSnackbar(
                context: context,
                message: 'Navigation to Fields coming soon',
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

  Widget _buildInspectionContent(List<CustomAppDataField> inspectionFields) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: spacingMD(context) * 2, // Increase side padding
        vertical: spacingMD(context),
      ).copyWith(
        bottom: 80 + spacingMD(context) * 2, // Space for bottom buttons
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInspectionHeader(inspectionFields),
          SizedBox(height: spacingLG(context)),
          _buildInspectionFieldsCard(inspectionFields),
          SizedBox(height: spacingMD(context)),
          // Use ValueListenableBuilder for efficient document list rebuilds
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) => _buildInspectionDocumentsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionHeader(List<CustomAppDataField> inspectionFields) {
    final completionPercentage = _controller.getCompletionPercentage();
    
    return Column(
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
            Icon(
              Icons.auto_mode,
              size: 16,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 4),
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
        if (completionPercentage > 0) ...[
          const SizedBox(height: 12),
          _buildProgressIndicator(completionPercentage),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator(double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Completion: ${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              '${(percentage * _controller.getInspectionFields().length).toInt()} of ${_controller.getInspectionFields().length} fields',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage < 0.5 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildInspectionFieldsCard(List<CustomAppDataField> inspectionFields) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldsHeader(),
            SizedBox(height: spacingMD(context)),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false, // Disable automatic drag handles
              itemCount: inspectionFields.length,
              onReorder: (oldIndex, newIndex) => _handleFieldReorder(oldIndex, newIndex, inspectionFields),
              itemBuilder: (context, index) {
                final field = inspectionFields[index];
                return _buildFieldItem(field, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacingMD(context), 
            vertical: spacingXS(context),
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Inspection Fields',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              fontSize: isCompact(context) ? 12 : 14,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Drag to reorder',
          style: TextStyle(
            fontSize: isCompact(context) ? 10 : 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldItem(CustomAppDataField field, int index) {
    return Container(
      key: ValueKey(field.id),
      margin: EdgeInsets.only(bottom: spacingSM(context)),
      child: InspectionFieldWidget(
        field: field,
        index: index,
        value: _controller.fieldValues[field.fieldName],
        onValueChanged: _controller.updateFieldValue,
        onDateTap: () => _controller.selectDate(field.fieldName),
      ),
    );
  }

  Widget _buildInspectionDocumentsSection() {
    final documents = _controller.getInspectionDocuments();
    
    return InspectionDocumentsSection(
      documents: documents,
      onAddNote: _handleAddNote,
      onAddPdf: _controller.addInspectionPdf,
      onDeleteDocument: _handleDeleteDocument,
      onEditNote: _handleEditNote,
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        bottom: true,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacingMD(context),
            vertical: spacingSM(context),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: RufkoSecondaryButton(
                  onPressed: _handleAddNote,
                  icon: Icons.note_add,
                  isFullWidth: true,
                  child: Text(isCompact(context) ? 'Note' : 'Add Note'),
                ),
              ),
              SizedBox(width: spacingMD(context)),
              Expanded(
                child: RufkoSecondaryButton(
                  onPressed: _controller.addInspectionPdf,
                  icon: Icons.picture_as_pdf,
                  isFullWidth: true,
                  child: Text(isCompact(context) ? 'PDF' : 'Add PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFieldReorder(int oldIndex, int newIndex, List<CustomAppDataField> fields) {
    _controller.reorderInspectionFields(oldIndex, newIndex, fields);
  }

  void _handleAddNote() async {
    final existingDocs = _controller.getInspectionDocuments();
    final existingNote = existingDocs.where((doc) => doc.isNote).toList();

    if (existingNote.isNotEmpty) {
      _handleEditNote(existingNote.first);
      return;
    }

    final content = await InspectionDialogs.showNoteDialog(context: context);
    if (content != null && content.isNotEmpty) {
      await _controller.addInspectionNote(content);
      if (mounted) {
        InspectionDialogs.showSuccessSnackbar(
          context: context,
          message: 'Inspection note added successfully',
        );
      }
    }
  }

  void _handleEditNote(InspectionDocument note) async {
    final content = await InspectionDialogs.showNoteDialog(
      context: context,
      existingContent: note.content,
      isEdit: true,
    );
    
    if (content != null && content.isNotEmpty) {
      await _controller.updateInspectionNote(note.id, content);
      if (mounted) {
        InspectionDialogs.showSuccessSnackbar(
          context: context,
          message: 'Inspection note updated successfully',
        );
      }
    }
  }

  void _handleDeleteDocument(String documentId) async {
    final documents = _controller.getInspectionDocuments();
    final document = documents.firstWhere((doc) => doc.id == documentId);
    
    final confirmed = await InspectionDialogs.showDeleteConfirmation(
      context: context,
      documentName: document.title,
      isNote: document.isNote,
    );
    
    if (confirmed) {
      await _controller.deleteInspectionDocument(documentId);
      if (mounted) {
        InspectionDialogs.showSuccessSnackbar(
          context: context,
          message: '${document.isNote ? 'Note' : 'Document'} deleted successfully',
        );
      }
    }
  }
}