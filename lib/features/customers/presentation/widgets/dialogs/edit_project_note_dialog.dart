import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../controllers/communication_history_controller.dart';

/// Dialog for editing existing project notes
/// Extracted from InfoTab to create reusable component
class EditProjectNoteDialog extends StatefulWidget {
  final String originalEntry;
  final String timestamp;
  final Customer customer;
  final CommunicationHistoryController controller;

  const EditProjectNoteDialog({
    super.key,
    required this.originalEntry,
    required this.timestamp,
    required this.customer,
    required this.controller,
  });

  @override
  State<EditProjectNoteDialog> createState() => _EditProjectNoteDialogState();
}

class _EditProjectNoteDialogState extends State<EditProjectNoteDialog> {
  late final TextEditingController noteController;
  late String editedNoteType;

  @override
  void initState() {
    super.initState();
    
    // Parse existing note
    final parts = widget.originalEntry.split(': ');
    String noteContent = '';
    String noteType = 'note';

    if (parts.length > 1) {
      final fullNote = parts.sublist(1).join(': ');
      noteContent = fullNote.replaceFirst('PROJECT_NOTE: ', '');

      if (noteContent.toLowerCase().contains('meeting')) {
        noteType = 'meeting';
      } else if (noteContent.toLowerCase().contains('site visit')) {
        noteType = 'site_visit';
      } else {
        noteType = 'note';
      }
    }

    noteController = TextEditingController(text: noteContent);
    editedNoteType = noteType;
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Project Note',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Modify this project note',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNoteTypeSelector(),
            const SizedBox(height: 20),
            _buildNoteContentField(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Type:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'note',
              label: Text('General'),
              icon: Icon(Icons.note),
            ),
            ButtonSegment(
              value: 'meeting',
              label: Text('Meeting'),
              icon: Icon(Icons.group),
            ),
            ButtonSegment(
              value: 'site_visit',
              label: Text('Site Visit'),
              icon: Icon(Icons.home_work),
            ),
          ],
          selected: {editedNoteType},
          onSelectionChanged: (selection) {
            setState(() {
              editedNoteType = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNoteContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Content:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: noteController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: _getProjectNoteHint(editedNoteType),
            prefixIcon: Icon(_getProjectNoteIcon(editedNoteType)),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          textAlignVertical: TextAlignVertical.top,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _handleUpdateNote,
            icon: const Icon(Icons.save),
            label: const Text('Update Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateNote() async {
    final editedContent = noteController.text.trim();
    if (editedContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note content cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await widget.controller.updateProjectNote(
        widget.originalEntry,
        widget.timestamp,
        editedContent,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project note updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getProjectNoteHint(String noteType) {
    switch (noteType) {
      case 'meeting':
        return 'Meeting details, attendees, decisions made...';
      case 'site_visit':
        return 'Site observations, measurements, photos taken...';
      case 'note':
      default:
        return 'General project notes, reminders, observations...';
    }
  }

  IconData _getProjectNoteIcon(String noteType) {
    switch (noteType) {
      case 'meeting':
        return Icons.group;
      case 'site_visit':
        return Icons.home_work;
      case 'note':
      default:
        return Icons.note;
    }
  }
}