import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../controllers/communication_history_controller.dart';
import '../utils/communication_utils.dart';

/// Detail view for displaying full email thread conversation
class EmailThreadDetailView extends StatelessWidget {
  final Map<String, dynamic> thread;
  final Customer customer;
  final CommunicationHistoryController controller;
  final VoidCallback onClose;

  const EmailThreadDetailView({
    super.key,
    required this.thread,
    required this.customer,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final subject = thread['subject'] as String;
    final emails = thread['emails'] as List<Map<String, dynamic>>;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${emails.length} ${emails.length == 1 ? 'message' : 'messages'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Email messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: emails.length,
              itemBuilder: (context, index) {
                final email = emails[index];
                return _buildEmailMessage(context, email);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailMessage(BuildContext context, Map<String, dynamic> email) {
    final message = email['message'] as String;
    final timestamp = email['timestamp'] as String;
    final isOutgoing = email['isOutgoing'] as bool;
    final parsedEmail = controller.parseEmailContent(message);
    final body = parsedEmail['body']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isOutgoing 
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                    : Colors.grey[300],
                child: Icon(
                  isOutgoing ? Icons.business : Icons.person,
                  size: 16,
                  color: isOutgoing 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOutgoing ? 'You' : customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      formatCommunicationDate(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isOutgoing && _isEditableEmail(message))
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditEmailDialog(context, email),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Email body
          Container(
            margin: const EdgeInsets.only(left: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOutgoing 
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOutgoing 
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                    : Colors.grey[300]!,
              ),
            ),
            child: Text(
              body,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  bool _isEditableEmail(String message) {
    return message.contains('Email sent using template') ||
           message.contains('Subject:');
  }


  void _showEditEmailDialog(BuildContext context, Map<String, dynamic> email) {
    // This could be implemented similar to EditOutboundDialog
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email editing coming soon'),
      ),
    );
  }

}