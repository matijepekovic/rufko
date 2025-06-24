import 'package:flutter/material.dart';
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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




}
