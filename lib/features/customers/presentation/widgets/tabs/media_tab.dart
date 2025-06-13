import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../core/utils/helpers/common_utils.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/media/project_media.dart';
import '../../../../../data/providers/state/app_state_provider.dart';

class MediaTab extends StatelessWidget {
  final Customer customer;
  final bool isProcessing;
  final bool isSelectionMode;
  final Set<String> selectedMediaIds;
  final VoidCallback onEnterSelection;
  final VoidCallback onExitSelection;
  final VoidCallback onSelectAll;
  final void Function(String) onToggleSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onPickImageFromCamera;
  final VoidCallback onPickImageFromGallery;
  final VoidCallback onPickDocument;
  final void Function(ProjectMedia) onViewMedia;
  final void Function(ProjectMedia) onShowContextMenu;
  final VoidCallback onShowMediaOptions;

  const MediaTab({
    super.key,
    required this.customer,
    required this.isProcessing,
    required this.isSelectionMode,
    required this.selectedMediaIds,
    required this.onEnterSelection,
    required this.onExitSelection,
    required this.onSelectAll,
    required this.onToggleSelection,
    required this.onDeleteSelected,
    required this.onPickImageFromCamera,
    required this.onPickImageFromGallery,
    required this.onPickDocument,
    required this.onViewMedia,
    required this.onShowContextMenu,
    required this.onShowMediaOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final mediaItems = appState.getProjectMediaForCustomer(customer.id);
        mediaItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (isProcessing) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing media...'),
              ],
            ),
          );
        }

        if (mediaItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.perm_media_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No media files for this customer.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onPickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onPickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onPickDocument,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Upload Document'),
                    ),
                  ],
                )
              ],
            ),
          );
        }

        final photos = mediaItems.where((m) => m.isImage).toList();
        final documents = mediaItems.where((m) => !m.isImage).toList();

        final photoCategories = <String, List<ProjectMedia>>{
          'before_photos': [],
          'after_photos': [],
          'inspection_photos': [],
          'progress_photos': [],
          'damage_report': [],
          'other_photos': [],
        };

        for (final photo in photos) {
          if (photoCategories.containsKey(photo.category)) {
            photoCategories[photo.category]!.add(photo);
          } else {
            photoCategories['other_photos']!.add(photo);
          }
        }

        photoCategories.removeWhere((key, value) => value.isEmpty);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Media Files (${mediaItems.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isSelectionMode)
                    ElevatedButton.icon(
                      onPressed: onEnterSelection,
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('Select'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: onSelectAll,
                          icon: const Icon(Icons.select_all, size: 18),
                          label: Text(
                            selectedMediaIds.length == mediaItems.length ? 'Deselect All' : 'Select All',
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: onExitSelection,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMediaStat(context, 'Total Files', '${mediaItems.length}', Icons.folder),
                      _buildMediaStat(context, 'Photos', '${photos.length}', Icons.image),
                      _buildMediaStat(context, 'Documents', '${documents.length}', Icons.description),
                    ],
                  ),
                ),
              ),
              if (isSelectionMode) ...[
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedMediaIds.isEmpty
                                ? 'Tap files to select them'
                                : '${selectedMediaIds.length} of ${mediaItems.length} files selected',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selectedMediaIds.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: onDeleteSelected,
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (photos.isNotEmpty) ...[
                _buildMediaTypeHeader(context, 'Photos', Icons.image, photos.length, Colors.blue),
                const SizedBox(height: 16),
                ...photoCategories.entries.map((entry) {
                  return _buildMediaSubsection(context, entry.key, entry.value);
                }),
                const SizedBox(height: 24),
              ],
              if (documents.isNotEmpty) ...[
                _buildMediaTypeHeader(context, 'Documents', Icons.description, documents.length, Colors.orange),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final isSelected = selectedMediaIds.contains(document.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          document.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                          color: document.isPdf ? Colors.red : Colors.grey[600],
                        ),
                        title: Text(document.fileName),
                        subtitle: Text('${document.formattedFileSize} • ${DateFormat('MMM dd').format(document.createdAt)}'),
                        trailing: isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) => onToggleSelection(document.id),
                              )
                            : null,
                        selected: isSelected,
                        onTap: isSelectionMode ? () => onToggleSelection(document.id) : () => onViewMedia(document),
                        onLongPress: !isSelectionMode ? () => onShowContextMenu(document) : null,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildMediaTypeHeader(BuildContext context, String label, IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMediaSubsection(BuildContext context, String category, List<ProjectMedia> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                formatPhotoCategoryName(category),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text('(${items.length})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onShowMediaOptions(),
                icon: const Icon(Icons.fullscreen, size: 14),
                label: const Text('View All'),
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
              final mediaItem = items[index];
              final isSelected = selectedMediaIds.contains(mediaItem.id);
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: _buildCompactMediaCard(context, mediaItem, isSelected),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCompactMediaCard(BuildContext context, ProjectMedia mediaItem, bool isSelected) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: isSelectionMode ? () => onToggleSelection(mediaItem.id) : () => onViewMedia(mediaItem),
            onLongPress: !isSelectionMode ? () => onShowContextMenu(mediaItem) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: isSelected ? Colors.blue.withAlpha(50) : Colors.grey[200],
                    child: mediaItem.isImage
                        ? (File(mediaItem.filePath).existsSync()
                            ? Image.file(File(mediaItem.filePath), fit: BoxFit.cover)
                            : Icon(Icons.broken_image, size: 32, color: Colors.grey[400]))
                        : Icon(
                            mediaItem.isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  color: isSelected ? Colors.blue.withAlpha(20) : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mediaItem.fileName,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? Colors.blue.shade800 : null),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        mediaItem.formattedFileSize,
                        style: TextStyle(fontSize: 8, color: isSelected ? Colors.blue.shade600 : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => onToggleSelection(mediaItem.id),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // formatPhotoCategoryName moved to common_utils.dart
}
