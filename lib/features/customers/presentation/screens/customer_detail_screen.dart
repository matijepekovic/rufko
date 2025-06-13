// lib/screens/customer_detail_screen.dart - COMPLETE WITH MEDIA FUNCTIONALITY + MULTI-SELECT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/helpers/common_utils.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

import '../../../../core/mixins/business/file_sharing_mixin.dart';
import '../../../../core/mixins/business/communication_actions_mixin.dart';
import '../../../../core/mixins/business/customer_communication_mixin.dart';
import '../widgets/media_tab_controller.dart';
import '../../../media/presentation/controllers/media_selection_controller.dart';
import '../../../../shared/controllers/navigation_controller.dart';
import '../controllers/customer_actions_controller.dart';
import '../../../../shared/controllers/ui_state_controller.dart';
import '../widgets/tabs/quotes_tab.dart';
import '../widgets/tabs/media_tab.dart';
import '../widgets/tabs/info_tab.dart';
import '../widgets/tabs/inspection_tab.dart';
import '../../../communication/presentation/controllers/communication_controller.dart';
import '../../../communication/presentation/controllers/communication_dialog_controller.dart';
import '../../../communication/presentation/widgets/dialogs/sms_preview_dialog.dart';
import '../../../communication/presentation/widgets/dialogs/sms_edit_dialog.dart';
import '../../../communication/presentation/widgets/dialogs/email_preview_dialog.dart';
import '../../../communication/presentation/widgets/dialogs/email_edit_dialog.dart';

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
  final TextEditingController _communicationController =
      TextEditingController();
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
    _uiController =
        UIStateController(vsync: this, onUpdate: () => setState(() {}));
    _mediaController = MediaTabController(
      context: context,
      customer: widget.customer,
      imagePicker: _imagePicker,
      setProcessingState: _uiController.setProcessingState,
      shareFile: (
          {required File file,
          required String fileName,
          String? description,
          Customer? customer,
          String? fileType}) {
        return shareFile(
            file: file,
            fileName: fileName,
            description: description,
            customer: customer,
            fileType: fileType);
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
    _navigationController =
        NavigationController(context: context, customer: widget.customer);
    _selectionController = MediaSelectionController(
      context: context,
      customer: widget.customer,
      showErrorSnackBar: showErrorSnackBar,
      onStateChanged: () => setState(() {}),
    );
    _actionsController = CustomerActionsController(
      context: context,
      customer: widget.customer,
      navigateToCreateQuoteScreen:
          _navigationController.navigateToCreateQuoteScreen,
      mediaController: _mediaController,
      showQuickCommunicationOptions: showQuickCommunicationOptions,
      onUpdated: () => setState(() {}),
    );

    _uiController.tabController.addListener(() {
      if (_selectionController.isSelectionMode &&
          _uiController.tabController.index != 3) {
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
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
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
                    onCreateQuote:
                        _navigationController.navigateToCreateQuoteScreen,
                    onOpenQuote:
                        _navigationController.navigateToSimplifiedQuoteDetail,
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
                    onToggleSelection:
                        _selectionController.toggleMediaSelection,
                    onDeleteSelected: _selectionController.deleteSelectedMedia,
                    onPickImageFromCamera: _mediaController.pickImageFromCamera,
                    onPickImageFromGallery:
                        _mediaController.pickImageFromGallery,
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
    final dialogController = CommunicationDialogController(
      commController: _commController,
      template: template,
    )..generateSmsPreview();

    showDialog(
      context: context,
      builder: (context) => SmsPreviewDialog(
        controller: dialogController,
        onEdit: () => _editSMSBeforeSending(dialogController),
      ),
    );
  }

  void _editSMSBeforeSending(CommunicationDialogController controller) {
    showDialog(
      context: context,
      builder: (context) => SmsEditDialog(controller: controller),
    );
  }

  void _previewAndSendEmail(dynamic template) {
    final dialogController = CommunicationDialogController(
      commController: _commController,
      template: template,
    )..generateEmailPreview();

    showDialog(
      context: context,
      builder: (context) => EmailPreviewDialog(
        controller: dialogController,
        onEdit: () => _editEmailBeforeSending(dialogController),
      ),
    );
  }

  void _editEmailBeforeSending(CommunicationDialogController controller) {
    showDialog(
      context: context,
      builder: (context) => EmailEditDialog(controller: controller),
    );
  }

  // MEDIA FUNCTIONALITY METHODS

  // HELPER METHODS

  // showErrorSnackBar provided by CommunicationActionsMixin

  // Customer action methods moved to CustomerActionsController

  // REAL COMMUNICATION METHODS MOVED TO MIXIN
}
