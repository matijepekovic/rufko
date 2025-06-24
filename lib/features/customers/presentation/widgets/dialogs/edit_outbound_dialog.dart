import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../shared/widgets/buttons/rufko_footer_action_bar.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../controllers/communication_history_controller.dart';

/// Dialog for editing outbound communications (SMS, calls)
class EditOutboundDialog extends StatefulWidget {
  final String originalMessage;
  final String timestamp;
  final Customer customer;
  final CommunicationHistoryController controller;

  const EditOutboundDialog({
    super.key,
    required this.originalMessage,
    required this.timestamp,
    required this.customer,
    required this.controller,
  });

  @override
  State<EditOutboundDialog> createState() => _EditOutboundDialogState();
}

class _EditOutboundDialogState extends State<EditOutboundDialog> {
  late final TextEditingController contentController;
  late String communicationType;

  @override
  void initState() {
    super.initState();
    
    // Parse existing message
    String content = '';
    final lowerMessage = widget.originalMessage.toLowerCase();
    
    if (lowerMessage.contains('quick sms sent:')) {
      communicationType = 'sms';
      // Extract SMS content after "Quick SMS sent: "
      final startIndex = widget.originalMessage.indexOf('Quick SMS sent:') + 'Quick SMS sent:'.length;
      content = widget.originalMessage.substring(startIndex).trim();
    } else if (lowerMessage.contains('outbound call to')) {
      communicationType = 'call';
      // For calls, we'll allow editing the call summary/notes
      content = 'Call summary';
    } else {
      communicationType = 'note';
      content = widget.originalMessage;
    }

    contentController = TextEditingController(text: content);
  }

  @override
  void dispose() {
    contentController.dispose();
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
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  communicationType == 'sms' 
                      ? 'Edit SMS Message' 
                      : 'Edit Call Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Modify the outbound communication details',
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
            _buildTypeInfo(),
            const SizedBox(height: 20),
            _buildContentField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            communicationType == 'sms' ? Icons.sms : Icons.phone,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            communicationType == 'sms' 
                ? 'SMS to ${widget.customer.phone ?? 'customer'}'
                : 'Call to ${widget.customer.name}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          communicationType == 'sms' ? 'Message Content:' : 'Call Summary:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: contentController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: communicationType == 'sms' 
                ? 'Enter the SMS message content...'
                : 'Enter call summary or notes...',
            prefixIcon: Icon(communicationType == 'sms' ? Icons.message : Icons.note),
            alignLabelWithHint: true,
          ),
          maxLines: communicationType == 'sms' ? 4 : 3,
          textAlignVertical: TextAlignVertical.top,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return RufkoFooterActionBar(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        RufkoSecondaryButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        RufkoPrimaryButton(
          onPressed: _handleUpdateOutbound,
          icon: Icons.save,
          child: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _handleUpdateOutbound() async {
    final editedContent = contentController.text.trim();
    if (editedContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update the communication entry
      final updatedMessage = communicationType == 'sms'
          ? 'Quick SMS sent: $editedContent'
          : 'Outbound call to ${widget.customer.name}';

      await widget.controller.updateOutboundCommunication(
        widget.originalMessage,
        widget.timestamp,
        updatedMessage,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Communication updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating communication: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}