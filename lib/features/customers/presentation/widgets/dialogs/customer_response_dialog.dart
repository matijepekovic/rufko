import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../shared/widgets/buttons/rufko_dialog_actions.dart';
import '../../controllers/communication_history_controller.dart';

/// Dialog for adding customer responses
/// Extracted from InfoTab to create reusable component
class CustomerResponseDialog extends StatefulWidget {
  final String messageType;
  final String contactMethod;
  final Customer customer;
  final CommunicationHistoryController controller;
  final String? replyToSubject;

  const CustomerResponseDialog({
    super.key,
    required this.messageType,
    required this.contactMethod,
    required this.customer,
    required this.controller,
    this.replyToSubject,
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
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          margin: const EdgeInsets.only(top: 60),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResponseTypeSelector(),
                      const SizedBox(height: 20),
                      _buildResponseContentField(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.add_comment, 
                color: Theme.of(context).colorScheme.primary, 
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Customer Response',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Manually log ${widget.customer.name}\'s response',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RufkoDialogActions(
            onCancel: () => Navigator.pop(context),
            onConfirm: _handleSaveResponse,
            confirmText: 'Log Response',
          ),
        ],
      ),
    );
  }


  Widget _buildResponseTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Response Method:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
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
            // Remove email option for messages & calls
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
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: responseController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: _getResponseHint(responseType),
            prefixIcon: Icon(_getResponseIcon(responseType)),
            alignLabelWithHint: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: responseType == 'call' ? 3 : 4,
          textAlignVertical: TextAlignVertical.top,
        ),
      ],
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

}