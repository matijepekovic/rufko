import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import 'project_notes_section.dart';

class InfoTab extends StatelessWidget {
  final Customer customer;
  final VoidCallback onAddProjectNote;
  final void Function(String entry, String timestamp) onEditProjectNote;
  final String Function(String timestamp) formatDate;
  final VoidCallback onTemplateEmail;
  final VoidCallback onTemplateSMS;
  final VoidCallback onQuickCommunication;
  final VoidCallback onAddCommunication;
  final Widget communicationHistory;

  const InfoTab({
    super.key,
    required this.customer,
    required this.onAddProjectNote,
    required this.onEditProjectNote,
    required this.formatDate,
    required this.onTemplateEmail,
    required this.onTemplateSMS,
    required this.onQuickCommunication,
    required this.onAddCommunication,
    required this.communicationHistory,
  });

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Customer since ${DateFormat('MMM yyyy').format(customer.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(context, Icons.phone_outlined, 'Phone', customer.phone ?? 'Not provided'),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, Icons.email_outlined, 'Email', customer.email ?? 'Not provided'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    'Address',
                    customer.fullDisplayAddress.isNotEmpty &&
                            customer.fullDisplayAddress != 'No address provided'
                        ? customer.fullDisplayAddress
                        : 'Not provided',
                  ),
                  if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.note_outlined, 'Notes', customer.notes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            onPressed: onAddProjectNote,
                            tooltip: 'Add Project Note',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProjectNotesSection(
                    customer: customer,
                    onEditNote: onEditProjectNote,
                    formatDate: formatDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Communication',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.email_outlined),
                            onPressed: onTemplateEmail,
                            tooltip: 'Send Template Email',
                          ),
                          IconButton(
                            icon: const Icon(Icons.sms_outlined),
                            onPressed: onTemplateSMS,
                            tooltip: 'Send Template SMS',
                          ),
                          IconButton(
                            icon: const Icon(Icons.flash_on),
                            onPressed: onQuickCommunication,
                            tooltip: 'Quick Communication',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_comment_outlined),
                            onPressed: onAddCommunication,
                            tooltip: 'Add Communication',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  communicationHistory,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
