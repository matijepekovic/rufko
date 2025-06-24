import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../project_notes_section.dart';
import '../customer_info_card_widget.dart';
import '../../controllers/communication_history_controller.dart';
import '../dialogs/project_note_dialog.dart';
import '../dialogs/edit_project_note_dialog.dart';

/// InfoTab widget for displaying customer information and project notes
/// Communication history moved to separate CommunicationsTab
/// Refactored from original 1,585-line monolithic file to use extracted components
class InfoTab extends StatefulWidget {
  final Customer customer;
  final String Function(String timestamp) formatDate;
  final VoidCallback? onEditCustomer;

  const InfoTab({
    super.key,
    required this.customer,
    required this.formatDate,
    this.onEditCustomer,
  });

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  late CommunicationHistoryController _communicationController;

  @override
  void initState() {
    super.initState();
    _communicationController = CommunicationHistoryController(
      customer: widget.customer,
      context: context,
    );
  }

  @override
  void dispose() {
    _communicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Information Card - extracted to CustomerInfoCardWidget
          CustomerInfoCardWidget(
            customer: widget.customer,
            onEdit: widget.onEditCustomer,
          ),
          
          const SizedBox(height: 16),
          
          // Project Notes Section - using existing ProjectNotesSection with new dialogs
          _buildProjectNotesCard(),
        ],
      ),
    );
  }

  /// Build project notes card with header and existing ProjectNotesSection
  Widget _buildProjectNotesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectNotesHeader(),
            const SizedBox(height: 12),
            ProjectNotesSection(
              customer: widget.customer,
              onEditNote: _handleEditProjectNote,
              formatDate: widget.formatDate,
            ),
          ],
        ),
      ),
    );
  }

  /// Build project notes section header with add button
  Widget _buildProjectNotesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Project Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_task),
              onPressed: _handleAddProjectNote,
              tooltip: 'Add Project Note',
            ),
          ],
        ),
      ],
    );
  }


  /// Handle adding new project note using extracted dialog
  void _handleAddProjectNote() {
    showDialog(
      context: context,
      builder: (context) => ProjectNoteDialog(
        customer: widget.customer,
        controller: _communicationController,
      ),
    );
  }

  /// Handle editing existing project note using extracted dialog
  void _handleEditProjectNote(String originalEntry, String timestamp) {
    showDialog(
      context: context,
      builder: (context) => EditProjectNoteDialog(
        originalEntry: originalEntry,
        timestamp: timestamp,
        customer: widget.customer,
        controller: _communicationController,
      ),
    );
  }
}