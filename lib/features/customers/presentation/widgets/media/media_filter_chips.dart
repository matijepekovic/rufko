import 'package:flutter/material.dart';
import '../../controllers/media_tab_controller.dart';
import '../../../../../data/models/media/project_media.dart';

class MediaFilterChips extends StatelessWidget {
  final MediaFilter activeFilter;
  final List<ProjectMedia> allMedia;
  final Function(MediaFilter) onFilterChanged;

  const MediaFilterChips({
    super.key,
    required this.activeFilter,
    required this.allMedia,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = allMedia.length;
    final photosCount = allMedia.where((item) => item.isImage).length;
    final documentsCount = allMedia.where((item) => !item.isImage).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFilterChip(
            context: context,
            filter: MediaFilter.all,
            label: 'All Files',
            count: totalCount,
            icon: Icons.folder,
            isActive: activeFilter == MediaFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            filter: MediaFilter.photos,
            label: 'Photos',
            count: photosCount,
            icon: Icons.image,
            isActive: activeFilter == MediaFilter.photos,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            filter: MediaFilter.documents,
            label: 'Documents',
            count: documentsCount,
            icon: Icons.description,
            isActive: activeFilter == MediaFilter.documents,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required MediaFilter filter,
    required String label,
    required int count,
    required IconData icon,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(filter),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).primaryColor 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(22),
            boxShadow: isActive 
                ? [BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive 
                    ? Colors.white 
                    : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive 
                      ? Colors.white 
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isActive 
                        ? Colors.white 
                        : Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}