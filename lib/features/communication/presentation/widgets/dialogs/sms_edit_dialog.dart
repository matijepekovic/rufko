import 'package:flutter/material.dart';

import '../../controllers/communication_dialog_controller.dart';
import 'sms_preview_dialog.dart';

class SmsEditDialog extends StatefulWidget {
  final CommunicationDialogController controller;
  const SmsEditDialog({super.key, required this.controller});

  @override
  State<SmsEditDialog> createState() => _SmsEditDialogState();
}

class _SmsEditDialogState extends State<SmsEditDialog> {
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController =
        TextEditingController(text: widget.controller.smsMessage);
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.controller.template;
    final customer = widget.controller.commController.customer;

    return Dialog(
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
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.purple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit SMS',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Template: ${template.templateName}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                              'To: ${customer.name} (${customer.phone ?? 'No phone'})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SMS Message:',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: messageController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: 'SMS message...',
                        prefixIcon: const Icon(Icons.sms),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: messageController.text.length > 160
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: messageController.text.length > 160
                              ? Colors.orange.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Characters: ${messageController.text.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: messageController.text.length > 160
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                              Text(
                                messageController.text.length <= 160
                                    ? '1 SMS'
                                    : '${(messageController.text.length / 160).ceil()} SMS',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: messageController.text.length > 160
                                      ? Colors.orange.shade600
                                      : Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                          if (messageController.text.length > 160) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Messages over 160 characters will be sent as multiple SMS',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Preview:',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(18).copyWith(
                              bottomRight: const Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            messageController.text.isEmpty
                                ? 'Your message will appear here...'
                                : messageController.text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontStyle: messageController.text.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
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
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.controller
                          .updateSmsMessage(messageController.text.trim());
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) =>
                            SmsPreviewDialog(controller: widget.controller),
                      );
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final editedMessage = messageController.text.trim();
                      if (editedMessage.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message cannot be empty'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      widget.controller.updateSmsMessage(editedMessage);
                      Navigator.pop(context);
                      widget.controller.sendSms();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
