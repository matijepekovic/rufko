import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../controllers/communication_history_controller.dart';

/// Dialog for editing existing customer responses
/// Extracted from InfoTab to create reusable component
class EditResponseDialog extends StatefulWidget {
  final String originalMessage;
  final String timestamp;
  final Customer customer;
  final CommunicationHistoryController controller;

  const EditResponseDialog({
    super.key,
    required this.originalMessage,
    required this.timestamp,
    required this.customer,
    required this.controller,
  });

  @override
  State<EditResponseDialog> createState() => _EditResponseDialogState();
}

class _EditResponseDialogState extends State<EditResponseDialog> {
  late final TextEditingController responseController;
  late String editedResponseType;

  @override
  void initState() {
    super.initState();
    
    // Parse existing response
    String responseType = 'text';
    String responseContent = '';

    try {
      final parts = widget.originalMessage.split(': ');
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
      responseContent = widget.originalMessage;
    }

    responseController = TextEditingController(text: responseContent);
    editedResponseType = responseType;
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
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.blue, size: 28),
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
          segments: const [
            ButtonSegment(
              value: 'text',
              label: Text('Text/SMS'),
              icon: Icon(Icons.sms),
            ),
            ButtonSegment(
              value: 'call',
              label: Text('Phone Call'),
              icon: Icon(Icons.phone),
            ),
            ButtonSegment(
              value: 'email',
              label: Text('Email Reply'),
              icon: Icon(Icons.email),
            ),
          ],
          selected: {editedResponseType},
          onSelectionChanged: (selection) {
            setState(() {
              editedResponseType = selection.first;
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
            hintText: _getResponseHint(editedResponseType),
            prefixIcon: Icon(_getResponseIcon(editedResponseType)),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textAlignVertical: TextAlignVertical.top,
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
            onPressed: _handleUpdateResponse,
            icon: const Icon(Icons.save),
            label: const Text('Update Response'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateResponse() async {
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

    try {
      await widget.controller.updateCustomerResponse(
        widget.originalMessage,
        widget.timestamp,
        editedResponseType,
        editedResponse,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer response updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating response: $e'),
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
}