import 'package:flutter/material.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../app/theme/rufko_theme.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../controllers/communication_history_controller.dart';
import '../../controllers/email_dialog_controller.dart';

/// Material 3 fullscreen email composition dialog
/// Pure UI component with separated business logic
class EmailCompositionDialog extends StatefulWidget {
  final Customer customer;
  final CommunicationHistoryController communicationController;
  final bool isReply;
  final String? replyToThreadSubject;
  final String? initialPdfAttachment; // NEW: Initial PDF file path to attach
  final String? initialSubject; // NEW: Pre-filled subject line

  const EmailCompositionDialog({
    super.key,
    required this.customer,
    required this.communicationController,
    this.isReply = false,
    this.replyToThreadSubject,
    this.initialPdfAttachment, // NEW: Optional PDF attachment
    this.initialSubject, // NEW: Optional initial subject
  });

  @override
  State<EmailCompositionDialog> createState() => _EmailCompositionDialogState();
}

class _EmailCompositionDialogState extends State<EmailCompositionDialog> {
  late EmailDialogController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EmailDialogController(
      customer: widget.customer,
      context: context,
      communicationController: widget.communicationController,
      isReply: widget.isReply,
      replyToThreadSubject: widget.replyToThreadSubject,
      initialPdfAttachment: widget.initialPdfAttachment, // NEW: Pass PDF attachment
      initialSubject: widget.initialSubject, // NEW: Pass initial subject
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= 600;
    
    if (isTabletOrDesktop) {
      return _buildTabletDesktopDialog(context);
    } else {
      return _buildMobileFullscreenDialog(context);
    }
  }
  
  Widget _buildMobileFullscreenDialog(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildMobileAppBar(context),
      body: _buildDialogContent(context),
      resizeToAvoidBottomInset: true,
    );
  }
  
  Widget _buildTabletDesktopDialog(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildDesktopAppBar(context),
        body: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildDialogContent(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isReply ? 'Reply to Email' : 'Compose Email',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            widget.customer.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return TextButton(
              onPressed: _controller.canSend ? _handleSendEmail : null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _controller.compositionController.isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
  
  PreferredSizeWidget _buildDesktopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: Row(
        children: [
          Icon(
            widget.isReply ? Icons.reply : Icons.email,
            color: RufkoTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isReply ? 'Reply to Email' : 'Compose Email',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Send email to ${widget.customer.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        RufkoSecondaryButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return RufkoPrimaryButton(
              onPressed: _controller.canSend ? _handleSendEmail : null,
              icon: _controller.compositionController.isSending 
                  ? Icons.hourglass_empty
                  : Icons.send,
              child: Text(_controller.compositionController.isSending ? 'Sending...' : 'Send Email'),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (_controller.errorMessage != null || _controller.compositionController.errorMessage != null) 
                _buildErrorCard(),
              if (_controller.errorMessage != null || _controller.compositionController.errorMessage != null)
                const SizedBox(height: 24),

              // Template selection for new emails
              if (!widget.isReply) ..._buildTemplateSection(),

              // Email fields
              _buildToField(),
              const SizedBox(height: 24),
              _buildSubjectField(),
              const SizedBox(height: 24),
              _buildBodyField(),
              const SizedBox(height: 24),
              
              // Attachments section
              _buildAttachmentsSection(),
              
              // Add bottom padding for mobile keyboard
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildErrorCard() {
    final errorMessage = _controller.errorMessage ?? _controller.compositionController.errorMessage;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildTemplateSection() {
    return [
      Text(
        'Email Template',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: RufkoTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<dynamic>(
            value: _controller.compositionController.selectedTemplate,
            decoration: InputDecoration(
              labelText: 'Select template (optional)',
              prefixIcon: const Icon(Icons.article_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Custom Email (No Template)'),
              ),
              ..._controller.compositionController.availableTemplates.map((template) {
                return DropdownMenuItem(
                  value: template,
                  child: Text(template.templateName ?? 'Unnamed Template'),
                );
              }),
            ],
            onChanged: _controller.compositionController.isLoading 
                ? null 
                : _controller.selectTemplate,
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }


  Widget _buildToField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'To',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: RufkoTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: RufkoTheme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: RufkoTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.customer.email ?? 'No email address',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.customer.email == null || widget.customer.email!.isEmpty)
                  Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error,
                  ),
              ],
            ),
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
          'Subject',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: RufkoTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controller.subjectController,
          decoration: InputDecoration(
            labelText: widget.isReply ? 'Reply Subject' : 'Email Subject',
            hintText: widget.isReply 
                ? 'Auto-generated from original subject' 
                : 'Enter a clear subject line...',
            prefixIcon: const Icon(Icons.subject),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: _controller.updateSubject,
          readOnly: widget.isReply,
        ),
        if (widget.isReply)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reply subject is automatically generated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBodyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: RufkoTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controller.bodyController,
          decoration: InputDecoration(
            labelText: 'Email Content',
            hintText: 'Type your email message here...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 120),
              child: Icon(Icons.message),
            ),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: 12,
          minLines: 6,
          textAlignVertical: TextAlignVertical.top,
          onChanged: _controller.updateBody,
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: RufkoTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Attachment action cards
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: InkWell(
                  onTap: _controller.attachFiles,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_file,
                          color: RufkoTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Browse Files',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: InkWell(
                  onTap: _showCustomerDataDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_special,
                          color: RufkoTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Customer Files',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
        const SizedBox(height: 16),
        
        // Attachment status display
        _buildAttachmentStatus(),
      ],
    );
  }
  
  Widget _buildAttachmentStatus() {
    if (!_controller.hasAttachments) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.attach_file_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                'No attachments selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 0,
      color: RufkoTheme.primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: RufkoTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_controller.totalAttachmentCount} file${_controller.totalAttachmentCount == 1 ? '' : 's'} selected',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: RufkoTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                RufkoTextButton(
                  onPressed: _controller.clearAllAttachments,
                  size: ButtonSize.small,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            if (_controller.fileAttachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Files: ${_controller.fileAttachments.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: RufkoTheme.primaryColor,
                ),
              ),
            ],
            if (_controller.selectedQuoteAttachments.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Quote PDFs: ${_controller.selectedQuoteAttachments.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: RufkoTheme.primaryColor,
                ),
              ),
            ],
            if (_controller.selectedMediaAttachments.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Media Files: ${_controller.selectedMediaAttachments.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: RufkoTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  void _showCustomerDataDialog() async {
    final customerData = _controller.getCustomerDataForAttachment();
    final customerQuotes = customerData['quotes'] as List;
    final customerMedia = customerData['media'] as List;
    
    if (customerQuotes.isEmpty && customerMedia.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customer documents or media found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer Files'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (customerQuotes.isNotEmpty) ...[
                Text(
                  'Quote PDFs',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: RufkoTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...customerQuotes.map((quote) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(quote.quoteNumber ?? 'Unknown Quote'),
                  subtitle: Text(quote.levels.isNotEmpty ? quote.levels.first.name : 'No Level'),
                  onTap: () {
                    _controller.addQuoteAttachment(quote.id);
                    Navigator.pop(context);
                  },
                )),
                const SizedBox(height: 16),
              ],
              if (customerMedia.isNotEmpty) ...[
                Text(
                  'Project Media',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: RufkoTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...customerMedia.map((media) => ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(media.fileName),
                  onTap: () {
                    _controller.addMediaAttachment(media.id);
                    Navigator.pop(context);
                  },
                )),
              ],
            ],
          ),
        ),
        actions: [
          RufkoTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendEmail() async {
    final success = await _controller.sendEmail();
    
    if (success && mounted) {
      Navigator.pop(context);
      
      final message = _controller.generateSuccessMessage();
      final hasAttachments = _controller.hasAttachments;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: hasAttachments ? 6 : 3),
        ),
      );
    }
  }
}