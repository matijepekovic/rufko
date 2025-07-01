import 'package:flutter/material.dart';

import '../../../../data/models/business/customer.dart';
import '../controllers/communication_history_controller.dart';
import '../utils/communication_utils.dart';
import 'dialogs/customer_response_dialog.dart';

/// Card widget for prompting to add customer responses
/// Extracted from InfoTab to create reusable component
class AddResponseCardWidget extends StatelessWidget {
  final String originalMessage;
  final String timestamp;
  final String messageType;
  final Customer customer;
  final CommunicationHistoryController controller;

  const AddResponseCardWidget({
    super.key,
    required this.originalMessage,
    required this.timestamp,
    required this.messageType,
    required this.customer,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final contactMethod = controller.extractContactMethod(originalMessage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildCustomerAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: _buildResponseCard(context, contactMethod),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      child: Text(
        customer.name[0].toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildResponseCard(BuildContext context, String contactMethod) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAddResponseDialog(context, contactMethod),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
            color: Colors.orange.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(contactMethod),
              const SizedBox(height: 8),
              _buildActionPrompt(),
              const SizedBox(height: 4),
              _buildTimestamp(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(String contactMethod) {
    return Row(
      children: [
        Icon(
          messageType == 'sms' ? Icons.sms : Icons.email,
          color: Colors.orange.shade700,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            messageType == 'sms'
                ? 'SMS sent to $contactMethod'
                : 'Email sent to $contactMethod',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.orange.shade800,
              fontSize: 14,
            ),
          ),
        ),
        Icon(
          Icons.add_comment,
          color: Colors.orange.shade600,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildActionPrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'TAP TO ADD CUSTOMER RESPONSE',
        style: TextStyle(
          color: Colors.orange.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      formatCommunicationDate(timestamp),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 11,
      ),
    );
  }

  void _showAddResponseDialog(BuildContext context, String contactMethod) {
    showDialog(
      context: context,
      builder: (context) => CustomerResponseDialog(
        messageType: messageType,
        contactMethod: contactMethod,
        customer: customer,
        controller: controller,
      ),
    );
  }
}