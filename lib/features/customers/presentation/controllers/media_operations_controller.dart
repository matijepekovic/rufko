import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/media/project_media.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../widgets/media_details_dialog.dart';
import '../../../quotes/presentation/screens/pdf_preview_screen.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../../../../core/services/media/media_processing_service.dart';
import '../widgets/media/camera_capture_screen.dart';
import '../../../../core/services/media/media_file_service.dart';

/// Controller for managing media operations and state
/// Extracted from MediaTabController to separate business logic from UI
class MediaOperationsController extends ChangeNotifier {
  final BuildContext context;
  final Customer customer;
  final ImagePicker imagePicker;

  // State variables
  bool _isProcessing = false;
  String? _error;

  MediaOperationsController({
    required this.context,
    required this.customer,
    required this.imagePicker,
  });

  // Getters
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  // Setters with notification
  set isProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Take multiple photos with embedded camera preview
  Future<List<File>> takeMultiplePhotos() async {
    // Navigate directly to camera capture screen
    final List<File>? photos = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraCaptureScreen(),
        fullscreenDialog: true,
      ),
    );

    if (photos != null && photos.isNotEmpty) {
      debugPrint('📸 Captured ${photos.length} photos');
      return photos;
    }

    return [];
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      final List<File> files = images.map((xfile) => File(xfile.path)).toList();
      debugPrint('🖼️ Selected ${files.length} images');
      return files;
    } catch (e) {
      _error = 'Error selecting images: $e';
      notifyListeners();
      return [];
    }
  }

  /// Pick multiple documents
  Future<List<File>> pickMultipleDocuments() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<File> files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        debugPrint('📄 Selected ${files.length} documents');
        return files;
      }
      return [];
    } catch (e) {
      _error = 'Error selecting documents: $e';
      notifyListeners();
      return [];
    }
  }

  /// Pick single image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('📸 Took photo from camera');
        return File(image.path);
      }
      return null;
    } catch (e) {
      _error = 'Error taking photo: $e';
      notifyListeners();
      return null;
    }
  }

  /// Pick single image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('🖼️ Selected image from gallery');
        return File(image.path);
      }
      return null;
    } catch (e) {
      _error = 'Error selecting image: $e';
      notifyListeners();
      return null;
    }
  }

  /// Pick single document
  Future<File?> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        debugPrint('📄 Selected document');
        return file;
      }
      return null;
    } catch (e) {
      _error = 'Error selecting document: $e';
      notifyListeners();
      return null;
    }
  }

  /// Process bulk media files with category selection
  Future<void> processBulkMedia(List<File> files, String defaultType) async {
    if (files.isEmpty) return;

    final String? selectedCategory = await _showBulkCategoryDialog(files.length, defaultType);
    if (selectedCategory == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      if (!context.mounted) return;
      // Business logic extracted to service
      final result = await MediaFileService.processBulkMedia(
        files: files,
        customerId: customer.id,
        defaultType: defaultType,
        selectedCategory: selectedCategory,
        appState: context.read<AppStateProvider>(),
        createMediaItem: (file, customerId, defaultType, category) => 
          MediaProcessingService.createMediaItemFromFile(
            file: file,
            customerId: customerId,
            defaultType: defaultType,
            category: category,
          ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.isSuccess 
              ? 'Added ${result.successCount} of ${files.length} files'
              : result.errorMessage ?? 'Error processing files'),
            backgroundColor: result.isSuccess && result.successCount == files.length 
              ? Colors.green 
              : Colors.orange,
          ),
        );
      }

      debugPrint('✅ Processed ${result.successCount ?? 0} of ${files.length} files');
    } catch (e) {
      _error = 'Error processing files: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Process single media file with dialog
  Future<void> processSelectedMedia(File file, String fileType) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final fileSize = await file.length();
      final fileName = path.basename(file.path);
      final detectedType = _detectFileType(fileName, fileType);

      if (!context.mounted) return;

      final ProjectMedia? mediaItem = await showDialog<ProjectMedia>(
        context: context,
        barrierDismissible: false,
        builder: (context) => MediaDetailsDialog(
          file: file,
          fileName: fileName,
          fileType: detectedType,
          fileSize: fileSize,
          customerId: customer.id,
        ),
      );

      if (!context.mounted) return;

      if (mediaItem != null) {
        await context.read<AppStateProvider>().addProjectMedia(mediaItem);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${mediaItem.fileName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        debugPrint('✅ Added media: ${mediaItem.fileName}');
      }
    } catch (e) {
      _error = 'Error processing media: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }


  /// Detect file type from extension
  String _detectFileType(String fileName, String defaultType) {
    // Business logic extracted to service
    return MediaProcessingService.detectFileType(fileName, defaultType);
  }

  /// Show bulk category selection dialog
  Future<String?> _showBulkCategoryDialog(int fileCount, String defaultType) async {
    // Business logic extracted to service
    String selectedCategory = MediaProcessingService.getDefaultCategory(defaultType);

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
                items: MediaProcessingService.getValidCategoriesForFileType(defaultType).map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(MediaProcessingService.getFormattedCategoryName(category)),
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

  /// Get formatted category name with emoji
  String getFormattedCategoryName(String category) {
    // Business logic extracted to service
    return MediaProcessingService.getFormattedCategoryName(category);
  }

  /// View media with appropriate viewer
  Future<void> viewMedia(ProjectMedia mediaItem) async {
    try {
      if (mediaItem.isImage) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(mediaItem: mediaItem),
          ),
        );
      } else if (mediaItem.isPdf) {
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
        final result = await OpenFilex.open(mediaItem.filePath);
        if (result.type != ResultType.done) {
          _error = 'Cannot open file: ${result.message}';
          notifyListeners();
        }
      }
      debugPrint('👁️ Viewed media: ${mediaItem.fileName}');
    } catch (e) {
      _error = 'Error opening media: $e';
      notifyListeners();
    }
  }

  /// Edit media details
  Future<void> editMediaDetails(ProjectMedia mediaItem) async {
    showDialog(
      context: context,
      builder: (context) => MediaDetailsDialog.edit(
        mediaItem: mediaItem,
        onSave: (updatedMedia) async {
          // Business logic extracted to service
          final result = await MediaFileService.updateMedia(
            updatedMedia: updatedMedia,
            appState: context.read<AppStateProvider>(),
          );
          
          if (!context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(result.isSuccess 
                ? 'Media details updated'
                : result.errorMessage ?? 'Error updating media'),
              backgroundColor: result.isSuccess ? Colors.green : Colors.red,
            ),
          );
          debugPrint('✏️ Updated media: ${updatedMedia.fileName}');
        },
      ),
    );
  }

  /// Delete media with confirmation
  Future<void> deleteMedia(ProjectMedia mediaItem) async {
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete "${mediaItem.fileName}"?'),
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

    if (confirmed == true && context.mounted) {
      // Business logic extracted to service
      final result = await MediaFileService.deleteMedia(
        mediaItem: mediaItem,
        appState: context.read<AppStateProvider>(),
      );

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.isSuccess 
              ? 'Deleted ${mediaItem.fileName}'
              : result.errorMessage ?? 'Error deleting media'),
            backgroundColor: result.isSuccess ? Colors.red : Colors.orange,
          ),
        );
      }
      
      if (!result.isSuccess) {
        _error = result.errorMessage;
        notifyListeners();
      }
      
      debugPrint('🗑️ Deleted media: ${mediaItem.fileName}');
    }
  }

  /// Share file with external apps
  Future<void> shareMedia({
    required File file,
    required String fileName,
    String? description,
    String? fileType,
  }) async {
    try {
      // This would be implemented with the share functionality
      // For now, just log the action
      debugPrint('📤 Sharing media: $fileName');
    } catch (e) {
      _error = 'Error sharing media: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🧹 MediaOperationsController disposed');
    super.dispose();
  }
}