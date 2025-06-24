import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../data/models/media/project_media.dart';
import '../../../../../core/utils/helpers/common_utils.dart';

class MediaGrid extends StatelessWidget {
  final List<ProjectMedia> mediaItems;
  final Map<String, List<ProjectMedia>> photosByCategory;
  final List<ProjectMedia> documents;
  final bool isSelectionMode;
  final Set<String> selectedMediaIds;
  final Function(String) onToggleSelection;
  final Function(ProjectMedia) onViewMedia;
  final Function(ProjectMedia) onContextMenu;
  final bool showPhotos;
  final bool showDocuments;

  const MediaGrid({
    super.key,
    required this.mediaItems,
    required this.photosByCategory,
    required this.documents,
    required this.isSelectionMode,
    required this.selectedMediaIds,
    required this.onToggleSelection,
    required this.onViewMedia,
    required this.onContextMenu,
    required this.showPhotos,
    required this.showDocuments,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos by category
          if (showPhotos) ...photosByCategory.entries.map((entry) {
            return _buildPhotoCategory(context, entry.key, entry.value);
          }),
          
          // Documents section
          if (showDocuments && documents.isNotEmpty) ...[
            if (showPhotos) const SizedBox(height: 24),
            _buildDocumentsSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoCategory(BuildContext context, String category, List<ProjectMedia> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            formatPhotoCategoryName(category),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0, // Square aspect ratio
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return _buildPhotoCard(context, photo);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPhotoCard(BuildContext context, ProjectMedia photo) {
    final isSelected = selectedMediaIds.contains(photo.id);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () => onViewMedia(photo),
            onLongPress: !isSelectionMode ? () => onContextMenu(photo) : null,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                      ),
                      child: photo.isImage
                          ? (File(photo.filePath).existsSync()
                              ? Image.file(
                                  File(photo.filePath),
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey[400],
                                ))
                          : Icon(
                              photo.isPdf 
                                  ? Icons.picture_as_pdf_outlined 
                                  : Icons.insert_drive_file_outlined,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.blue[800] : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              photo.formattedFileSize,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd').format(photo.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => onToggleSelection(photo.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            return _buildDocumentCard(context, document);
          },
        ),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, ProjectMedia document) {
    final isSelected = selectedMediaIds.contains(document.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onViewMedia(document),
        onLongPress: !isSelectionMode ? () => onContextMenu(document) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onToggleSelection(document.id),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  document.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                  color: document.isPdf ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.blue[800] : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM dd').format(document.createdAt)} • ${document.formattedFileSize}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.blue[600] : Colors.grey[600],
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
}