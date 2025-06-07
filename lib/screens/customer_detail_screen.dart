// lib/screens/customer_detail_screen.dart - COMPLETE WITH MEDIA FUNCTIONALITY + MULTI-SELECT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import '../utils/common_utils.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/project_media.dart';
import '../models/simplified_quote.dart';
import '../providers/app_state_provider.dart';
import 'pdf_preview_screen.dart';
import 'simplified_quote_screen.dart';
import 'simplified_quote_detail_screen.dart';
import '../mixins/file_sharing_mixin.dart';
import '../mixins/communication_actions_mixin.dart';
import '../models/custom_app_data.dart';
import '../models/inspection_document.dart';
import 'inspection_viewer_screen.dart';
import 'customer_detail/enhanced_communication_dialog.dart';
import 'customer_detail/media_details_dialog.dart';
import 'customer_detail/full_screen_image_viewer.dart';
import 'customer_detail/category_media_screen.dart';
import 'customer_detail/customer_edit_dialog.dart';
import 'customer_detail/quotes_tab.dart';
import 'customer_detail/project_notes_section.dart';
import 'customer_detail/media_tab.dart';
import 'customer_detail/info_tab.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with TickerProviderStateMixin, FileSharingMixin, CommunicationActionsMixin {
  late TabController _tabController;
  final TextEditingController _communicationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessingMedia = false;


  // Multi-select state for media
  bool _isSelectionMode = false;
  Set<String> _selectedMediaIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen for tab changes to exit selection mode
    _tabController.addListener(() {
      if (_isSelectionMode && _tabController.index != 3) {
        _exitSelectionMode();
      }

    });
  }





  @override
  void dispose() {
    _tabController.dispose();
    _communicationController.dispose();
    super.dispose();
  }

  // SELECTION MODE METHODS
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedMediaIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMediaIds.clear();
    });
  }

  void _toggleMediaSelection(String mediaId) {
    setState(() {
      if (_selectedMediaIds.contains(mediaId)) {
        _selectedMediaIds.remove(mediaId);
      } else {
        _selectedMediaIds.add(mediaId);
      }
    });
  }

  void _selectAllMedia() {
    final appState = context.read<AppStateProvider>();
    final mediaItems = appState.getProjectMediaForCustomer(widget.customer.id);

    setState(() {
      if (_selectedMediaIds.length == mediaItems.length) {
        // Deselect all if all are selected
        _selectedMediaIds.clear();
      } else {
        // Select all
        _selectedMediaIds = mediaItems.map((m) => m.id).toSet();
      }
    });
  }

  void _deleteSelectedMedia() {
    if (_selectedMediaIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedMediaIds.length} file${_selectedMediaIds.length == 1 ? '' : 's'}'),
        content: Text(
            _selectedMediaIds.length == 1
                ? 'Are you sure you want to delete this file?'
                : 'Are you sure you want to delete these ${_selectedMediaIds.length} files?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final appState = context.read<AppStateProvider>();
                final mediaItems = appState.getProjectMediaForCustomer(widget.customer.id);
                final itemsToDelete = mediaItems.where((m) => _selectedMediaIds.contains(m.id)).toList();

                // Delete files from device and app state
                for (final mediaItem in itemsToDelete) {
                  // Delete file from device
                  final file = File(mediaItem.filePath);
                  if (await file.exists()) {
                    await file.delete();
                  }

                  // Remove from app state
                  await appState.deleteProjectMedia(mediaItem.id);
                }

                // Exit selection mode
                _exitSelectionMode();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${itemsToDelete.length} file${itemsToDelete.length == 1 ? '' : 's'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                showErrorSnackBar('Error deleting files: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isSelectionMode) {
            _exitSelectionMode();
          }
        }
      },
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  _buildModernSliverAppBar(appState),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  InfoTab(
                    customer: widget.customer,
                    onAddProjectNote: _addProjectNote,
                    onEditProjectNote: _editProjectNote,
                    formatDate: formatCommunicationDate,
                    onTemplateEmail: _showTemplateEmailPicker,
                    onTemplateSMS: _showTemplateSMSPicker,
                    onQuickCommunication: _showQuickCommunicationOptions,
                    onAddCommunication: _addCommunication,
                    communicationHistory: _buildChatStyleCommunicationHistory(),
                  ),
                  QuotesTab(
                    customer: widget.customer,
                    onCreateQuote: _navigateToCreateQuoteScreen,
                    onOpenQuote: _navigateToSimplifiedQuoteDetail,
                  ),
                  _buildInspectionTab(), // NEW
                  MediaTab(
                    customer: widget.customer,
                    isProcessing: _isProcessingMedia,
                    isSelectionMode: _isSelectionMode,
                    selectedMediaIds: _selectedMediaIds,
                    onEnterSelection: _enterSelectionMode,
                    onExitSelection: _exitSelectionMode,
                    onSelectAll: _selectAllMedia,
                    onToggleSelection: _toggleMediaSelection,
                    onDeleteSelected: _deleteSelectedMedia,
                    onPickImageFromCamera: _pickImageFromCamera,
                    onPickImageFromGallery: _pickImageFromGallery,
                    onPickDocument: _pickDocument,
                    onViewMedia: _viewMedia,
                    onShowContextMenu: _showMediaContextMenu,
                    onShowMediaOptions: _showMediaOptions,
                  ),
                ],
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final currentTab = _tabController.index;

        // Media tab with selection mode
        if (currentTab == 4 && _isSelectionMode) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_selectedMediaIds.isNotEmpty)
                FloatingActionButton(
                  heroTag: "delete_selected_media_fab",
                  onPressed: _deleteSelectedMedia,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: "cancel_media_selection_fab",
                onPressed: _exitSelectionMode,
                backgroundColor: Colors.grey,
                child: const Icon(Icons.close),
              ),
            ],
          );
        }



        // Regular FABs for each tab
        switch (currentTab) {
          case 0: // Info tab
            return FloatingActionButton.extended(
              heroTag: "info_fab",
              onPressed: _navigateToCreateQuoteScreen,
              icon: const Icon(Icons.add),
              label: const Text('New Quote'),
              backgroundColor: Theme.of(context).primaryColor,
            );
          case 1: // Quotes tab
            return FloatingActionButton.extended(
              heroTag: "quotes_fab",
              onPressed: _navigateToCreateQuoteScreen,
              icon: const Icon(Icons.add),
              label: const Text('New Quote'),
              backgroundColor: Theme.of(context).primaryColor,
            );
          case 2: // Inspection tab (was case 3)
            return FloatingActionButton.extended(
              heroTag: "inspection_fab",
              onPressed: _navigateToCreateQuoteScreen,
              icon: const Icon(Icons.add_task),
              label: const Text('New Quote'),
              backgroundColor: Colors.green,
            );
          case 3: // Media tab (was case 4)
            return FloatingActionButton.extended(
              heroTag: "media_fab",
              onPressed: _showMediaOptions,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Media'),
              backgroundColor: Colors.teal,
            );
          default:
            return FloatingActionButton.extended(
              heroTag: "default_fab",
              onPressed: _navigateToCreateQuoteScreen,
              icon: const Icon(Icons.add),
              label: const Text('New Quote'),
              backgroundColor: Theme.of(context).primaryColor,
            );
        }
      },
    );
  }
  Widget _buildModernSliverAppBar(AppStateProvider appState) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2E86AB),
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E86AB),
                Color(0xFF1B5E7F),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_tabController.index == 3 && !_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _enterSelectionMode,
            tooltip: 'Select files',
            color: Colors.white,
          ),
        if (!_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCustomer,
            color: Colors.white,
          ),
        if (!_isSelectionMode)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'new_quote':
                  _navigateToCreateQuoteScreen();
                  break;
                case 'edit_customer':
                  _editCustomer();
                  break;
                case 'delete_customer':
                  _showDeleteCustomerConfirmation();
                  break;
                case 'quick_actions':
                  _showQuickActions();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_quote',
                child: Row(
                  children: [
                    Icon(Icons.add_box, size: 18),
                    SizedBox(width: 8),
                    Text('New Quote'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_customer',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Customer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_customer',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Customer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'quick_actions',
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('Quick Actions'),
                  ],
                ),
              ),
            ],
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(
            icon: Icon(_isSelectionMode && _tabController.index == 3
                ? Icons.checklist
                : Icons.info_outline),
            text: _isSelectionMode && _tabController.index == 3
                ? '${_selectedMediaIds.length} selected'
                : 'Info',
          ),
          const Tab(icon: Icon(Icons.description), text: 'Quotes'),
          const Tab(icon: Icon(Icons.assignment), text: 'Inspection'),
          const Tab(icon: Icon(Icons.photo_library), text: 'Media'),
        ],
      ),
    );
  }

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

    // Reverse the list to show newest first
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

          // Determine message type and direction
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

    // Reverse the list to show newest first
    final communications =
        widget.customer.communicationHistory.reversed.toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: communications.length,
        itemBuilder: (context, index) {
          final entry = communications[index];
          final parts = entry.split(': ');
          final timestamp = parts.isNotEmpty ? parts[0] : '';
          final message =
              parts.length > 1 ? parts.sublist(1).join(': ') : entry;

          // Determine message type and direction
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
    // Check if this is an "opened" message that needs ADD RESPONSE
    final isOpenedMessage = message.toLowerCase().contains('opened sms to') ||
        message.toLowerCase().contains('opened email to');

    if (isOpenedMessage) {
      // Check if there's already a customer response logged after this message
      final hasResponse = _hasCustomerResponseAfter(timestamp);

      if (hasResponse) {
        // Don't show the orange bubble, response already logged
        return const SizedBox.shrink(); // Hide this message completely
      } else {
        // Show the orange "ADD RESPONSE" bubble
        return _buildAddResponseCard(message, timestamp, messageType);
      }
    }

    // Regular chat bubble for normal messages
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
                      // Add edit button for customer responses
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
    // Extract phone/email from the original message
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

      // Check all communication history for customer responses after this timestamp
      for (final entry in widget.customer.communicationHistory) {
        final parts = entry.split(': ');
        if (parts.length < 2) continue;

        final entryTimestamp = parts[0];
        final entryMessage = parts.sublist(1).join(': ');

        try {
          final entryDateTime = DateTime.parse(entryTimestamp);

          // If this entry is after the original timestamp
          if (entryDateTime.isAfter(originalDateTime)) {
            // Check if it's a customer response
            if (entryMessage.toLowerCase().contains('customer responded via') ||
                entryMessage.toLowerCase().contains('customer replied') ||
                entryMessage.toLowerCase().contains('customer said')) {
              return true; // Found a response after this timestamp
            }
          }
        } catch (e) {
          // Skip entries with invalid timestamps
          continue;
        }
      }

      return false; // No response found
    } catch (e) {
      // If timestamp parsing fails, show the orange bubble to be safe
      return false;
    }
  }
  bool _isOutgoingMessage(String message) {
    // Special case: "Opened" messages should show as "ADD RESPONSE" (not outgoing, not incoming)
    if (message.toLowerCase().contains('opened sms to') ||
        message.toLowerCase().contains('opened email to')) {
      return false; // We'll handle these specially
    }

    // Messages sent by business (outgoing)
    final outgoingKeywords = ['sent', 'delivered', 'provided', 'scheduled', 'completed', 'quote', 'invoice', 'template'];
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
    // Check if this message is a logged customer response
    return message.toLowerCase().contains('customer responded via') ||
        message.toLowerCase().contains('customer replied') ||
        message.toLowerCase().contains('customer said');
  }

  void _editCustomerResponse(String originalMessage, String timestamp) {
    // Extract the response type and content from the original message
    String responseType = 'text';
    String responseContent = '';

    try {
      // Parse the original logged response
      // Format: "Customer responded via [type]: [content]"
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
    } catch (e) {
      // If parsing fails, use defaults
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
                // Header
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

                          _updateCustomerResponse(originalMessage, timestamp, editedResponseType, editedResponse);
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
      // Find and update the specific communication entry
      final communicationHistory = widget.customer.communicationHistory;

      for (int i = 0; i < communicationHistory.length; i++) {
        final entry = communicationHistory[i];
        final parts = entry.split(': ');

        if (parts.isNotEmpty && parts[0] == timestamp) {
          // Found the matching entry, update it
          final newMessage = 'Customer responded via $newResponseType: $newResponse';
          final updatedEntry = '$timestamp: $newMessage';

          // Replace the entry in the list
          communicationHistory[i] = updatedEntry;

          // Update the customer and save
          context.read<AppStateProvider>().updateCustomer(widget.customer);
          setState(() {}); // Refresh the UI

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer response updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          return; // Exit once we've found and updated the entry
        }
      }

      // If we get here, the original entry wasn't found
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
                // Header
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

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Note Type Selector
                        Text(
                          'Note Type:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'note',
                              label: Text('General'),
                              icon: Icon(Icons.note),
                            ),
                            ButtonSegment(
                              value: 'meeting',
                              label: Text('Meeting'),
                              icon: Icon(Icons.group),
                            ),
                            ButtonSegment(
                              value: 'site_visit',
                              label: Text('Site Visit'),
                              icon: Icon(Icons.home_work),
                            ),
                          ],
                          selected: {noteType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              noteType = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Note Content
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

                        // Quick Templates
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

                          // Add project note with special prefix
                          widget.customer.addCommunication(
                            'PROJECT_NOTE: $noteContent',
                            type: 'note',
                          );

                          context.read<AppStateProvider>().updateCustomer(widget.customer);
                          setState(() {}); // Refresh parent widget

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
    // Extract note content from the original entry
    final parts = originalEntry.split(': ');
    String noteContent = '';
    String noteType = 'note';

    if (parts.length > 1) {
      final fullNote = parts.sublist(1).join(': ');
      noteContent = fullNote.replaceFirst('PROJECT_NOTE: ', '');

      // Determine note type from content
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
                // Header
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

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Note Type Selector
                        Text(
                          'Note Type:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'note',
                              label: Text('General'),
                              icon: Icon(Icons.note),
                            ),
                            ButtonSegment(
                              value: 'meeting',
                              label: Text('Meeting'),
                              icon: Icon(Icons.group),
                            ),
                            ButtonSegment(
                              value: 'site_visit',
                              label: Text('Site Visit'),
                              icon: Icon(Icons.home_work),
                            ),
                          ],
                          selected: {editedNoteType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              editedNoteType = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Note Content
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
      // Find and update the specific note entry
      final communicationHistory = widget.customer.communicationHistory;

      for (int i = 0; i < communicationHistory.length; i++) {
        final entry = communicationHistory[i];

        if (entry == originalEntry) {
          // Found the matching entry, update it
          final updatedEntry = '$timestamp: PROJECT_NOTE: $newContent';

          // Replace the entry in the list
          communicationHistory[i] = updatedEntry;

          // Update the customer and save
          context.read<AppStateProvider>().updateCustomer(widget.customer);
          setState(() {}); // Refresh the UI

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project note updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          return; // Exit once we've found and updated the entry
        }
      }

      // If we get here, the original entry wasn't found
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
      // Sanitize the message to handle potential UTF-16 issues
      String cleanedMessage = message
          .replaceAll(RegExp(r'^[📞📧💬🤝🏠📅📝]\s*'), '')
          .replaceAll(RegExp(r'\[URGENT\]\s*'), '')
          .trim();

      // Remove any invalid UTF-16 characters
      cleanedMessage = _sanitizeString(cleanedMessage);

      // If message is empty after cleaning, provide a fallback
      return cleanedMessage.isEmpty ? 'Communication recorded' : cleanedMessage;
    } catch (e) {
      // If any error occurs, return a safe fallback
      return 'Communication recorded';
    }
  }

  String _sanitizeString(String input) {
    try {
      // Remove any characters that might cause UTF-16 issues
      final sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');

      // Ensure the string is valid UTF-16
      final buffer = StringBuffer();
      for (int i = 0; i < sanitized.length; i++) {
        final char = sanitized[i];
        final code = char.codeUnitAt(0);

        // Only include valid Unicode characters
        if ((code >= 0x20 && code <= 0xD7FF) ||
            (code >= 0xE000 && code <= 0xFFFD) ||
            code == 0x09 || code == 0x0A || code == 0x0D) {
          buffer.write(char);
        } else {
          buffer.write(' '); // Replace invalid chars with space
        }
      }

      return buffer.toString().trim();
    } catch (e) {
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
  void _showTemplateSMSPicker() {
    final appState = context.read<AppStateProvider>();
    final messageTemplates = appState.activeMessageTemplates;

    if (messageTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No message templates available. Create templates first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sms, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Choose SMS Template',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a template to send to ${widget.customer.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: messageTemplates.length,
                  itemBuilder: (context, index) {
                    final template = messageTemplates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.sms, color: Colors.purple),
                        ),
                        title: Text(
                          template.templateName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${template.category} • ${template.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _previewAndSendSMS(template);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previewAndSendSMS(dynamic template) {
    final customerData = _buildCustomerDataMap();

    // Generate the SMS with customer data filled in
    final filledMessage = template.generateMessage(customerData);

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sms, color: Colors.purple, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SMS Preview',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Template: ${template.templateName}',
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

              // SMS Preview Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SMS Header Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text('To: ${widget.customer.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(widget.customer.phone ?? 'No phone number'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SMS Preview in Phone-like Interface
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            // Phone mockup header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone_android, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SMS Preview',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // SMS Message Bubble
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(18).copyWith(
                                    bottomRight: const Radius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  filledMessage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Character count
                            Text(
                              '${filledMessage.length} characters',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              // Footer Actions
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
                        Navigator.pop(context);
                        _editSMSBeforeSending(template, filledMessage);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendTemplateSMS(template, filledMessage);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Send As-Is'),
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
      ),
    );
  }

  void _sendTemplateSMS(dynamic template, String message) {
    // Log the SMS communication with filled content
    widget.customer.addCommunication(
      'SMS sent using template "${template.templateName}" - Message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      type: 'text',
    );
    context.read<AppStateProvider>().updateCustomer(widget.customer);
    setState(() {});

    // Try to open SMS app if customer has phone
    if (widget.customer.phone != null) {
      sendSMS(widget.customer.phone!, message: message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer has no phone number. Communication logged only.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Map<String, String> _buildCustomerDataMap() {
    // Get app settings for company info
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings;

    return {
      // Customer Information
      'customerName': widget.customer.name,
      'customerPhone': widget.customer.phone ?? 'Not provided',
      'customerEmail': widget.customer.email ?? 'Not provided',
      'customerStreetAddress': widget.customer.streetAddress ?? '',
      'customerCity': widget.customer.city ?? '',
      'customerState': widget.customer.stateAbbreviation ?? '',
      'customerZipCode': widget.customer.zipCode ?? '',
      'customerFullAddress': widget.customer.fullDisplayAddress,

      // Company Information (from app settings if available)
      'companyName': settings?.companyName ?? 'Your Company Name',
      'companyPhone': settings?.companyPhone ?? 'Your Phone',
      'companyEmail': settings?.companyEmail ?? 'Your Email',
      'companyAddress': settings?.companyAddress ?? 'Your Address',

      // Date Information
      'todaysDate': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
      'currentTime': TimeOfDay.now().format(context),

      // Customer Stats
      'totalQuotes': appState.getSimplifiedQuotesForCustomer(widget.customer.id).length.toString(),
      'customerSince': widget.customer.createdAt.toString().split(' ')[0],

      // Additional placeholders that might be commonly used
      'representativeName': 'Your Sales Rep',
      'appointmentDate': 'TBD',
      'appointmentTime': 'TBD',
      'quoteNumber': 'Will be assigned',
      'projectAddress': widget.customer.fullDisplayAddress,
    };
  }

  void _showTemplateEmailPicker() {
    final appState = context.read<AppStateProvider>();
    final emailTemplates = appState.activeEmailTemplates;

    if (emailTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email templates available. Create templates first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Choose Email Template',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a template to send to ${widget.customer.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: emailTemplates.length,
                  itemBuilder: (context, index) {
                    final template = emailTemplates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.email, color: Colors.blue),
                        ),
                        title: Text(
                          template.templateName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${template.category} • ${template.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _previewAndSendEmail(template);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _editSMSBeforeSending(dynamic template, String originalMessage) {
    final messageController = TextEditingController(text: originalMessage);

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
                // Header
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
                      Icon(Icons.edit, color: Colors.purple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit SMS',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Template: ${template.templateName}',
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

                // Edit Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipient Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text('To: ${widget.customer.name} (${widget.customer.phone ?? 'No phone'})'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Message Field
                        Text(
                          'SMS Message:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: messageController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: 'SMS message...',
                            prefixIcon: const Icon(Icons.sms),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 6,
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (value) => setState(() {}), // Update character count
                        ),
                        const SizedBox(height: 12),

                        // Character count and SMS info
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
                                    messageController.text.length <= 160 ? '1 SMS' : '${(messageController.text.length / 160).ceil()} SMS',
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

                        // Live Preview
                        Text(
                          'Preview:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(18).copyWith(
                                  bottomRight: const Radius.circular(4),
                                ),
                              ),
                              child: Text(
                                messageController.text.isEmpty ? 'Your message will appear here...' : messageController.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontStyle: messageController.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
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
                          Navigator.pop(context);
                          _previewAndSendSMS(template);
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

                          Navigator.pop(context);
                          _sendTemplateSMS(template, editedMessage);
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
        ),
      ),
    );
  }
  void _previewAndSendEmail(dynamic template) {
    final customerData = _buildCustomerDataMap();

    // Generate the email with customer data filled in
    final generatedEmail = template.generateEmail(customerData);
    final filledSubject = generatedEmail['subject'] ?? template.subject;
    final filledContent = generatedEmail['content'] ?? template.emailContent;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
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
                    Icon(Icons.email, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Preview',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Template: ${template.templateName}',
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

              // Email Preview Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Email Header Info
                  Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text('To: ${widget.customer.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(widget.customer.email ?? 'No email address'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Subject Line
                Text(
                  'Subject:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    filledSubject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Content
                Text(
                  'Message:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  filledContent,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Footer Actions
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
                        Navigator.pop(context);
                        _editEmailBeforeSending(template, filledSubject, filledContent);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendTemplateEmail(template, filledSubject, filledContent);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Send As-Is'),
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
    );
  }

  void _editEmailBeforeSending(dynamic template, String originalSubject, String originalContent) {
    final subjectController = TextEditingController(text: originalSubject);
    final contentController = TextEditingController(text: originalContent);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
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
                            'Edit Email',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Template: ${template.templateName}',
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

              // Edit Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipient Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('To: ${widget.customer.name} (${widget.customer.email ?? 'No email'})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subject Field
                      Text(
                        'Subject Line:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          hintText: 'Email subject...',
                          prefixIcon: const Icon(Icons.subject),
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 20),

                      // Content Field
                      Text(
                        'Email Content:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: contentController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          hintText: 'Email message...',
                          prefixIcon: const Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                      const SizedBox(height: 16),

                      // Character count
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${contentController.text.length} characters',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
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
                        Navigator.pop(context);
                        _previewAndSendEmail(template);
                      },
                      icon: const Icon(Icons.preview),
                      label: const Text('Preview'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        final editedSubject = subjectController.text.trim();
                        final editedContent = contentController.text.trim();

                        if (editedSubject.isEmpty || editedContent.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Subject and content cannot be empty'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        _sendTemplateEmail(template, editedSubject, editedContent);
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
      ),
    );
  }

  void _sendTemplateEmail(dynamic template, String subject, String content) {
    // Log the email communication with filled content
    widget.customer.addCommunication(
      'Email sent using template "${template.templateName}" - Subject: $subject',
      type: 'email',
    );
    context.read<AppStateProvider>().updateCustomer(widget.customer);
    setState(() {});

    // Try to open email app if customer has email
    if (widget.customer.email != null) {
      sendEmail(widget.customer.email!, subject: subject, body: content);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer has no email address. Communication logged only.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildInspectionTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        // Filter to only show inspection category fields
        final allCustomFields = appState.customAppDataFields;
        final inspectionFields = allCustomFields
            .where((field) => field.category == 'inspection')
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (inspectionFields.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No inspection fields configured',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to Templates → Custom App Data Fields\nand create fields with "Inspection" category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to custom fields screen (placeholder for now)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigation to Custom Fields coming soon'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Inspection Fields'),
                ),
                const SizedBox(height: 32),
                _buildInspectionDocumentsSection(),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.assignment, size: 28, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Site Inspection - ${widget.customer.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Fill out inspection details for this customer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_mode,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  Text(
                    'Auto-saves',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${inspectionFields.length} field${inspectionFields.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Inspection fields as a single group
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Inspection Fields',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: inspectionFields.length,
                        onReorder: (oldIndex, newIndex) => _onInspectionFieldReorder(oldIndex, newIndex, inspectionFields),
                        itemBuilder: (context, index) {
                          final field = inspectionFields[index];
                          return Container(
                            key: ValueKey(field.id),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: _buildFieldWidget(field),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ADD THESE TWO LINES - THIS IS THE FIX!
              const SizedBox(height: 32),
              _buildInspectionDocumentsSection(),
            ],
          ),
        );
      },
    );
  }
  void _onInspectionFieldReorder(int oldIndex, int newIndex, List<CustomAppDataField> fields) {
    if (oldIndex < newIndex) {
      newIndex--;
    }

    final movedField = fields.removeAt(oldIndex);
    fields.insert(newIndex, movedField);

    context.read<AppStateProvider>().reorderCustomAppDataFields('inspection', fields);
  }

  Widget _buildInspectionDocumentsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final inspectionDocs = appState.getInspectionDocumentsForCustomer(widget.customer.id);

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Inspection Documents',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${inspectionDocs.length} items',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (inspectionDocs.isEmpty)
                  _buildEmptyInspectionDocuments()
                else
                  _buildInspectionDocumentsList(inspectionDocs),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyInspectionDocuments() {
    // Check if note exists
    final existingDocs = context.read<AppStateProvider>().getInspectionDocumentsForCustomer(widget.customer.id);
    final hasNote = existingDocs.any((doc) => doc.isNote);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No inspection documents yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add notes and PDFs to document your inspection',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddInspectionNoteDialog,
                  icon: Icon(hasNote ? Icons.edit_note : Icons.note_add, size: 16),
                  label: Text(hasNote ? 'Edit Note' : 'Add Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddInspectionPdfDialog,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionDocumentsList(List<InspectionDocument> documents) {
    // Check if note exists
    final hasNote = documents.any((doc) => doc.isNote);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _showAddInspectionNoteDialog,
              icon: Icon(hasNote ? Icons.edit_note : Icons.note_add, size: 16),
              label: Text(hasNote ? 'Edit Note' : 'Add Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showAddInspectionPdfDialog,
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    doc.isNote ? Icons.note : Icons.picture_as_pdf,
                    color: doc.isNote ? Colors.blue : Colors.red,
                    size: 20,
                  ),
                  title: Text(
                    doc.displayTitle,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    doc.isNote
                        ? 'Note • ${DateFormat('MMM dd, yyyy').format(doc.createdAt)}'
                        : 'PDF • ${doc.formattedFileSize} • ${DateFormat('MMM dd, yyyy').format(doc.createdAt)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    // Find the index of this document
                    final allDocs = context.read<AppStateProvider>().getInspectionDocumentsForCustomer(widget.customer.id);
                    final index = allDocs.indexWhere((d) => d.id == doc.id);

                    // Navigate to the viewer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InspectionViewerScreen(
                          customer: widget.customer,
                          initialIndex: index != -1 ? index : 0,
                        ),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  void _showAddInspectionNoteDialog() {
    // Check if a note already exists
    final existingDocs = context.read<AppStateProvider>().getInspectionDocumentsForCustomer(widget.customer.id);
    final existingNote = existingDocs.where((doc) => doc.isNote).toList();

    if (existingNote.isNotEmpty) {
      _showEditInspectionNoteDialog(existingNote.first);
      return;
    }

    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isMobile = screenHeight < 700;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.note_add, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Inspection Note'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: isMobile ? screenHeight * 0.5 : 200, // Mobile gets MORE space
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      hintText: 'Document your inspection findings...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: isMobile ? 6 : 4, // Mobile gets MORE lines
                  ),
                  // Quick templates ONLY on mobile
                  if (isMobile) const SizedBox(height: 12),
                  if (isMobile) Text(
                    'Quick add:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (isMobile) const SizedBox(height: 4),
                  if (isMobile) Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      _buildQuickChip('Good condition', contentController),
                      _buildQuickChip('Minor repairs needed', contentController),
                      _buildQuickChip('Replacement recommended', contentController),
                      _buildQuickChip('No immediate concerns', contentController),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (contentController.text.trim().isNotEmpty) {
                  final note = InspectionDocumentHelper.createNote(
                    customerId: widget.customer.id,
                    title: 'Site Inspection',
                    content: contentController.text.trim(),
                  );

                  await context.read<AppStateProvider>().addInspectionDocument(note);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inspection note saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

// Responsive helper method for quick templates
  Widget _buildQuickChip(String text, TextEditingController controller) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 10)),
      onPressed: () {
        if (controller.text.isEmpty) {
          controller.text = text;
        } else {
          controller.text += '\n$text';
        }
      },
      backgroundColor: Colors.blue.shade50,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

// Responsive edit dialog
  void _showEditInspectionNoteDialog(InspectionDocument existingNote) {
    final contentController = TextEditingController(text: existingNote.content);

    showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 700;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit_note, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Edit Note'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? screenHeight * 0.35 : 350,
            ),
            child: SingleChildScrollView(
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: 'Update inspection notes...',
                  border: OutlineInputBorder(),
                ),
                maxLines: isSmallScreen ? 6 : 8,
              ),
            ),
          ),
          actions: [
            if (!isSmallScreen)
              TextButton(
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Note'),
                      content: const Text('Delete this inspection note?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    await context.read<AppStateProvider>().deleteInspectionDocument(existingNote.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note deleted'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                existingNote.updateContent(contentController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note updated!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Update'),
            ),
          ],
          actionsPadding: isSmallScreen
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : const EdgeInsets.all(8),
        );
      },
    );
  }

  void _showAddInspectionPdfDialog() async {
    try {
      // Pick PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();

        // Show dialog to get title
        final titleController = TextEditingController(text: fileName.replaceAll('.pdf', ''));
        List<String> selectedTags = ['inspection', 'pdf'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Add PDF Document'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatFileSize(fileSize),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title field
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    hintText: 'e.g., Roof Inspection Report',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Create inspection document
                  final document = InspectionDocumentHelper.createPdf(
                    customerId: widget.customer.id,
                    title: title,
                    filePath: file.path,
                    fileSizeBytes: fileSize,
                    tags: selectedTags,
                  );

                  // Save to app state
                  await context.read<AppStateProvider>().addInspectionDocument(document);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF document added!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Add Document'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }




  Widget _buildFieldWidget(dynamic field) {
    final currentValue = widget.customer.getInspectionValue(field.fieldName);

    switch (field.fieldType) {
      case 'text':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.text_fields, color: Colors.blue),
                ),
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            SizedBox(width: 48), // Space for drag handle
          ],
        );

      case 'multiline':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.notes, color: Colors.blue),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            SizedBox(width: 48), // Space for drag handle
          ],
        );

      case 'number':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.numbers, color: Colors.green),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final numValue = double.tryParse(value);
                  _updateFieldValue(field.fieldName, numValue ?? value);
                },
              ),
            ),
            SizedBox(width: 48), // Space for drag handle
          ],
        );

      case 'checkbox':
        final bool checkboxValue = currentValue == true || currentValue == 'true';

        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: Text(field.displayName),
                  subtitle: field.description != null ? Text(field.description) : null,
                  value: checkboxValue,
                  onChanged: (value) {
                    _updateFieldValue(field.fieldName, value ?? false);
                  },
                ),
              ),
            ),
            SizedBox(width: 48), // Space for drag handle
          ],
        );

      case 'dropdown':
        final options = field.dropdownOptions ?? ['Good', 'Fair', 'Poor'];
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentValue?.toString(),
                decoration: InputDecoration(
                  labelText: field.displayName,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.arrow_drop_down, color: Colors.purple),
                ),
                items: options.map((option) =>
                    DropdownMenuItem(value: option, child: Text(option))
                ).toList(),
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            SizedBox(width: 48), // Space for drag handle
          ],
        );

      case 'date':
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder ?? 'Select date',
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.red),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_month),
                    onPressed: () => _selectDate(field.fieldName),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(field.fieldName),
              ),
            ),
            SizedBox(width: 48), // Space for drag handle
          ],
        );

      default:
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: field.displayName,
                  hintText: field.placeholder,
                  helperText: field.description,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.help_outline, color: Colors.grey),
                ),
                onChanged: (value) => _updateFieldValue(field.fieldName, value),
              ),
            ),
            SizedBox(width: 48), // Space for drag handle
          ],
        );
    }
  }

  void _updateFieldValue(String fieldName, dynamic value) {
    widget.customer.setInspectionValue(fieldName, value);
    setState(() {}); // Refresh UI

    // 🚀 AUTO-SAVE: Immediately save to database when any field changes
    try {
      context.read<AppStateProvider>().updateCustomer(widget.customer);
      debugPrint('✅ Auto-saved inspection field: $fieldName = $value');
    } catch (e) {
      debugPrint('❌ Error auto-saving inspection data: $e');
      // Show brief error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }



  Future<void> _selectDate(String fieldName) async {
    final currentValue = widget.customer.getInspectionValue(fieldName);
    DateTime initialDate = DateTime.now();

    if (currentValue != null && currentValue.toString().isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentValue.toString());
      } catch (e) {
        // Use current date if parsing fails
      }
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      _updateFieldValue(fieldName, date.toIso8601String().split('T')[0]);
    }
  }


  Widget _buildMediaTypeHeader(String title, IconData icon, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSubsection(String category, List<ProjectMedia> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPhotoCategoryColor(category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getPhotoCategoryColor(category).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPhotoCategoryIcon(category),
                      size: 16,
                      color: _getPhotoCategoryColor(category),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatPhotoCategoryName(category),
                      style: TextStyle(
                        color: _getPhotoCategoryColor(category),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${items.length})',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCategoryMedia(category, items),
                icon: const Icon(Icons.fullscreen, size: 14),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: math.min(items.length, 10),
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: _buildCompactMediaCard(items[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Color _getPhotoCategoryColor(String category) {
    switch (category) {
      case 'before_photos':
        return Colors.blue;
      case 'after_photos':
        return Colors.green;
      case 'inspection_photos':
        return Colors.purple;
      case 'progress_photos':
        return Colors.orange;
      case 'damage_report':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPhotoCategoryIcon(String category) {
    switch (category) {
      case 'before_photos':
        return Icons.photo_camera_back;
      case 'after_photos':
        return Icons.photo_camera_front;
      case 'inspection_photos':
        return Icons.search;
      case 'progress_photos':
        return Icons.timeline;
      case 'damage_report':
        return Icons.warning;
      default:
        return Icons.photo;
    }
  }


  String _formatPhotoCategoryName(String category) {
    switch (category) {
      case 'before_photos':
        return 'Before Photos';
      case 'after_photos':
        return 'After Photos';
      case 'inspection_photos':
        return 'Inspection Photos';
      case 'progress_photos':
        return 'Progress Photos';
      case 'damage_report':
        return 'Damage Photos';
      case 'other_photos':
        return 'Other Photos';
      default:
        return formatCategoryName(category);
    }
  }


  Widget _buildMediaStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCompactMediaCard(ProjectMedia mediaItem) {
    final isSelected = _selectedMediaIds.contains(mediaItem.id);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: _isSelectionMode
                ? () => _toggleMediaSelection(mediaItem.id)
                : () => _viewMedia(mediaItem),
            onLongPress: !_isSelectionMode
                ? () => _showMediaContextMenu(mediaItem)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.grey[200],
                    child: mediaItem.isImage
                        ? Stack(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        if (File(mediaItem.filePath).existsSync())
                          Positioned.fill(
                            child: Image.file(
                              File(mediaItem.filePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey[400],
                                );
                              },
                            ),
                          ),
                      ],
                    )
                        : Icon(
                      mediaItem.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.insert_drive_file_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mediaItem.fileName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.blue.shade800 : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        mediaItem.formattedFileSize,
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected ? Colors.blue.shade600 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selection checkbox
          if (_isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) => _toggleMediaSelection(mediaItem.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

          // Selection overlay
          if (_isSelectionMode && isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // MEDIA FUNCTIONALITY METHODS
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Media',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
              ),
              title: const Text('Take Multiple Photos'),
              subtitle: const Text('Take several photos in sequence'),
              onTap: () {
                Navigator.pop(context);
                _takeMultiplePhotos();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: Colors.green.shade700),
              ),
              title: const Text('Select Multiple Photos'),
              subtitle: const Text('Choose multiple photos from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.file_upload, color: Colors.orange.shade700),
              ),
              title: const Text('Upload Documents'),
              subtitle: const Text('Select PDF, Word, Excel files'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeMultiplePhotos() async {
    List<File> photos = [];

    while (true) {
      try {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          photos.add(File(image.path));

          // Ask if they want to take another
          bool takeAnother = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Photo ${photos.length} taken'),
              content: const Text('Take another photo?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Done'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Take Another'),
                ),
              ],
            ),
          ) ?? false;

          if (!takeAnother) break;
        } else {
          break;
        }
      } catch (e) {
        showErrorSnackBar('Error taking photo: $e');
        break;
      }
    }

    if (photos.isNotEmpty) {
      await _processBulkMedia(photos, 'image');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final List<File> files = images.map((xfile) => File(xfile.path)).toList();
        await _processBulkMedia(files, 'image');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting images: $e');
    }
  }

  Future<void> _pickMultipleDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<File> files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        if (files.isNotEmpty) {
          await _processBulkMedia(files, 'document');
        }
      }
    } catch (e) {
      showErrorSnackBar('Error selecting documents: $e');
    }
  }

  Future<void> _processBulkMedia(List<File> files, String defaultType) async {
    if (files.isEmpty) return;

    // Show category selection dialog for bulk upload
    final String? selectedCategory = await _showBulkCategoryDialog(files.length, defaultType);

    if (selectedCategory == null) return; // User cancelled

    setState(() => _isProcessingMedia = true);

    try {
      int successCount = 0;

      for (final file in files) {
        try {
          final fileSize = await file.length();
          final fileName = path.basename(file.path);
          final fileExtension = path.extension(fileName).toLowerCase();

          String fileType = defaultType;
          if (fileExtension == '.pdf') {
            fileType = 'pdf';
          } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(fileExtension)) {
            fileType = 'image';
          }

          final mediaItem = ProjectMedia(
            customerId: widget.customer.id,
            filePath: file.path,
            fileName: fileName,
            fileType: fileType,
            category: selectedCategory,
            fileSizeBytes: fileSize,
          );

          await context.read<AppStateProvider>().addProjectMedia(mediaItem);
          successCount++;
        } catch (e) {
          debugPrint('Error processing file ${file.path}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $successCount of ${files.length} files'),
            backgroundColor: successCount == files.length ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      showErrorSnackBar('Error processing files: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingMedia = false);
      }
    }
  }

  Future<String?> _showBulkCategoryDialog(int fileCount, String defaultType) async {
    String selectedCategory = defaultType == 'image' ? 'before_photos' : 'general';

    final categories = [
      'before_photos',
      'after_photos',
      'inspection_photos',
      'progress_photos',
      'damage_report',
      'other_photos',
      'roofscope_reports',
      'contracts',
      'invoices',
      'permits',
      'insurance_docs',
      'general',
    ];

    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Category for $fileCount files'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select category for all $fileCount files:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Category',
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getFormattedCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value ?? 'general';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedCategory),
              child: const Text('Add Files'),
            ),
          ],
        ),
      ),
    );
  }
  String _getFormattedCategoryName(String category) {
    switch (category) {
      case 'before_photos':
        return '📷 Before Photos';
      case 'after_photos':
        return '📸 After Photos';
      case 'inspection_photos':
        return '🔍 Inspection Photos';
      case 'progress_photos':
        return '📊 Progress Photos';
      case 'damage_report':
        return '⚠️ Damage Photos';
      case 'other_photos':
        return '📱 Other Photos';
      case 'contracts':
        return '📋 Contracts';
      case 'invoices':
        return '💰 Invoices';
      case 'permits':
        return '🏛️ Permits';
      case 'insurance_docs':
        return '🛡️ Insurance Documents';
      case 'general':
        return '📁 General';
      default:
        return category.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedMedia(File(image.path), 'image');
      }
    } catch (e) {
      showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedMedia(File(image.path), 'image');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _processSelectedMedia(file, 'document');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting document: $e');
    }
  }

  Future<void> _processSelectedMedia(File file, String fileType) async {
    setState(() => _isProcessingMedia = true);

    try {
      // Calculate file size
      final fileSize = await file.length();

      // Get file info
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      // Determine file type
      String detectedType = fileType;
      if (fileExtension == '.pdf') {
        detectedType = 'pdf';
      } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(fileExtension)) {
        detectedType = 'image';
      }

      // Show media details dialog
      final ProjectMedia? mediaItem = await showDialog<ProjectMedia>(
        context: context,
        barrierDismissible: false,
        builder: (context) => MediaDetailsDialog(
          file: file,
          fileName: fileName,
          fileType: detectedType,
          fileSize: fileSize,
          customerId: widget.customer.id,
        ),
      );

      if (mediaItem != null) {
        // Add to app state
        await context.read<AppStateProvider>().addProjectMedia(mediaItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${mediaItem.fileName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      showErrorSnackBar('Error processing media: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingMedia = false);
      }
    }
  }

  Future<void> _viewMedia(ProjectMedia mediaItem) async {
    try {
      if (mediaItem.isImage) {
        // Show full-screen image viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(mediaItem: mediaItem),
          ),
        );
      } else if (mediaItem.isPdf) {
        // Use enhanced PDF preview screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfPath: mediaItem.filePath,
              suggestedFileName: mediaItem.fileName,
              customer: widget.customer,
              quote: mediaItem.quoteId != null
                  ? context.read<AppStateProvider>().getSimplifiedQuotesForCustomer(widget.customer.id)
                  .firstWhere((q) => q.id == mediaItem.quoteId, orElse: () => null as dynamic)
                  : null,
              title: mediaItem.description ?? mediaItem.fileName,
              isPreview: true,
            ),
          ),
        );
      } else {
        // Open other files with system default app
        final result = await OpenFilex.open(mediaItem.filePath);
        if (result.type != ResultType.done) {
          showErrorSnackBar('Cannot open file: ${result.message}');
        }
      }
    } catch (e) {
      showErrorSnackBar('Error opening media: $e');
    }
  }

  void _showMediaContextMenu(ProjectMedia mediaItem) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                if (mediaItem.isPdf) {
                  // Use enhanced PDF preview instead of system viewer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewScreen(
                        pdfPath: mediaItem.filePath,
                        suggestedFileName: mediaItem.fileName,
                        customer: widget.customer,
                        quote: mediaItem.quoteId != null
                            ? context.read<AppStateProvider>().getSimplifiedQuotesForCustomer(widget.customer.id)
                            .firstWhere((q) => q.id == mediaItem.quoteId, orElse: () => null as dynamic)
                            : null,
                        title: mediaItem.description ?? mediaItem.fileName,
                        isPreview: true,
                      ),
                    ),
                  );
                } else {
                  _viewMedia(mediaItem);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Details'),
              onTap: () {
                Navigator.pop(context);
                _editMediaDetails(mediaItem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                shareFile(
                  file: File(mediaItem.filePath),
                  fileName: mediaItem.fileName,
                  description: mediaItem.description,
                  customer: widget.customer,
                  fileType: mediaItem.fileType,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMedia(mediaItem);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editMediaDetails(ProjectMedia mediaItem) {
    showDialog(
      context: context,
      builder: (context) => MediaDetailsDialog.edit(
        mediaItem: mediaItem,
        onSave: (updatedMedia) async {
          await context.read<AppStateProvider>().updateProjectMedia(updatedMedia);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Media details updated'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _deleteMedia(ProjectMedia mediaItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete "${mediaItem.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete file from device
                final file = File(mediaItem.filePath);
                if (await file.exists()) {
                  await file.delete();
                }

                // Remove from app state
                await context.read<AppStateProvider>().deleteProjectMedia(mediaItem.id);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${mediaItem.fileName}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                showErrorSnackBar('Error deleting media: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCategoryMedia(String category, List<ProjectMedia> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryMediaScreen(
          category: category,
          mediaItems: items,
          customerName: widget.customer.name,
        ),
      ),
    );
  }

  // HELPER METHODS


  // showErrorSnackBar provided by CommunicationActionsMixin


  

  void _editCustomer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerEditDialog(
        customer: widget.customer,
        onCustomerUpdated: () {
          setState(() {});
        },
      ),
    );
  }

  void _showDeleteCustomerConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete ${widget.customer.name}?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also delete all quotes, RoofScope data, and media associated with this customer.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteCustomer(widget.customer.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.customer.name} deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addCommunication() {
    showDialog(
      context: context,
      builder: (context) => EnhancedCommunicationDialog(
        customer: widget.customer,
        onCommunicationAdded: () {
          setState(() {}); // Refresh the UI
        },
      ),
    );
  }

  void _navigateToCreateQuoteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteScreen(
          customer: widget.customer,
        ),
      ),
    );
  }

  void _navigateToSimplifiedQuoteDetail(SimplifiedMultiLevelQuote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteDetailScreen(
          quote: quote,
          customer: widget.customer,
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.green),
              title: const Text('Create New Quote'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateQuoteScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(context);
                _editCustomer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Add Media'),
              onTap: () {
                Navigator.pop(context);
                _showMediaOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.purple),
              title: const Text('Quick Communication'),
              onTap: () {
                Navigator.pop(context);
                _showQuickCommunicationOptions();
              },
            ),
          ],
        ),
      ),
    );
  } // <-- Proper closing brace for _showQuickActions

  // Quick communication options - SEPARATE METHOD
  void _showQuickCommunicationOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Communication',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact ${widget.customer.name} directly',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Real communication actions
                _buildRealCommTile(
                    'Call Customer',
                    widget.customer.phone != null ? 'Call ${widget.customer.phone}' : 'No phone number',
                    Icons.phone,
                    Colors.green,
                    widget.customer.phone != null ? () => makePhoneCall(widget.customer.phone!) : null
                ),

                _buildRealCommTile(
                    'Send Email',
                    widget.customer.email != null ? 'Email ${widget.customer.email}' : 'No email address',
                    Icons.email,
                    Colors.blue,
                    widget.customer.email != null ? () => sendEmail(widget.customer.email!) : null
                ),

                _buildRealCommTile(
                    'Send Text Message',
                    widget.customer.phone != null ? 'Text ${widget.customer.phone}' : 'No phone number',
                    Icons.sms,
                    Colors.purple,
                    widget.customer.phone != null ? () => sendSMS(widget.customer.phone!) : null
                ),

                const Divider(height: 32),

                // Quick logging actions
                Text(
                  'Quick Log Entry',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                _buildQuickCommTile('Initial Contact', 'Customer inquiry received', Icons.contact_phone, Colors.blue, () => _addQuickNote('📞 Initial contact - Customer interested in roofing services')),
                _buildQuickCommTile('Quote Sent', 'Quote delivered to customer', Icons.send, Colors.green, () => _showQuoteSentDialog()),
                _buildQuickCommTile('Site Visit', 'Schedule or log site visit', Icons.location_on, Colors.orange, () => _showSiteVisitDialog()),
                _buildQuickCommTile('Follow-up Needed', 'Set reminder note', Icons.schedule, Colors.amber, () => _showFollowUpDialog()),

                // Add some bottom padding to ensure scrolling works well
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildQuickCommTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  Widget _buildRealCommTile(String title, String subtitle, IconData icon, Color color, VoidCallback? onTap) {
    final bool isEnabled = onTap != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
              icon,
              color: isEnabled ? color : Colors.grey,
              size: 24
          ),
        ),
        title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isEnabled ? null : Colors.grey,
            )
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isEnabled ? null : Colors.grey,
          ),
        ),
        trailing: isEnabled
            ? const Icon(Icons.launch, size: 16)
            : const Icon(Icons.block, size: 16, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        enabled: isEnabled,
        onTap: onTap != null ? () {
          Navigator.pop(context);
          onTap();
        } : null,
      ),
    );
  }

  void _addQuickNote(String message) {
    widget.customer.addCommunication(message);
    context.read<AppStateProvider>().updateCustomer(widget.customer);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Communication logged'), backgroundColor: Colors.green),
    );
  }

  void _showQuoteSentDialog() {
    final quoteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quote Sent'),
        content: TextField(
          controller: quoteController,
          decoration: const InputDecoration(
            labelText: 'Quote Number (optional)',
            hintText: 'e.g., Q-2024-001',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quoteNum = quoteController.text.isNotEmpty ? quoteController.text : 'new quote';
              _addQuickNote('📧 Quote sent - $quoteNum delivered to customer');
              Navigator.pop(context);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showSiteVisitDialog() {
    final notesController = TextEditingController();
    bool isScheduled = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Site Visit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: isScheduled,
                    onChanged: (value) => setDialogState(() => isScheduled = value!),
                  ),
                  const Text('Scheduled'),
                  Radio<bool>(
                    value: false,
                    groupValue: isScheduled,
                    onChanged: (value) => setDialogState(() => isScheduled = value!),
                  ),
                  const Text('Completed'),
                ],
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: isScheduled ? 'Schedule Details' : 'Visit Notes',
                  hintText: isScheduled ? 'Date and time...' : 'What was observed...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final prefix = isScheduled ? '📅 Site visit scheduled' : '🏠 Site visit completed';
                final notes = notesController.text.isNotEmpty ? ' - ${notesController.text}' : '';
                _addQuickNote('$prefix$notes');
                Navigator.pop(context);
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }


  void _showFollowUpDialog() {
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Follow-up Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Note',
                  hintText: 'What needs to be followed up?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final notes = notesController.text.isNotEmpty ? notesController.text : 'General follow-up';
                final dateStr = DateFormat('MMM dd').format(selectedDate);
                _addQuickNote('📅 FOLLOW-UP ($dateStr): $notes');
                Navigator.pop(context);
              },
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
  // REAL COMMUNICATION METHODS MOVED TO MIXIN



}
