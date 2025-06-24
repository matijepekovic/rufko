import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../data/models/media/project_media.dart';
import '../../../../core/utils/helpers/common_utils.dart';
import '../../../../core/services/media/media_processing_service.dart';
import '../../../../shared/widgets/buttons/rufko_dialog_actions.dart';
class MediaDetailsDialog extends StatefulWidget {
  final File? file;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String customerId; // Non-nullable
  final ProjectMedia? mediaItem;
  final Function(ProjectMedia)? onSave;

  // Default constructor (can remain const if customerId is the only varying part among final fields)
  const MediaDetailsDialog({
    super.key,
    this.file,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.customerId,
  })  : mediaItem = null,
        onSave = null;

  // Edit constructor - REMOVE CONST HERE
  MediaDetailsDialog.edit({ // <<<< REMOVED 'const'
    super.key,
    required this.mediaItem,
    required this.onSave,
  })  : file = null,
        fileName = null,
        fileType = null,
        fileSize = null,
        customerId = mediaItem!.customerId; // This is now valid in a non-const constructor

  @override
  State<MediaDetailsDialog> createState() => _MediaDetailsDialogState();
}

class _MediaDetailsDialogState extends State<MediaDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedCategory = 'general';
  List<String> _tags = [];

  List<String> get _categories {
    if (widget.fileType != null) {
      // Filter categories based on file type
      return MediaProcessingService.getValidCategoriesForFileType(widget.fileType!);
    } else if (widget.mediaItem != null) {
      // For editing existing media, show all categories
      return MediaProcessingService.getCategories();
    } else {
      // Fallback to all categories
      return MediaProcessingService.getCategories();
    }
  }

  bool get _isEditing => widget.mediaItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final media = widget.mediaItem!;
      _descriptionController.text = media.description ?? '';
      _selectedCategory = media.category;
      _tags = List.from(media.tags);
    } else {
      // Set default category based on file type
      if (widget.fileType != null) {
        _selectedCategory = MediaProcessingService.getDefaultCategory(widget.fileType!);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.add_photo_alternate,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Media Details' : 'Add Media Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File preview/info
                      if (!_isEditing && widget.file != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: widget.fileType == 'image'
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      widget.file!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.broken_image, color: Colors.grey[400]);
                                      },
                                    ),
                                  )
                                      : Icon(
                                    widget.fileType == 'pdf'
                                        ? Icons.picture_as_pdf
                                        : Icons.insert_drive_file,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.fileName ?? 'Unknown file',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        widget.fileSize != null
                                            ? formatFileSize(widget.fileSize!)
                                            : 'Unknown size',
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
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Category selection
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(formatCategoryName(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value ?? 'general';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Add a description...',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Text(
                        'Tags',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag),
                                hintText: 'Add a tag and press Enter',
                              ),
                              onFieldSubmitted: _addTag,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _addTag(_tagController.text),
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeTag(tag),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: RufkoDialogActions(
                onCancel: () => Navigator.pop(context),
                onConfirm: _saveMedia,
                confirmText: _isEditing ? 'Update' : 'Add Media',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveMedia() {
    if (_isEditing) {
      // Update existing media
      final updatedMedia = widget.mediaItem!;
      updatedMedia.updateDetails(
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
      );

      widget.onSave?.call(updatedMedia);
      Navigator.pop(context);
    } else {
      // Create new media
      final mediaItem = ProjectMedia(
        customerId: widget.customerId,
        filePath: widget.file!.path,
        fileName: widget.fileName!,
        fileType: widget.fileType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        fileSizeBytes: widget.fileSize,
      );

      Navigator.pop(context, mediaItem);
    }
  }

}

