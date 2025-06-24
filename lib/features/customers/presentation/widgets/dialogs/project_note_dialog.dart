import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../controllers/communication_history_controller.dart';

/// Full-screen dialog for adding project notes
/// Redesigned to match CustomerFormDialog pattern
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project Note'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton(
            onPressed: _handleAddNote,
            child: const Text('Add Note'),
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNoteTypeSelector(),
              const SizedBox(height: 24),
              _buildNoteContentField(),
              const SizedBox(height: 24),
              _buildQuickTemplates(),
              const SizedBox(height: 24), // Extra space for keyboard
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildNoteTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'note',
              label: Text('General'),
              icon: Icon(Icons.note, size: 18),
            ),
            ButtonSegment(
              value: 'meeting',
              label: Text('Meeting'),
              icon: Icon(Icons.group, size: 18),
            ),
            ButtonSegment(
              value: 'site_visit',
              label: Text('Site Visit'),
              icon: Icon(Icons.home_work, size: 18),
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
          'Note Content',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: 'Project Note*',
            hintText: _getProjectNoteHint(noteType),
            prefixIcon: Icon(
              _getProjectNoteIcon(noteType),
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          textAlignVertical: TextAlignVertical.top,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildQuickTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getProjectNoteTemplates(noteType).map((template) {
            return ActionChip(
              label: Text(
                template,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                noteController.text = template;
              },
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
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