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
import 'media_details_dialog.dart';
import '../../../quotes/presentation/screens/pdf_preview_screen.dart';
import 'full_screen_image_viewer.dart';

class MediaTabController {
  MediaTabController({
    required this.context,
    required this.customer,
    required this.imagePicker,
    required this.setProcessingState,
    required this.shareFile,
    required this.showErrorSnackBar,
  });

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

  void showMediaOptions() {
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
                  color: Colors.blueAccent.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
              ),
              title: const Text('Take Multiple Photos'),
              subtitle: const Text('Take several photos in sequence'),
              onTap: () {
                Navigator.pop(context);
                takeMultiplePhotos();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: Colors.green.shade700),
              ),
              title: const Text('Select Multiple Photos'),
              subtitle: const Text('Choose multiple photos from gallery'),
              onTap: () {
                Navigator.pop(context);
                pickMultipleImages();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.file_upload, color: Colors.orange.shade700),
              ),
              title: const Text('Upload Documents'),
              subtitle: const Text('Select PDF, Word, Excel files'),
              onTap: () {
                Navigator.pop(context);
                pickMultipleDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> takeMultiplePhotos() async {
    final List<File> photos = [];

    while (true) {
      try {
        final XFile? image = await imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (!context.mounted) return;

        if (image != null) {
          photos.add(File(image.path));

          final bool takeAnother = await showDialog<bool>(
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
              ) ??
              false;

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
      await processBulkMedia(photos, 'image');
    }
  }

  Future<void> pickMultipleImages() async {
    try {
      final List<XFile> images = await imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final List<File> files = images.map((xfile) => File(xfile.path)).toList();
        await processBulkMedia(files, 'image');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting images: $e');
    }
  }

  Future<void> pickMultipleDocuments() async {
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

        if (files.isNotEmpty) {
          await processBulkMedia(files, 'document');
        }
      }
    } catch (e) {
      showErrorSnackBar('Error selecting documents: $e');
    }
  }

  Future<void> processBulkMedia(List<File> files, String defaultType) async {
    if (files.isEmpty) return;

    final String? selectedCategory =
        await _showBulkCategoryDialog(files.length, defaultType);

    if (selectedCategory == null) return;

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setProcessingState(true);

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
          } else if ([
            '.jpg',
            '.jpeg',
            '.png',
            '.gif',
            '.webp',
            '.bmp'
          ].contains(fileExtension)) {
            fileType = 'image';
          }

          final mediaItem = ProjectMedia(
            customerId: customer.id,
            filePath: file.path,
            fileName: fileName,
            fileType: fileType,
            category: selectedCategory,
            fileSizeBytes: fileSize,
          );

          if (!context.mounted) return;
          await context.read<AppStateProvider>().addProjectMedia(mediaItem);
          successCount++;
        } catch (e) {
          debugPrint('Error processing file ${file.path}: $e');
        }
      }

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Added $successCount of ${files.length} files'),
            backgroundColor:
                successCount == files.length ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      showErrorSnackBar('Error processing files: $e');
    } finally {
      if (context.mounted) {
        setProcessingState(false);
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
                    child: Text(getFormattedCategoryName(category)),
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

  String getFormattedCategoryName(String category) {
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
        return category
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await processSelectedMedia(File(image.path), 'image');
      }
    } catch (e) {
      showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await processSelectedMedia(File(image.path), 'image');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        await processSelectedMedia(file, 'document');
      }
    } catch (e) {
      showErrorSnackBar('Error selecting document: $e');
    }
  }

  Future<void> processSelectedMedia(File file, String fileType) async {
    setProcessingState(true);

    try {
      final fileSize = await file.length();

      if (!context.mounted) return;

      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      String detectedType = fileType;
      if (fileExtension == '.pdf') {
        detectedType = 'pdf';
      } else if ([
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.bmp'
      ].contains(fileExtension)) {
        detectedType = 'image';
      }

      final messenger = ScaffoldMessenger.of(context);
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
          messenger.showSnackBar(
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
      if (context.mounted) {
        setProcessingState(false);
      }
    }
  }

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
          showErrorSnackBar('Cannot open file: ${result.message}');
        }
      }
    } catch (e) {
      showErrorSnackBar('Error opening media: $e');
    }
  }

  void showMediaContextMenu(ProjectMedia mediaItem) {
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
                  viewMedia(mediaItem);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Details'),
              onTap: () {
                Navigator.pop(context);
                editMediaDetails(mediaItem);
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
                  customer: customer,
                  fileType: mediaItem.fileType,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                deleteMedia(mediaItem);
              },
            ),
          ],
        ),
      ),
    );
  }

  void editMediaDetails(ProjectMedia mediaItem) {
    showDialog(
      context: context,
      builder: (context) => MediaDetailsDialog.edit(
        mediaItem: mediaItem,
        onSave: (updatedMedia) async {
          final messenger = ScaffoldMessenger.of(context);
          await context.read<AppStateProvider>().updateProjectMedia(updatedMedia);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Media details updated'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void deleteMedia(ProjectMedia mediaItem) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete "${mediaItem.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final file = File(mediaItem.filePath);
                if (await file.exists()) {
                  await file.delete();
                }

                if (!context.mounted) return;
                await context.read<AppStateProvider>().deleteProjectMedia(mediaItem.id);
                if (!context.mounted) return;

                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${mediaItem.fileName}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                navigator.pop();
                showErrorSnackBar('Error deleting media: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
