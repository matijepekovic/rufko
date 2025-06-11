// lib/screens/customer_detail_screen.dart - COMPLETE WITH MEDIA FUNCTIONALITY + MULTI-SELECT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utils/common_utils.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart';
import '../providers/app_state_provider.dart';
import '../theme/rufko_theme.dart';
import 'simplified_quote_screen.dart';
import 'simplified_quote_detail_screen.dart';
import '../mixins/file_sharing_mixin.dart';
import '../mixins/communication_actions_mixin.dart';
import '../mixins/customer_communication_mixin.dart';
import 'customer_detail/media_tab_controller.dart';
import 'customer_detail/customer_edit_dialog.dart';
import 'customer_detail/quotes_tab.dart';
import 'customer_detail/media_tab.dart';
import 'customer_detail/info_tab.dart';
import 'customer_detail/inspection_tab.dart';
import '../controllers/communication_controller.dart';

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
    with
        TickerProviderStateMixin,
        FileSharingMixin,
        CommunicationActionsMixin,
        CustomerCommunicationMixin {
  late TabController _tabController;
  final TextEditingController _communicationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessingMedia = false;


  // Multi-select state for media
  bool _isSelectionMode = false;
  Set<String> _selectedMediaIds = <String>{};
  late MediaTabController _mediaController;
  late CommunicationController _commController;

  @override
  Customer get customer => widget.customer;

  @override
  void previewAndSendSMS(dynamic template) => _previewAndSendSMS(template);

  @override
  void previewAndSendEmail(dynamic template) => _previewAndSendEmail(template);

  @override
  void initState() {
    super.initState();
    _mediaController = MediaTabController(
      context: context,
      customer: widget.customer,
      imagePicker: _imagePicker,
      setProcessingState: (processing) {
        setState(() => _isProcessingMedia = processing);
      },
      shareFile: ({required File file, required String fileName, String? description, Customer? customer, String? fileType}) {
        return shareFile(file: file, fileName: fileName, description: description, customer: customer, fileType: fileType);
      },
      showErrorSnackBar: showErrorSnackBar,
    );
    _commController = CommunicationController(
      context: context,
      customer: widget.customer,
      onUpdated: () {
        if (mounted) setState(() {});
      },
    );
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
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

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

                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${itemsToDelete.length} file${itemsToDelete.length == 1 ? '' : 's'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                navigator.pop();
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
                    formatDate: formatCommunicationDate,
                    onTemplateEmail: showTemplateEmailPicker,
                    onTemplateSMS: showTemplateSMSPicker,
                    onQuickCommunication: showQuickCommunicationOptions,
                    onAddCommunication: addCommunication,
                  ),
                  QuotesTab(
                    customer: widget.customer,
                    onCreateQuote: _navigateToCreateQuoteScreen,
                    onOpenQuote: _navigateToSimplifiedQuoteDetail,
                  ),
                  InspectionTab(customer: widget.customer), // NEW
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
                    onPickImageFromCamera: _mediaController.pickImageFromCamera,
                    onPickImageFromGallery: _mediaController.pickImageFromGallery,
                    onPickDocument: _mediaController.pickDocument,
                    onViewMedia: _mediaController.viewMedia,
                    onShowContextMenu: _mediaController.showMediaContextMenu,
                    onShowMediaOptions: _mediaController.showMediaOptions,
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
              onPressed: _mediaController.showMediaOptions,
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
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RufkoTheme.primaryColor,
                RufkoTheme.primaryDarkColor,
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

  void _previewAndSendSMS(dynamic template) {
    final customerData = _commController.buildCustomerDataMap();

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
    _commController.sendTemplateSMS(template, message);
    setState(() {});
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
    final customerData = _commController.buildCustomerDataMap();

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
    _commController.sendTemplateEmail(template, subject, content);
    setState(() {});
  }

  // MEDIA FUNCTIONALITY METHODS



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
                _mediaController.showMediaOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.purple),
              title: const Text('Quick Communication'),
              onTap: () {
                Navigator.pop(context);
                showQuickCommunicationOptions();
              },
            ),
          ],
        ),
      ),
    );
  } // <-- Proper closing brace for _showQuickActions

  // REAL COMMUNICATION METHODS MOVED TO MIXIN



}
