import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/media/project_media.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../controllers/media_tab_controller.dart' as simple_controller;
import '../media_tab_controller.dart' as full_controller;
import '../media/expandable_filter_chips.dart';
import '../media/media_footer_actions.dart';
import '../media/media_grid.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

class MediaTab extends StatefulWidget {
  final Customer customer;
  final VoidCallback onPickImageFromCamera;
  final VoidCallback onPickImageFromGallery;
  final VoidCallback onPickDocument;
  final void Function(ProjectMedia) onViewMedia;
  final void Function(ProjectMedia) onShowContextMenu;
  final void Function(bool isSelectionMode) onSelectionModeChanged;
  final void Function(
    int selectedCount,
    VoidCallback onSelectAll,
    VoidCallback onDeleteSelected,
    VoidCallback onCancelSelection,
    bool isDeleteEnabled,
  ) onSelectionStateChanged;
  final full_controller.MediaTabController? mediaController;

  const MediaTab({
    super.key,
    required this.customer,
    required this.onPickImageFromCamera,
    required this.onPickImageFromGallery,
    required this.onPickDocument,
    required this.onViewMedia,
    required this.onShowContextMenu,
    required this.onSelectionModeChanged,
    required this.onSelectionStateChanged,
    this.mediaController,
  });

  @override
  State<MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends State<MediaTab> {
  late simple_controller.MediaTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = simple_controller.MediaTabController(
      customer: widget.customer,
      context: context,
    );
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    // Notify parent of selection mode changes
    widget.onSelectionModeChanged(_controller.isSelectionMode);
    
    // If in selection mode, provide callbacks to parent
    if (_controller.isSelectionMode) {
      final mediaItems = context.read<AppStateProvider>().getProjectMediaForCustomer(widget.customer.id);
      final filteredItems = _controller.getFilteredMedia(mediaItems);
      
      widget.onSelectionStateChanged(
        _controller.selectedMediaIds.length,
        () => _controller.selectAll(filteredItems),
        _controller.deleteSelectedMedia,
        _controller.exitSelectionMode,
        _controller.hasSelection,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            final mediaItems = appState.getProjectMediaForCustomer(widget.customer.id);
            mediaItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (_controller.isProcessing) {
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
              return _buildEmptyState();
            }

            final filteredItems = _controller.getFilteredMedia(mediaItems);
            final photos = mediaItems.where((m) => m.isImage).toList();
            final documents = mediaItems.where((m) => !m.isImage).toList();
            
            // Determine display mode based on filter type
            final isBasicFilter = [simple_controller.MediaFilter.all, simple_controller.MediaFilter.photos, simple_controller.MediaFilter.documents].contains(_controller.activeFilter);
            final isCategoryFilter = !isBasicFilter;
            
            // For category filters, show simple grid; for basic filters, show grouped
            final photosByCategory = isBasicFilter ? _controller.getPhotosByCategory(photos) : <String, List<ProjectMedia>>{};

            final showPhotos = (_controller.activeFilter == simple_controller.MediaFilter.all || 
                               _controller.activeFilter == simple_controller.MediaFilter.photos) && isBasicFilter;
            final showDocuments = (_controller.activeFilter == simple_controller.MediaFilter.all || 
                                  _controller.activeFilter == simple_controller.MediaFilter.documents) && isBasicFilter;

            return Column(
              children: [
                // Expandable filter chips
                ExpandableFilterChips(
                  activeFilter: _controller.activeFilter,
                  allMedia: mediaItems,
                  onFilterChanged: _controller.setFilter,
                ),

                // Content area
                Expanded(
                  child: isCategoryFilter 
                      ? _buildCategoryFilteredGrid(filteredItems)
                      : MediaGrid(
                          mediaItems: filteredItems,
                          photosByCategory: showPhotos ? photosByCategory : {},
                          documents: showDocuments ? documents : [],
                          isSelectionMode: _controller.isSelectionMode,
                          selectedMediaIds: _controller.selectedMediaIds,
                          onToggleSelection: _controller.toggleSelection,
                          onViewMedia: (media) {
                            if (_controller.isSelectionMode) {
                              _controller.toggleSelection(media.id);
                            } else {
                              widget.onViewMedia(media);
                            }
                          },
                          onContextMenu: widget.onShowContextMenu,
                          showPhotos: showPhotos,
                          showDocuments: showDocuments,
                        ),
                ),

                // Footer actions (when not in selection mode)
                if (!_controller.isSelectionMode)
                  MediaFooterActions(
                    onTakePhoto: _takePhotosDirectly,
                    onUpload: _showUploadOptions,
                    onEnterSelection: _controller.enterSelectionMode,
                    hasMedia: mediaItems.isNotEmpty,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.perm_media_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No media yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding photos and documents to keep\ntrack of your project progress.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RufkoPrimaryButton(
                onPressed: _takePhotosDirectly,
                icon: Icons.camera_alt,
                size: ButtonSize.medium,
                child: const Text('Take Photo'),
              ),
              const SizedBox(width: 8),
              RufkoSecondaryButton(
                onPressed: _showUploadOptions,
                icon: Icons.upload,
                size: ButtonSize.medium,
                child: const Text('Choose File'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUploadOptions() {
    // If we have the full media controller, use its showMediaOptions for upload options
    if (widget.mediaController != null) {
      widget.mediaController!.showMediaOptions();
    } else {
      // Fallback to simplified options
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Upload Document'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickDocument();
                },
              ),
            ],
          ),
        ),
      );
    }
  }
  
  void _takePhotosDirectly() {
    // If we have the full media controller, use the direct camera functionality
    if (widget.mediaController != null) {
      widget.mediaController!.takePhotosDirectly();
    } else {
      // Fallback to single photo camera
      widget.onPickImageFromCamera();
    }
  }

  Widget _buildCategoryFilteredGrid(List<ProjectMedia> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items in this category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _controller.selectedMediaIds.contains(item.id);
        
        return GestureDetector(
          onTap: () {
            if (_controller.isSelectionMode) {
              _controller.toggleSelection(item.id);
            } else {
              widget.onViewMedia(item);
            }
          },
          onLongPress: () {
            if (!_controller.isSelectionMode) {
              widget.onShowContextMenu(item);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Media preview
                  item.isImage
                      ? Image.file(
                          File(item.filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.isPdf ? Icons.picture_as_pdf : Icons.description,
                                size: 32,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  item.fileName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                  
                  // Selection overlay
                  if (_controller.isSelectionMode)
                    Container(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.1),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
