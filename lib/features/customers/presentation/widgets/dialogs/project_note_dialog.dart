import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../controllers/communication_history_controller.dart';

/// Dialog for adding project notes
/// Extracted from InfoTab to create reusable component
class ProjectNoteDialog extends StatefulWidget {
  final Customer customer;
  final CommunicationHistoryController controller;

  const ProjectNoteDialog({
    super.key,
    required this.customer,
    required this.controller,
  });

  @override
  State<ProjectNoteDialog> createState() => _ProjectNoteDialogState();
}

class _ProjectNoteDialogState extends State<ProjectNoteDialog> {
  late final TextEditingController noteController;
  String noteType = 'note';

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController();
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
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_task, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Project Note',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Record meetings, site visits, and project details',
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
            const SizedBox(height: 16),
            _buildQuickTemplates(),
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
          selected: {noteType},
          onSelectionChanged: (selection) {
            setState(() {
              noteType = selection.first;
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
            hintText: _getProjectNoteHint(noteType),
            prefixIcon: Icon(_getProjectNoteIcon(noteType)),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          textAlignVertical: TextAlignVertical.top,
        ),
      ],
    );
  }

  Widget _buildQuickTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _getProjectNoteTemplates(noteType).map((template) {
            return ActionChip(
              label: Text(template),
              onPressed: () {
                noteController.text = template;
              },
              backgroundColor: Colors.grey[100],
            );
          }).toList(),
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
            onPressed: _handleAddNote,
            icon: const Icon(Icons.save),
            label: const Text('Add Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddNote() async {
    final noteContent = noteController.text.trim();
    if (noteContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note content cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await widget.controller.addProjectNote(noteContent);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project note added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding note: $e'),
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

  List<String> _getProjectNoteTemplates(String noteType) {
    switch (noteType) {
      case 'meeting':
        return [
          'Initial consultation meeting completed',
          'Discussed project timeline and materials',
          'Customer approved final design',
          'Reviewed contract terms',
        ];
      case 'site_visit':
        return [
          'Site measurement completed',
          'Photos taken of current condition',
          'Identified potential challenges',
          'Confirmed access requirements',
        ];
      case 'note':
      default:
        return [
          'Follow-up needed in 3 days',
          'Waiting for customer decision',
          'Materials ordered',
          'Permits applied for',
        ];
    }
  }
}