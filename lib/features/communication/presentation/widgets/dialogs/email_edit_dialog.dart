import 'package:flutter/material.dart';

import '../../controllers/communication_dialog_controller.dart';
import 'email_preview_dialog.dart';

class EmailEditDialog extends StatefulWidget {
  final CommunicationDialogController controller;
  const EmailEditDialog({super.key, required this.controller});

  @override
  State<EmailEditDialog> createState() => _EmailEditDialogState();
}

class _EmailEditDialogState extends State<EmailEditDialog> {
  late TextEditingController subjectController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    subjectController =
        TextEditingController(text: widget.controller.emailSubject);
    contentController =
        TextEditingController(text: widget.controller.emailContent);
  }

  @override
  void dispose() {
    subjectController.dispose();
    contentController.dispose();
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
        constraints: const BoxConstraints(maxHeight: 700),
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
                  const Icon(Icons.edit, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Email',
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
                              'To: ${customer.name} (${customer.email ?? 'No email'})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Subject Line:',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: 'Email subject...',
                        prefixIcon: const Icon(Icons.subject),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Email Content:',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: contentController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        hintText: 'Email message...',
                        prefixIcon: const Icon(Icons.message),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${contentController.text.length} characters',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                          .updateEmailSubject(subjectController.text.trim());
                      widget.controller
                          .updateEmailContent(contentController.text.trim());
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) =>
                            EmailPreviewDialog(controller: widget.controller),
                      );
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final subj = subjectController.text.trim();
                      final cont = contentController.text.trim();
                      if (subj.isEmpty || cont.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Subject and content cannot be empty'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      widget.controller.updateEmailSubject(subj);
                      widget.controller.updateEmailContent(cont);
                      Navigator.pop(context);
                      widget.controller.sendEmail();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Email'),
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
    );
  }
}
