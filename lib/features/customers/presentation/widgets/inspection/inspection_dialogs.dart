import 'package:flutter/material.dart';

/// Collection of reusable dialogs for inspection operations
/// Extracted from InspectionTab for better maintainability
class InspectionDialogs {
  /// Show dialog to add or edit inspection note
  static Future<String?> showNoteDialog({
    required BuildContext context,
    String? existingContent,
    bool isEdit = false,
  }) async {
    final contentController = TextEditingController(text: existingContent ?? '');
    
    return showDialog<String>(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isMobile = screenHeight < 700;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_note : Icons.note_add,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Inspection Note' : 'Add Inspection Note'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: isMobile ? screenHeight * 0.5 : 300,
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
                    maxLines: isMobile ? 8 : 6,
                    autofocus: true,
                  ),
                  if (isMobile) const SizedBox(height: 12),
                  if (isMobile) _buildQuickChips(contentController),
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
              onPressed: () {
                final content = contentController.text.trim();
                if (content.isNotEmpty) {
                  Navigator.pop(context, content);
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Update' : 'Add Note'),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog for deleting inspection document
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String documentName,
    required bool isNote,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text('Delete ${isNote ? 'Note' : 'Document'}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$documentName"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isNote ? Icons.note : Icons.picture_as_pdf,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      documentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Show error dialog
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build quick text chips for common inspection notes
  static Widget _buildQuickChips(TextEditingController controller) {
    final quickTexts = [
      'Good condition',
      'Minor repairs needed',
      'Replacement recommended',
      'No immediate concerns',
      'Further inspection required',
      'Meets standards',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick add:',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: quickTexts.map((text) => _buildQuickChip(text, controller)).toList(),
        ),
      ],
    );
  }

  /// Build individual quick text chip
  static Widget _buildQuickChip(String text, TextEditingController controller) {
    return InkWell(
      onTap: () {
        final currentText = controller.text;
        if (currentText.isNotEmpty && !currentText.endsWith('\n') && !currentText.endsWith(' ')) {
          controller.text = '$currentText. $text';
        } else {
          controller.text = '$currentText$text';
        }
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}