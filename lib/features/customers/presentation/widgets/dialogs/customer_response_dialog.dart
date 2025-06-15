import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../controllers/communication_history_controller.dart';

/// Dialog for adding customer responses
/// Extracted from InfoTab to create reusable component
class CustomerResponseDialog extends StatefulWidget {
  final String messageType;
  final String contactMethod;
  final Customer customer;
  final CommunicationHistoryController controller;

  const CustomerResponseDialog({
    super.key,
    required this.messageType,
    required this.contactMethod,
    required this.customer,
    required this.controller,
  });

  @override
  State<CustomerResponseDialog> createState() => _CustomerResponseDialogState();
}

class _CustomerResponseDialogState extends State<CustomerResponseDialog> {
  late final TextEditingController responseController;
  String responseType = 'text';

  @override
  void initState() {
    super.initState();
    responseController = TextEditingController();
    responseType = widget.messageType == 'sms' ? 'text' : 'text';
  }

  @override
  void dispose() {
    responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          const Icon(Icons.add_comment, color: Colors.green, size: 28),
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
                  'Manually log ${widget.customer.name}\'s response',
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
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResponseTypeSelector(),
            const SizedBox(height: 20),
            _buildResponseContentField(),
            const SizedBox(height: 16),
            _buildQuickResponseTemplates(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTypeSelector() {
    return Column(
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
          segments: [
            ButtonSegment(
              value: 'text',
              label: Text(widget.messageType == 'sms' ? 'SMS Reply' : 'Text Reply'),
              icon: Icon(widget.messageType == 'sms' ? Icons.sms : Icons.message),
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
      ],
    );
  }

  Widget _buildResponseContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildQuickResponseTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  Widget _buildFooter() {
    return Container(
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
            onPressed: _handleSaveResponse,
            icon: const Icon(Icons.save),
            label: const Text('Log Response'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveResponse() async {
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

    try {
      await widget.controller.addCustomerResponse(responseType, response);
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer response logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
}