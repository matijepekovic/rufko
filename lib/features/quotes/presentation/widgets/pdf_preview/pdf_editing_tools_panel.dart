import 'package:flutter/material.dart';
import '../../controllers/pdf_preview_controller.dart';

/// Panel containing editing tools for PDF preview
class PDFEditingToolsPanel extends StatelessWidget {
  final PdfPreviewController controller;

  const PDFEditingToolsPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.showEditingTools) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 120,
      color: Colors.grey[900],
      child: Column(
        children: [
          Container(
            height: 40,
            color: Colors.grey[800],
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.edit, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Editing Tools',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (controller.hasEdits) ...[
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                    onPressed: controller.editingController.canUndo()
                        ? controller.editingController.undo
                        : null,
                    tooltip: 'Undo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, color: Colors.white, size: 20),
                    onPressed: controller.editingController.canRedo()
                        ? controller.editingController.redo
                        : null,
                    tooltip: 'Redo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.orange, size: 20),
                    onPressed: () => _showClearEditsDialog(context),
                    tooltip: 'Clear All Edits',
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: controller.isLoadingFields
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _buildFieldsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList() {
    if (controller.editableFields.isEmpty) {
      return const Center(
        child: Text(
          'No editable fields found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: controller.editableFields.length,
      itemBuilder: (context, index) {
        final fieldKey = controller.editableFields[index];
        final currentValue = controller.getCurrentFieldValue(fieldKey);
        final hasValue = currentValue.isNotEmpty;

        return Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          child: Card(
            color: Colors.grey[800],
            child: InkWell(
              onTap: () => _editField(fieldKey),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fieldKey,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasValue ? currentValue : 'Tap to edit',
                      style: TextStyle(
                        color: hasValue ? Colors.white70 : Colors.grey[500],
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasValue) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _editField(String fieldKey) {
    final currentValue = controller.getCurrentFieldValue(fieldKey);
    controller.dialogManager.showEditDialog(fieldKey, currentValue);
  }

  void _showClearEditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Edits'),
        content: const Text('Are you sure you want to clear all unsaved changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.editingController.clearEdits();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}