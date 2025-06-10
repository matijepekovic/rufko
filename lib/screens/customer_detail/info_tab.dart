import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/common_utils.dart';
import 'project_notes_section.dart';

class InfoTab extends StatefulWidget {
  final Customer customer;
  final String Function(String timestamp) formatDate;
  final VoidCallback onTemplateEmail;
  final VoidCallback onTemplateSMS;
  final VoidCallback onQuickCommunication;
  final VoidCallback onAddCommunication;

  const InfoTab({
    super.key,
    required this.customer,
    required this.formatDate,
    required this.onTemplateEmail,
    required this.onTemplateSMS,
    required this.onQuickCommunication,
    required this.onAddCommunication,
  });

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {

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
                              widget.customer.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Customer since ${DateFormat('MMM yyyy').format(widget.customer.createdAt)}',
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
                  _buildInfoRow(context, Icons.phone_outlined, 'Phone', widget.customer.phone ?? 'Not provided'),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, Icons.email_outlined, 'Email', widget.customer.email ?? 'Not provided'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.location_on_outlined,
                    'Address',
                    widget.customer.fullDisplayAddress.isNotEmpty &&
                            widget.customer.fullDisplayAddress != 'No address provided'
                        ? widget.customer.fullDisplayAddress
                        : 'Not provided',
                  ),
                  if (widget.customer.notes != null && widget.customer.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.note_outlined, 'Notes', widget.customer.notes!),
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
                            onPressed: _addProjectNote,
                            tooltip: 'Add Project Note',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProjectNotesSection(
                    customer: widget.customer,
                    onEditNote: _editProjectNote,
                    formatDate: widget.formatDate,
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
                            onPressed: widget.onTemplateEmail,
                            tooltip: 'Send Template Email',
                          ),
                          IconButton(
                            icon: const Icon(Icons.sms_outlined),
                            onPressed: widget.onTemplateSMS,
                            tooltip: 'Send Template SMS',
                          ),
                          IconButton(
                            icon: const Icon(Icons.flash_on),
                            onPressed: widget.onQuickCommunication,
                            tooltip: 'Quick Communication',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_comment_outlined),
                            onPressed: widget.onAddCommunication,
                            tooltip: 'Add Communication',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildChatStyleCommunicationHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Communication history and dialogs
  Widget _buildChatStyleCommunicationHistory() {
    if (widget.customer.communicationHistory.isEmpty) {
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

    final communications = widget.customer.communicationHistory.reversed.toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: communications.length,
        itemBuilder: (context, index) {
          final entry = communications[index];
          final parts = entry.split(': ');
          final timestamp = parts.isNotEmpty ? parts[0] : '';
          final message = parts.length > 1 ? parts.sublist(1).join(': ') : entry;

          final isOutgoing = _isOutgoingMessage(message);
          final messageType = _getMessageType(message);
          final cleanMessage = _cleanMessage(message);

          return _buildChatBubble(
            message: cleanMessage,
            timestamp: timestamp,
            isOutgoing: isOutgoing,
            messageType: messageType,
          );
        },
      ),
    );
  }

  Widget _buildChatBubble({
    required String message,
    required String timestamp,
    required bool isOutgoing,
    required String messageType,
  }) {
    final isOpenedMessage = message.toLowerCase().contains('opened sms to') ||
        message.toLowerCase().contains('opened email to');

    if (isOpenedMessage) {
      final hasResponse = _hasCustomerResponseAfter(timestamp);
      if (hasResponse) {
        return const SizedBox.shrink();
      } else {
        return _buildAddResponseCard(message, timestamp, messageType);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOutgoing) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.customer.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getMessageTypeIcon(messageType),
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
                      if (_isCustomerResponse(message) && !isOutgoing) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _editCustomerResponse(message, timestamp),
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
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCommunicationDate(timestamp),
                    style: TextStyle(
                      color: isOutgoing ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOutgoing) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.business,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddResponseCard(String originalMessage, String timestamp, String messageType) {
    String contactMethod = '';
    if (originalMessage.toLowerCase().contains('opened sms to')) {
      final phoneMatch = RegExp(r'(\d{10,})').firstMatch(originalMessage);
      contactMethod = phoneMatch?.group(1) ?? widget.customer.phone ?? '';
    } else if (originalMessage.toLowerCase().contains('opened email to')) {
      final emailMatch = RegExp(r'([^\s]+@[^\s]+)').firstMatch(originalMessage);
      contactMethod = emailMatch?.group(1) ?? widget.customer.email ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              widget.customer.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _showAddResponseDialog(messageType, contactMethod),
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
                      Row(
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
                      ),
                      const SizedBox(height: 8),
                      Container(
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
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCommunicationDate(timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResponseDialog(String messageType, String contactMethod) {
    final responseController = TextEditingController();
    String responseType = 'text'; // Default response type

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_comment, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Customer Response',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Manually log ${ widget.customer.name}\'s response',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Response Type Selector
                        Text(
                          'Response Method:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'text',
                              label: Text(messageType == 'sms' ? 'SMS Reply' : 'Text Reply'),
                              icon: Icon(messageType == 'sms' ? Icons.sms : Icons.message),
                            ),
                            const ButtonSegment(
                              value: 'call',
                              label: Text('Phone Call'),
                              icon: Icon(Icons.phone),
                            ),
                            const ButtonSegment(
                              value: 'email',
                              label: Text('Email Reply'),
                              icon: Icon(Icons.email),
                            ),
                          ],
                          selected: {responseType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              responseType = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Response Content
                        Text(
                          'Customer Response:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: responseController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: _getResponseHint(responseType),
                            prefixIcon: Icon(_getResponseIcon(responseType)),
                            alignLabelWithHint: true,
                          ),
                          maxLines: responseType == 'call' ? 3 : 4,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                        const SizedBox(height: 16),

                        // Quick Response Templates
                        Text(
                          'Quick Responses:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _getQuickResponses(responseType).map((response) {
                            return ActionChip(
                              label: Text(response),
                              onPressed: () {
                                responseController.text = response;
                              },
                              backgroundColor: Colors.grey[100],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final response = responseController.text.trim();
                          if (response.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a response'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Add the customer response to communication history
                          widget.customer.addCommunication(
                            'Customer responded via $responseType: $response',
                            type: responseType,
                          );

                          context.read<AppStateProvider>().updateCustomer(widget.customer);
                          setState(() {});

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer response logged successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Log Response'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getResponseHint(String responseType) {
    switch (responseType) {
      case 'call':
        return 'What did the customer say during the call?';
      case 'email':
        return 'Copy/paste the customer\'s email response...';
      case 'text':
      default:
        return 'Copy/paste the customer\'s text message...';
    }
  }

  IconData _getResponseIcon(String responseType) {
    switch (responseType) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'text':
      default:
        return Icons.sms;
    }
  }

  List<String> _getQuickResponses(String responseType) {
    switch (responseType) {
      case 'call':
        return [
          'Interested, wants to schedule appointment',
          'Needs to think about it',
          'Price is too high',
          'Not interested at this time',
          'Wants to compare with other quotes',
        ];
      case 'email':
        return [
          'Thanks for the quote!',
          'When can you start?',
          'Can you adjust the price?',
          'I need to discuss with my spouse',
          'Looks good, let\'s proceed',
        ];
      case 'text':
      default:
        return [
          'Yes, sounds good!',
          'Thanks!',
          'When can you start?',
          'Let me think about it',
          'Call me',
          'Too expensive',
        ];
    }
  }

  bool _hasCustomerResponseAfter(String originalTimestamp) {
    try {
      final originalDateTime = DateTime.parse(originalTimestamp);

      for (final entry in widget.customer.communicationHistory) {
        final parts = entry.split(': ');
        if (parts.length < 2) continue;

        final entryTimestamp = parts[0];
        final entryMessage = parts.sublist(1).join(': ');

        try {
          final entryDateTime = DateTime.parse(entryTimestamp);

          if (entryDateTime.isAfter(originalDateTime)) {
            if (entryMessage.toLowerCase().contains('customer responded via') ||
                entryMessage.toLowerCase().contains('customer replied') ||
                entryMessage.toLowerCase().contains('customer said')) {
              return true;
            }
          }
        } catch (_) {
          continue;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  bool _isOutgoingMessage(String message) {
    if (message.toLowerCase().contains('opened sms to') ||
        message.toLowerCase().contains('opened email to')) {
      return false;
    }

    final outgoingKeywords = [
      'sent',
      'delivered',
      'provided',
      'scheduled',
      'completed',
      'quote',
      'invoice',
      'template'
    ];
    final lowerMessage = message.toLowerCase();
    return outgoingKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  String _getMessageType(String message) {
    if (message.contains('📞')) return 'call';
    if (message.contains('📧')) return 'email';
    if (message.contains('💬')) return 'sms';
    if (message.contains('🤝')) return 'meeting';
    if (message.contains('🏠')) return 'site_visit';
    if (message.contains('📅')) return 'follow_up';
    return 'note';
  }

  bool _isCustomerResponse(String message) {
    return message.toLowerCase().contains('customer responded via') ||
        message.toLowerCase().contains('customer replied') ||
        message.toLowerCase().contains('customer said');
  }

  void _editCustomerResponse(String originalMessage, String timestamp) {
    String responseType = 'text';
    String responseContent = '';

    try {
      final parts = originalMessage.split(': ');
      if (parts.length >= 2) {
        final firstPart = parts[0].toLowerCase();
        responseContent = parts.sublist(1).join(': ');

        if (firstPart.contains('via call')) {
          responseType = 'call';
        } else if (firstPart.contains('via email')) {
          responseType = 'email';
        } else {
          responseType = 'text';
        }
      }
    } catch (_) {
      responseContent = originalMessage;
    }

    final responseController = TextEditingController(text: responseContent);
    String editedResponseType = responseType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Customer Response',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Modify ${widget.customer.name}\'s logged response',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response Method:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'text', label: Text('Text/SMS'), icon: Icon(Icons.sms)),
                            ButtonSegment(value: 'call', label: Text('Phone Call'), icon: Icon(Icons.phone)),
                            ButtonSegment(value: 'email', label: Text('Email Reply'), icon: Icon(Icons.email)),
                          ],
                          selected: {editedResponseType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              editedResponseType = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Customer Response:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: responseController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: _getResponseHint(editedResponseType),
                            prefixIcon: Icon(_getResponseIcon(editedResponseType)),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final editedResponse = responseController.text.trim();
                          if (editedResponse.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Response cannot be empty'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          _updateCustomerResponse(
                            originalMessage,
                            timestamp,
                            editedResponseType,
                            editedResponse,
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Update Response'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateCustomerResponse(String originalMessage, String timestamp, String newResponseType, String newResponse) {
    try {
      final communicationHistory = widget.customer.communicationHistory;

      for (int i = 0; i < communicationHistory.length; i++) {
        final entry = communicationHistory[i];
        final parts = entry.split(': ');

        if (parts.isNotEmpty && parts[0] == timestamp) {
          final newMessage = 'Customer responded via $newResponseType: $newResponse';
          final updatedEntry = '$timestamp: $newMessage';

          communicationHistory[i] = updatedEntry;

          context.read<AppStateProvider>().updateCustomer(widget.customer);
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer response updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find the original response to update'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addProjectNote() {
    final noteController = TextEditingController();
    String noteType = 'note';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_task, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Project Note',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Record meetings, site visits, and project details',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note Type:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'note', label: Text('General'), icon: Icon(Icons.note)),
                            ButtonSegment(value: 'meeting', label: Text('Meeting'), icon: Icon(Icons.group)),
                            ButtonSegment(value: 'site_visit', label: Text('Site Visit'), icon: Icon(Icons.home_work)),
                          ],
                          selected: {noteType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              noteType = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Note Content:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: noteController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: _getProjectNoteHint(noteType),
                            prefixIcon: Icon(_getProjectNoteIcon(noteType)),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quick Templates:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _getProjectNoteTemplates(noteType).map((template) {
                            return ActionChip(
                              label: Text(template),
                              onPressed: () {
                                noteController.text = template;
                              },
                              backgroundColor: Colors.grey[100],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
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

                          widget.customer.addCommunication(
                            'PROJECT_NOTE: $noteContent',
                            type: 'note',
                          );

                          context.read<AppStateProvider>().updateCustomer(widget.customer);
                          setState(() {});

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Project note added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Add Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void _editProjectNote(String originalEntry, String timestamp) {
    final parts = originalEntry.split(': ');
    String noteContent = '';
    String noteType = 'note';

    if (parts.length > 1) {
      final fullNote = parts.sublist(1).join(': ');
      noteContent = fullNote.replaceFirst('PROJECT_NOTE: ', '');

      if (noteContent.toLowerCase().contains('meeting')) {
        noteType = 'meeting';
      } else if (noteContent.toLowerCase().contains('site visit')) {
        noteType = 'site_visit';
      } else {
        noteType = 'note';
      }
    }

    final noteController = TextEditingController(text: noteContent);
    String editedNoteType = noteType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Project Note',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Modify this project note',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note Type:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'note', label: Text('General'), icon: Icon(Icons.note)),
                            ButtonSegment(value: 'meeting', label: Text('Meeting'), icon: Icon(Icons.group)),
                            ButtonSegment(value: 'site_visit', label: Text('Site Visit'), icon: Icon(Icons.home_work)),
                          ],
                          selected: {editedNoteType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              editedNoteType = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Note Content:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: noteController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: _getProjectNoteHint(editedNoteType),
                            prefixIcon: Icon(_getProjectNoteIcon(editedNoteType)),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final editedContent = noteController.text.trim();
                          if (editedContent.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Note content cannot be empty'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          _updateProjectNote(originalEntry, timestamp, editedContent);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Update Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateProjectNote(String originalEntry, String timestamp, String newContent) {
    try {
      final communicationHistory = widget.customer.communicationHistory;

      for (int i = 0; i < communicationHistory.length; i++) {
        final entry = communicationHistory[i];

        if (entry == originalEntry) {
          final updatedEntry = '$timestamp: PROJECT_NOTE: $newContent';

          communicationHistory[i] = updatedEntry;

          context.read<AppStateProvider>().updateCustomer(widget.customer);
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project note updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find the original note to update'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _cleanMessage(String message) {
    try {
      String cleanedMessage = message
          .replaceAll(RegExp(r'^[📞📧💬🤝🏠📅📝]\s*'), '')
          .replaceAll(RegExp(r'\[URGENT\]\s*'), '')
          .trim();

      cleanedMessage = _sanitizeString(cleanedMessage);

      return cleanedMessage.isEmpty ? 'Communication recorded' : cleanedMessage;
    } catch (_) {
      return 'Communication recorded';
    }
  }

  String _sanitizeString(String input) {
    try {
      final sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');

      final buffer = StringBuffer();
      for (int i = 0; i < sanitized.length; i++) {
        final char = sanitized[i];
        final code = char.codeUnitAt(0);

        if ((code >= 0x20 && code <= 0xD7FF) ||
            (code >= 0xE000 && code <= 0xFFFD) ||
            code == 0x09 || code == 0x0A || code == 0x0D) {
          buffer.write(char);
        } else {
          buffer.write(' ');
        }
      }

      return buffer.toString().trim();
    } catch (_) {
      return 'Text encoding error';
    }
  }

  Widget _getMessageTypeIcon(String messageType) {
    IconData icon;
    Color color;

    switch (messageType) {
      case 'call':
        icon = Icons.phone;
        color = Colors.green;
        break;
      case 'email':
        icon = Icons.email;
        color = Colors.blue;
        break;
      case 'sms':
        icon = Icons.sms;
        color = Colors.purple;
        break;
      case 'meeting':
        icon = Icons.handshake;
        color = Colors.orange;
        break;
      case 'site_visit':
        icon = Icons.home;
        color = Colors.brown;
        break;
      case 'follow_up':
        icon = Icons.schedule;
        color = Colors.amber;
        break;
      default:
        icon = Icons.note;
        color = Colors.grey;
    }

    return Icon(icon, size: 14, color: color);
  }
}
