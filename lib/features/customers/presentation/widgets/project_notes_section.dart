import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';

class ProjectNotesSection extends StatelessWidget {
  final Customer customer;
  final void Function(String, String) onEditNote;
  final String Function(String) formatDate;

  const ProjectNotesSection({
    super.key,
    required this.customer,
    required this.onEditNote,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final projectNotes = customer.communicationHistory
        .where((entry) => entry.contains('PROJECT_NOTE:'))
        .toList()
        .reversed
        .toList();

    if (projectNotes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No project notes yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Add notes about meetings, site visits, and project details',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: projectNotes.map((entry) {
        final parts = entry.split(': ');
        final timestamp = parts.isNotEmpty ? parts[0] : '';
        final fullNote = parts.length > 1 ? parts.sublist(1).join(': ') : entry;

        final noteContent = fullNote.replaceFirst('PROJECT_NOTE: ', '');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 0.5,
            color: Colors.grey.shade50,
            child: ListTile(
              title: Text(
                noteContent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                formatDate(timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                onPressed: () => onEditNote(entry, timestamp),
                tooltip: 'Edit Note',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
