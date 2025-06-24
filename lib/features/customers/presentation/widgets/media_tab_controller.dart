import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/media/project_media.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../controllers/media_operations_controller.dart';
import 'media/upload_options_sheet.dart';
import 'media/media_context_menu.dart';
import '../../../quotes/presentation/screens/pdf_preview_screen.dart';

/// Refactored MediaTabController with extracted components and controller
/// Original 651-line monolithic controller broken down into manageable components
/// All original functionality preserved with improved maintainability
class MediaTabController {
  final BuildContext context;
  final Customer customer;
  final ImagePicker imagePicker;
  final void Function(bool) setProcessingState;
  final Future<void> Function({
    required File file,
    required String fileName,
    String? description,
    Customer? customer,
    String? fileType,
  }) shareFile;
  final void Function(String) showErrorSnackBar;

  late final MediaOperationsController _controller;

  MediaTabController({
    required this.context,
    required this.customer,
    required this.imagePicker,
    required this.setProcessingState,
    required this.shareFile,
    required this.showErrorSnackBar,
  }) {
    _controller = MediaOperationsController(
      context: context,
      customer: customer,
      imagePicker: imagePicker,
    );
    
    // Listen to controller changes and update processing state
    _controller.addListener(_onControllerChanged);
  }

  /// Handle controller state changes
  void _onControllerChanged() {
    setProcessingState(_controller.isProcessing);
    
    if (_controller.error != null) {
      showErrorSnackBar(_controller.error!);
      _controller.clearError();
    }
  }

  /// Show upload options bottom sheet (gallery and documents only)
  void showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => UploadOptionsSheet(
        onSelectMultiplePhotos: _handleSelectMultiplePhotos,
        onUploadDocuments: _handleUploadDocuments,
      ),
    );
  }
  
  /// Take photos directly without showing options sheet
  Future<void> takePhotosDirectly() async {
    await _handleTakeMultiplePhotos();
  }

  /// Handle taking multiple photos
  Future<void> _handleTakeMultiplePhotos() async {
    final photos = await _controller.takeMultiplePhotos();
    if (photos.isNotEmpty) {
      await _controller.processBulkMedia(photos, 'image');
    }
  }

  /// Handle selecting multiple photos
  Future<void> _handleSelectMultiplePhotos() async {
    final photos = await _controller.pickMultipleImages();
    if (photos.isNotEmpty) {
      await _controller.processBulkMedia(photos, 'image');
    }
  }

  /// Handle uploading documents
  Future<void> _handleUploadDocuments() async {
    final documents = await _controller.pickMultipleDocuments();
    if (documents.isNotEmpty) {
      await _controller.processBulkMedia(documents, 'document');
    }
  }

  /// Preserved original method for backward compatibility
  Future<void> takeMultiplePhotos() async {
    await _handleTakeMultiplePhotos();
  }

  /// Preserved original method for backward compatibility
  Future<void> pickMultipleImages() async {
    await _handleSelectMultiplePhotos();
  }

  /// Preserved original method for backward compatibility
  Future<void> pickMultipleDocuments() async {
    await _handleUploadDocuments();
  }

  /// Preserved original method for backward compatibility
  Future<void> processBulkMedia(List<File> files, String defaultType) async {
    await _controller.processBulkMedia(files, defaultType);
  }

  /// Preserved original method for backward compatibility
  String getFormattedCategoryName(String category) {
    return _controller.getFormattedCategoryName(category);
  }

  /// Preserved original method for backward compatibility
  Future<void> pickImageFromCamera() async {
    final file = await _controller.pickImageFromCamera();
    if (file != null) {
      await _controller.processSelectedMedia(file, 'image');
    }
  }

  /// Preserved original method for backward compatibility
  Future<void> pickImageFromGallery() async {
    final file = await _controller.pickImageFromGallery();
    if (file != null) {
      await _controller.processSelectedMedia(file, 'image');
    }
  }

  /// Preserved original method for backward compatibility
  Future<void> pickDocument() async {
    final file = await _controller.pickDocument();
    if (file != null) {
      await _controller.processSelectedMedia(file, 'document');
    }
  }

  /// Preserved original method for backward compatibility
  Future<void> processSelectedMedia(File file, String fileType) async {
    await _controller.processSelectedMedia(file, fileType);
  }

  /// View media with appropriate viewer
  Future<void> viewMedia(ProjectMedia mediaItem) async {
    await _controller.viewMedia(mediaItem);
  }

  /// Show context menu for media operations
  void showMediaContextMenu(ProjectMedia mediaItem) {
    showModalBottomSheet(
      context: context,
      builder: (context) => MediaContextMenu(
        mediaItem: mediaItem,
        onView: () => _handleViewMedia(mediaItem),
        onEdit: () => _controller.editMediaDetails(mediaItem),
        onDelete: () => _controller.deleteMedia(mediaItem),
        onShare: _controller.shareMedia,
      ),
    );
  }

  /// Handle viewing media with PDF special case
  void _handleViewMedia(ProjectMedia mediaItem) {
    if (mediaItem.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: mediaItem.filePath,
            suggestedFileName: mediaItem.fileName,
            customer: customer,
            quote: mediaItem.quoteId != null
                ? context
                    .read<AppStateProvider>()
                    .getSimplifiedQuotesForCustomer(customer.id)
                    .firstWhere((q) => q.id == mediaItem.quoteId, orElse: () => null as dynamic)
                : null,
            title: mediaItem.description ?? mediaItem.fileName,
            isPreview: true,
          ),
        ),
      );
    } else {
      _controller.viewMedia(mediaItem);
    }
  }

  /// Preserved original method for backward compatibility
  void editMediaDetails(ProjectMedia mediaItem) {
    _controller.editMediaDetails(mediaItem);
  }

  /// Preserved original method for backward compatibility
  void deleteMedia(ProjectMedia mediaItem) {
    _controller.deleteMedia(mediaItem);
  }

  /// Dispose of resources
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
  }
}