import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../data/models/business/customer.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../core/services/communication/communication_service.dart';
import '../communication_history_widget.dart';
import '../../controllers/communication_history_controller.dart';
import '../dialogs/customer_response_dialog.dart';
import '../dialogs/email_response_dialog.dart';
import '../dialogs/email_composition_dialog.dart';
import '../email_thread_card.dart';
import '../email_thread_detail_view.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

/// Communications tab that contains the actual communication logic moved from InfoTab
/// This replaces the communication section that was previously in InfoTab
class CommunicationsTab extends StatefulWidget {
  final Customer customer;
  final String Function(String timestamp) formatDate;
  final VoidCallback onTemplateEmail;
  final VoidCallback onTemplateSMS;
  final VoidCallback onQuickCommunication;
  final VoidCallback onAddCommunication;

  const CommunicationsTab({
    super.key,
    required this.customer,
    required this.formatDate,
    required this.onTemplateEmail,
    required this.onTemplateSMS,
    required this.onQuickCommunication,
    required this.onAddCommunication,
  });

  @override
  State<CommunicationsTab> createState() => _CommunicationsTabState();
}

class _CommunicationsTabState extends State<CommunicationsTab> {
  late CommunicationHistoryController _communicationController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _activeType = 'messages'; // 'messages' or 'emails'
  Map<String, dynamic>? _selectedEmailThread;

  @override
  void initState() {
    super.initState();
    _communicationController = CommunicationHistoryController(
      customer: widget.customer,
      context: context,
    );
    _messageController.addListener(() {
      setState(() {}); // Update send button state
    });
  }

  @override
  void dispose() {
    _communicationController.dispose();
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  List<String> get _filteredCommunications {
    if (_searchQuery.isEmpty) {
      return widget.customer.communicationHistory;
    }
    return widget.customer.communicationHistory.where((comm) {
      return comm.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Actions Header
          _buildHeader(),
          
          // Communication Content
          Expanded(
            child: _buildCommunicationContent(),
          ),
          
          // Quick Actions Footer
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search communications...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showAddResponseDialog(),
                icon: const Icon(Icons.add_comment),
                tooltip: _activeType == 'messages' 
                    ? 'Add Customer Response' 
                    : 'Add Email Response',
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Communication Type Toggle
          _buildTypeToggle(),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeType = 'messages'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _activeType == 'messages' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _activeType == 'messages' 
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)]
                    : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message,
                      size: 16,
                      color: _activeType == 'messages' ? Colors.black : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Messages & Calls',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _activeType == 'messages' ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeType = 'emails'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _activeType == 'emails' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _activeType == 'emails' 
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)]
                    : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail,
                      size: 16,
                      color: _activeType == 'emails' ? Colors.black : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email Threads',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _activeType == 'emails' ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCommunicationContent() {
    if (_activeType == 'messages') {
      return _buildMessagesView();
    } else {
      return _buildEmailThreadsView();
    }
  }

  Widget _buildMessagesView() {
    if (_filteredCommunications.isEmpty) {
      return _buildEmptyState('messages');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListenableBuilder(
        listenable: _communicationController,
        builder: (context, child) {
          return CommunicationHistoryWidget(
            customer: widget.customer,
            controller: _communicationController,
          );
        },
      ),
    );
  }

  Widget _buildEmailThreadsView() {
    final emailThreads = _communicationController.groupEmailsByThread();
    
    if (emailThreads.isEmpty) {
      return _buildEmptyState('emails');
    }

    // Filter threads based on search query
    final filteredThreads = _searchQuery.isEmpty 
        ? emailThreads 
        : emailThreads.where((thread) {
            final subject = thread['subject'] as String;
            final emails = thread['emails'] as List<Map<String, dynamic>>;
            
            // Search in subject
            if (subject.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return true;
            }
            
            // Search in email messages
            return emails.any((email) {
              final message = email['cleanMessage'] as String;
              return message.toLowerCase().contains(_searchQuery.toLowerCase());
            });
          }).toList();

    if (filteredThreads.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptyState('emails');
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredThreads.length,
          itemBuilder: (context, index) {
            final thread = filteredThreads[index];
            return EmailThreadCard(
              thread: thread,
              onTap: () => _showEmailThreadDetail(thread),
            );
          },
        ),
        if (_selectedEmailThread != null)
          Positioned.fill(
            child: EmailThreadDetailView(
              thread: _selectedEmailThread!,
              customer: widget.customer,
              controller: _communicationController,
              onClose: () => setState(() => _selectedEmailThread = null),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'messages' ? Icons.message : Icons.mail,
              color: Colors.grey[400],
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No ${type == 'messages' ? 'messages' : 'email threads'} found'
                : 'No ${type == 'messages' ? 'messages' : 'email threads'} yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search terms'
                : type == 'messages' 
                    ? 'Start a conversation with your customer'
                    : 'Email conversations will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: _activeType == 'messages' ? _buildMessageActions() : _buildEmailActions(),
    );
  }

  Widget _buildMessageActions() {
    return Column(
      children: [
        // Message composer (simple version)
        if (_activeType == 'messages') ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  maxLines: 1,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _messageController.text.trim().isNotEmpty ? Colors.blue : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _messageController.text.trim().isNotEmpty ? _sendMessage : null,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Action buttons
        Row(
          children: [
            Expanded(
              child: RufkoSecondaryButton(
                onPressed: _makeCall,
                icon: Icons.phone,
                isFullWidth: true,
                child: const Text('Call'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RufkoSecondaryButton(
                onPressed: widget.onTemplateSMS,
                icon: Icons.sms,
                isFullWidth: true,
                child: const Text('Template SMS'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RufkoSecondaryButton(
                onPressed: _showEmailCompositionDialog,
                icon: _selectedEmailThread != null ? Icons.reply : Icons.mail,
                isFullWidth: true,
                child: Text(_selectedEmailThread != null ? 'Reply' : 'Compose Email'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Check if customer has phone number
    if (widget.customer.phone == null || widget.customer.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer has no phone number. Please add one first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Log the communication first
      widget.customer.addCommunication(
        'Quick SMS sent: ${messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText}',
        type: 'text',
      );

      // Update customer in provider
      await context.read<AppStateProvider>().updateCustomer(widget.customer);

      // Use the existing real SMS service to send
      final result = await _sendSMSDirect(
        widget.customer.phone!,
        messageText,
      );

      // Handle result
      if (result.isSuccess) {
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS app opened with your message'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Failed to open SMS app'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Show error feedback for unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Make a phone call to the customer
  Future<void> _makeCall() async {
    // Check if customer has phone number
    if (widget.customer.phone == null || widget.customer.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer has no phone number. Please add one first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Log the communication first  
      widget.customer.addCommunication(
        'Outbound call to ${widget.customer.name}',
        type: 'call',
      );

      // Update customer in provider
      await context.read<AppStateProvider>().updateCustomer(widget.customer);

      // Make the call using the same logic as CommunicationService
      final result = await _makeCallDirect(widget.customer.phone!);

      // Handle result
      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Call initiated'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Failed to make call'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Show error feedback for unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Direct SMS sending using the same logic as CommunicationService
  Future<CommunicationResult> _sendSMSDirect(String phoneNumber, String message) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return const CommunicationResult.success();
      } else {
        return const CommunicationResult.error('Cannot launch SMS app');
      }
    } catch (e) {
      return CommunicationResult.error('SMS sending failed: $e');
    }
  }

  /// Direct phone call using url_launcher
  Future<CommunicationResult> _makeCallDirect(String phoneNumber) async {
    try {
      // Clean the phone number (remove any non-digit characters except +)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      final Uri callUri = Uri(
        scheme: 'tel',
        path: cleanPhone,
      );

      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        return const CommunicationResult.success();
      } else {
        return const CommunicationResult.error('Cannot launch phone app');
      }
    } catch (e) {
      return CommunicationResult.error('Call failed: $e');
    }
  }

  /// Show dialog to add customer response
  void _showAddResponseDialog() {
    if (_activeType == 'messages') {
      // Show SMS/Call response dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CustomerResponseDialog(
          messageType: 'text',
          contactMethod: widget.customer.phone ?? widget.customer.email ?? '',
          customer: widget.customer,
          controller: _communicationController,
        ),
      );
    } else {
      // Show email response dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => EmailResponseDialog(
          customer: widget.customer,
          controller: _communicationController,
        ),
      );
    }
  }

  /// Show email thread detail view
  void _showEmailThreadDetail(Map<String, dynamic> thread) {
    setState(() {
      _selectedEmailThread = thread;
    });
  }

  /// Show email composition dialog
  void _showEmailCompositionDialog() {
    // Determine if this is a reply
    final bool isReply = _selectedEmailThread != null;
    final String? replyToSubject = isReply 
        ? _selectedEmailThread!['subject'] as String?
        : null;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => EmailCompositionDialog(
        customer: widget.customer,
        communicationController: _communicationController,
        isReply: isReply,
        replyToThreadSubject: replyToSubject,
      ),
    );
  }
}