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
import '../controllers/media_selection_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/customer_actions_controller.dart';
import '../controllers/ui_state_controller.dart';
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
  late UIStateController _uiController;
  late MediaSelectionController _selectionController;
  late NavigationController _navigationController;
  late CustomerActionsController _actionsController;
  final TextEditingController _communicationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
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
    _uiController = UIStateController(vsync: this, onUpdate: () => setState(() {}));
    _mediaController = MediaTabController(
      context: context,
      customer: widget.customer,
      imagePicker: _imagePicker,
      setProcessingState: _uiController.setProcessingState,
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
    _navigationController = NavigationController(context: context, customer: widget.customer);
    _selectionController = MediaSelectionController(
      context: context,
      customer: widget.customer,
      showErrorSnackBar: showErrorSnackBar,
      onStateChanged: () => setState(() {}),
    );
    _actionsController = CustomerActionsController(
      context: context,
      customer: widget.customer,
      navigateToCreateQuoteScreen: _navigationController.navigateToCreateQuoteScreen,
      mediaController: _mediaController,
      showQuickCommunicationOptions: showQuickCommunicationOptions,
      onUpdated: () => setState(() {}),
    );

    _uiController.tabController.addListener(() {
      if (_selectionController.isSelectionMode && _uiController.tabController.index != 3) {
        _selectionController.exitSelectionMode();
      }

    });

  }





  @override
  void dispose() {
    _uiController.dispose();
    _communicationController.dispose();
    super.dispose();
  }

  // SELECTION MODE METHODS ARE HANDLED BY MediaSelectionController

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectionController.isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_selectionController.isSelectionMode) {
            _selectionController.exitSelectionMode();
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
                controller: _uiController.tabController,
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
                    onCreateQuote: _navigationController.navigateToCreateQuoteScreen,
                    onOpenQuote: _navigationController.navigateToSimplifiedQuoteDetail,
                  ),
                  InspectionTab(customer: widget.customer), // NEW
                  MediaTab(
                    customer: widget.customer,
                    isProcessing: _uiController.isProcessingMedia,
                    isSelectionMode: _selectionController.isSelectionMode,
                    selectedMediaIds: _selectionController.selectedMediaIds,
                    onEnterSelection: _selectionController.enterSelectionMode,
                    onExitSelection: _selectionController.exitSelectionMode,
                    onSelectAll: _selectionController.selectAllMedia,
                    onToggleSelection: _selectionController.toggleMediaSelection,
                    onDeleteSelected: _selectionController.deleteSelectedMedia,
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
      animation: _uiController.tabController,
      builder: (context, child) {
        return _uiController.buildFloatingActionButton(
          isSelectionMode: _selectionController.isSelectionMode,
          selectedMediaIds: _selectionController.selectedMediaIds,
          deleteSelectedMedia: _selectionController.deleteSelectedMedia,
          exitSelectionMode: _selectionController.exitSelectionMode,
          navigateToCreateQuoteScreen:
              _navigationController.navigateToCreateQuoteScreen,
          showMediaOptions: _mediaController.showMediaOptions,
        );
      },
    );
  }
  Widget _buildModernSliverAppBar(AppStateProvider appState) {
    return _uiController.buildModernSliverAppBar(
      appState,
      isSelectionMode: _selectionController.isSelectionMode,
      enterSelectionMode: _selectionController.enterSelectionMode,
      navigateToCreateQuoteScreen:
          _navigationController.navigateToCreateQuoteScreen,
      editCustomer: _actionsController.editCustomer,
      deleteCustomer: _actionsController.showDeleteCustomerConfirmation,
      showQuickActions: _actionsController.showQuickActions,
      selectedMediaIds: _selectionController.selectedMediaIds,
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


  

  // Customer action methods moved to CustomerActionsController

  // REAL COMMUNICATION METHODS MOVED TO MIXIN



}
