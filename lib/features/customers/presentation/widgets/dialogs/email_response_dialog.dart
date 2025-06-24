import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../controllers/communication_history_controller.dart';

/// Dialog for adding email responses with threading support
class EmailResponseDialog extends StatefulWidget {
  final Customer customer;
  final CommunicationHistoryController controller;
  final String? replyToSubject;

  const EmailResponseDialog({
    super.key,
    required this.customer,
    required this.controller,
    this.replyToSubject,
  });

  @override
  State<EmailResponseDialog> createState() => _EmailResponseDialogState();
}

class _EmailResponseDialogState extends State<EmailResponseDialog> {
  late final TextEditingController subjectController;
  late final TextEditingController responseController;
  bool isReply = false;
  String? selectedThreadSubject;
  List<Map<String, dynamic>> availableThreads = [];

  @override
  void initState() {
    super.initState();
    responseController = TextEditingController();
    
    // Get available email threads - do this safely
    try {
      availableThreads = widget.controller.groupEmailsByThread();
    } catch (e) {
      availableThreads = [];
    }
    
    // Initialize as reply if we have a subject to reply to
    if (widget.replyToSubject != null && widget.replyToSubject!.isNotEmpty) {
      isReply = true;
      selectedThreadSubject = widget.replyToSubject!;
      subjectController = TextEditingController(text: widget.replyToSubject!);
    } else if (availableThreads.isNotEmpty) {
      // Default to most recent thread for convenience
      selectedThreadSubject = availableThreads.first['subject'] as String;
      subjectController = TextEditingController(text: selectedThreadSubject!);
    } else {
      subjectController = TextEditingController();
    }
  }

  @override
  void dispose() {
    responseController.dispose();
    subjectController.dispose();
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
                child: _buildContent(),
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
                Icons.email, 
                color: Theme.of(context).colorScheme.primary, 
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Email Response',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Log ${widget.customer.name}\'s email response',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RufkoSecondaryButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              RufkoPrimaryButton(
                onPressed: _handleSaveResponse,
                icon: Icons.save,
                child: const Text('Log Email'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmailTypeSelector(),
          const SizedBox(height: 20),
          if (isReply && availableThreads.isNotEmpty) ...[
            _buildThreadSelector(),
            const SizedBox(height: 20),
          ],
          if (!isReply || availableThreads.isEmpty) ...[
            _buildSubjectField(),
            const SizedBox(height: 20),
          ],
          _buildResponseContentField(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmailTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Type:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              label: const Text('Reply to Thread'),
              icon: const Icon(Icons.reply),
              enabled: availableThreads.isNotEmpty,
            ),
            const ButtonSegment(
              value: false,
              label: Text('New Email'),
              icon: Icon(Icons.add),
            ),
          ],
          selected: {isReply},
          onSelectionChanged: (selection) {
            setState(() {
              isReply = selection.first;
              if (isReply && selectedThreadSubject != null) {
                subjectController.text = selectedThreadSubject!;
              } else {
                subjectController.clear();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildThreadSelector() {
    if (availableThreads.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Thread to Reply To:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: availableThreads.any((thread) => thread['subject'] == selectedThreadSubject) 
                ? selectedThreadSubject 
                : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.forum),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            isExpanded: true,
            menuMaxHeight: 200,
            items: availableThreads.map((thread) {
              final subject = thread['subject'] as String;
              final messageCount = thread['messageCount'] as int;
              return DropdownMenuItem(
                value: subject,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$messageCount',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedThreadSubject = value;
                  subjectController.text = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: subjectController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: isReply 
                ? 'Reply subject (auto-filled)' 
                : 'Enter email subject...',
            prefixIcon: Icon(isReply ? Icons.reply : Icons.subject),
            enabled: !isReply,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
        if (isReply && widget.replyToSubject != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'This will be added to the existing conversation thread',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResponseContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Content:',
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
            hintText: 'Enter the customer\'s email content...',
            prefixIcon: const Icon(Icons.message),
            alignLabelWithHint: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 4,
          textAlignVertical: TextAlignVertical.top,
        ),
      ],
    );
  }



  Future<void> _handleSaveResponse() async {
    final subject = subjectController.text.trim();
    final content = responseController.text.trim();
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isReply && subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a subject for new emails'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      String emailResponse;
      
      if (isReply && selectedThreadSubject != null) {
        // Reply to selected thread
        emailResponse = 'Subject: Re: $selectedThreadSubject\n$content';
      } else {
        // New email thread
        emailResponse = 'Subject: $subject\n$content';
      }

      await widget.controller.addCustomerResponse('email', emailResponse);
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email response logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}