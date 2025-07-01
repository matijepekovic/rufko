import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../data/models/media/project_media.dart';

/// Reusable context menu for media operations
/// Extracted from MediaTabController for better maintainability
class MediaContextMenu extends StatelessWidget {
  final ProjectMedia mediaItem;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function({
    required File file,
    required String fileName,
    String? description,
    String? fileType,
  }) onShare;

  const MediaContextMenu({
    super.key,
    required this.mediaItem,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuTile(
            icon: Icons.visibility,
            title: 'View',
            onTap: () {
              Navigator.pop(context);
              onView();
            },
          ),
          _buildMenuTile(
            icon: Icons.edit,
            title: 'Edit Details',
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          _buildMenuTile(
            icon: Icons.share,
            title: 'Share',
            onTap: () {
              Navigator.pop(context);
              onShare(
                file: File(mediaItem.filePath),
                fileName: mediaItem.fileName,
                description: mediaItem.description,
                fileType: mediaItem.fileType,
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.delete,
            title: 'Delete',
            textColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }
}