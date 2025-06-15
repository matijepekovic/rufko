import 'package:flutter/material.dart';

import '../../../../data/models/business/customer.dart';
import '../controllers/communication_history_controller.dart';
import '../utils/communication_utils.dart';
import 'dialogs/edit_response_dialog.dart';

/// Chat bubble widget for displaying individual communication messages
/// Extracted from InfoTab to create reusable component
class ChatBubbleWidget extends StatelessWidget {
  final String message;
  final String timestamp;
  final bool isOutgoing;
  final String messageType;
  final Customer customer;
  final CommunicationHistoryController controller;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isOutgoing,
    required this.messageType,
    required this.customer,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOutgoing) ...[
            _buildCustomerAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: _buildMessageBubble(context),
          ),
          if (isOutgoing) ...[
            const SizedBox(width: 8),
            _buildBusinessAvatar(context),
          ],
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

  Widget _buildBusinessAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Icon(
        Icons.business,
        size: 16,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOutgoing ? Theme.of(context).primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: isOutgoing ? const Radius.circular(4) : const Radius.circular(18),
          bottomLeft: !isOutgoing ? const Radius.circular(4) : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageContent(context),
          const SizedBox(height: 4),
          _buildTimestamp(context),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        controller.getMessageTypeIcon(messageType),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            message,
            style: TextStyle(
              color: isOutgoing ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        if (_isCustomerResponse() && !isOutgoing) ...[
          const SizedBox(width: 8),
          _buildEditButton(context),
        ],
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return InkWell(
      onTap: () => _showEditResponseDialog(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.edit,
          size: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Text(
      formatCommunicationDate(timestamp),
      style: TextStyle(
        color: isOutgoing ? Colors.white70 : Colors.grey[600],
        fontSize: 11,
      ),
    );
  }

  bool _isCustomerResponse() {
    return controller.isCustomerResponse(message);
  }

  void _showEditResponseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditResponseDialog(
        originalMessage: message,
        timestamp: timestamp,
        customer: customer,
        controller: controller,
      ),
    );
  }
}