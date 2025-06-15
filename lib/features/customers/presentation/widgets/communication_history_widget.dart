import 'package:flutter/material.dart';

import '../../../../data/models/business/customer.dart';
import '../controllers/communication_history_controller.dart';
import '../utils/communication_utils.dart';
import 'add_response_card_widget.dart';
import 'chat_bubble_widget.dart';

/// Widget for displaying chat-style communication history
/// Extracted from InfoTab to create reusable component
class CommunicationHistoryWidget extends StatefulWidget {
  final Customer customer;
  final CommunicationHistoryController controller;

  const CommunicationHistoryWidget({
    super.key,
    required this.customer,
    required this.controller,
  });

  @override
  State<CommunicationHistoryWidget> createState() => _CommunicationHistoryWidgetState();
}

class _CommunicationHistoryWidgetState extends State<CommunicationHistoryWidget> {

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customer.communicationHistory.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCommunicationList();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.chat_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No communication history yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your customer',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationList() {
    final communications = widget.controller.getSortedCommunications();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: communications.length,
        itemBuilder: (context, index) {
          return _buildCommunicationItem(communications[index]);
        },
      ),
    );
  }

  Widget _buildCommunicationItem(String entry) {
    final timestamp = CommunicationUtils.parseTimestamp(entry);
    final message = CommunicationUtils.parseMessage(entry);

    final isOutgoing = widget.controller.isOutgoingMessage(message);
    final messageType = widget.controller.getMessageType(message);
    final cleanMessage = widget.controller.cleanMessage(message);

    // Check if this is an "opened" message that needs a response card
    final isOpenedMessage = CommunicationUtils.isOpenedMessage(message);
    
    if (isOpenedMessage) {
      final hasResponse = widget.controller.hasCustomerResponseAfter(timestamp);
      if (hasResponse) {
        return const SizedBox.shrink();
      } else {
        return AddResponseCardWidget(
          originalMessage: message,
          timestamp: timestamp,
          messageType: messageType,
          customer: widget.customer,
          controller: widget.controller,
        );
      }
    }

    // Regular chat bubble
    return ChatBubbleWidget(
      message: cleanMessage,
      timestamp: timestamp,
      isOutgoing: isOutgoing,
      messageType: messageType,
      customer: widget.customer,
      controller: widget.controller,
    );
  }
}