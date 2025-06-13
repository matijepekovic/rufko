import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/business/customer.dart';
import '../../../data/providers/state/app_state_provider.dart';
import '../../../features/customers/presentation/widgets/enhanced_communication_dialog.dart';
import 'communication_actions_mixin.dart';

mixin CustomerCommunicationMixin<T extends StatefulWidget> on State<T>, CommunicationActionsMixin<T> {
  Customer get customer;

  void previewAndSendSMS(dynamic template);
  void previewAndSendEmail(dynamic template);

  void addCommunication() {
    showDialog(
      context: context,
      builder: (context) => EnhancedCommunicationDialog(
        customer: customer,
        onCommunicationAdded: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void showTemplateSMSPicker() {
    final appState = context.read<AppStateProvider>();
    final messageTemplates = appState.activeMessageTemplates;

    if (messageTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No message templates available. Create templates first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.sms, color: Colors.purple),
                  SizedBox(width: 8),
                  Text(
                    'Choose SMS Template',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a template to send to ${customer.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: messageTemplates.length,
                  itemBuilder: (context, index) {
                    final template = messageTemplates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.sms, color: Colors.purple),
                        ),
                        title: Text(
                          template.templateName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${template.category} • ${template.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          previewAndSendSMS(template);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showTemplateEmailPicker() {
    final appState = context.read<AppStateProvider>();
    final emailTemplates = appState.activeEmailTemplates;

    if (emailTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email templates available. Create templates first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Choose Email Template',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a template to send to ${customer.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: emailTemplates.length,
                  itemBuilder: (context, index) {
                    final template = emailTemplates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.email, color: Colors.blue),
                        ),
                        title: Text(
                          template.templateName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${template.category} • ${template.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          previewAndSendEmail(template);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showQuickCommunicationOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Communication',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact ${customer.name} directly',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                _buildRealCommTile(
                    'Call Customer',
                    customer.phone != null ? 'Call ${customer.phone}' : 'No phone number',
                    Icons.phone,
                    Colors.green,
                    customer.phone != null ? () => makePhoneCall(customer.phone!) : null),
                _buildRealCommTile(
                    'Send Email',
                    customer.email != null ? 'Email ${customer.email}' : 'No email address',
                    Icons.email,
                    Colors.blue,
                    customer.email != null ? () => sendEmail(customer.email!) : null),
                _buildRealCommTile(
                    'Send Text Message',
                    customer.phone != null ? 'Text ${customer.phone}' : 'No phone number',
                    Icons.sms,
                    Colors.purple,
                    customer.phone != null ? () => sendSMS(customer.phone!) : null),
                const Divider(height: 32),
                Text(
                  'Quick Log Entry',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildQuickCommTile(
                    'Initial Contact',
                    'Customer inquiry received',
                    Icons.contact_phone,
                    Colors.blue,
                    () => _addQuickNote('📞 Initial contact - Customer interested in roofing services')),
                _buildQuickCommTile(
                    'Quote Sent',
                    'Quote delivered to customer',
                    Icons.send,
                    Colors.green,
                    () => _showQuoteSentDialog()),
                _buildQuickCommTile(
                    'Site Visit',
                    'Schedule or log site visit',
                    Icons.location_on,
                    Colors.orange,
                    () => _showSiteVisitDialog()),
                _buildQuickCommTile(
                    'Follow-up Needed',
                    'Set reminder note',
                    Icons.schedule,
                    Colors.amber,
                    () => _showFollowUpDialog()),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCommTile(
      String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  Widget _buildRealCommTile(
      String title, String subtitle, IconData icon, Color color, VoidCallback? onTap) {
    final bool isEnabled = onTap != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnabled ? color.withAlpha(25) : Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isEnabled ? color : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: isEnabled ? null : Colors.grey),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: isEnabled ? null : Colors.grey)),
        trailing: isEnabled
            ? const Icon(Icons.launch, size: 16)
            : const Icon(Icons.block, size: 16, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        enabled: isEnabled,
        onTap: onTap != null
            ? () {
                Navigator.pop(context);
                onTap();
              }
            : null,
      ),
    );
  }

  void _addQuickNote(String message) {
    customer.addCommunication(message);
    context.read<AppStateProvider>().updateCustomer(customer);
    if (mounted) setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Communication logged'), backgroundColor: Colors.green),
    );
  }

  void _showQuoteSentDialog() {
    final quoteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quote Sent'),
        content: TextField(
          controller: quoteController,
          decoration: const InputDecoration(
            labelText: 'Quote Number (optional)',
            hintText: 'e.g., Q-2024-001',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quoteNum = quoteController.text.isNotEmpty ? quoteController.text : 'new quote';
              _addQuickNote('📧 Quote sent - $quoteNum delivered to customer');
              Navigator.pop(context);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showSiteVisitDialog() {
    final notesController = TextEditingController();
    bool isScheduled = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Site Visit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: isScheduled,
                    onChanged: (value) => setDialogState(() => isScheduled = value!),
                  ),
                  const Text('Scheduled'),
                  Radio<bool>(
                    value: false,
                    groupValue: isScheduled,
                    onChanged: (value) => setDialogState(() => isScheduled = value!),
                  ),
                  const Text('Completed'),
                ],
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: isScheduled ? 'Schedule Details' : 'Visit Notes',
                  hintText: isScheduled ? 'Date and time...' : 'What was observed...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final prefix = isScheduled ? '📅 Site visit scheduled' : '🏠 Site visit completed';
                final notes = notesController.text.isNotEmpty ? ' - ${notesController.text}' : '';
                _addQuickNote('$prefix$notes');
                Navigator.pop(context);
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowUpDialog() {
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Follow-up Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Note',
                  hintText: 'What needs to be followed up?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final notes = notesController.text.isNotEmpty ? notesController.text : 'General follow-up';
                final dateStr = DateFormat('MMM dd').format(selectedDate);
                _addQuickNote('📅 FOLLOW-UP ($dateStr): $notes');
                Navigator.pop(context);
              },
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
