import 'package:flutter/material.dart';

/// Reusable bottom sheet for media addition options
/// Extracted from MediaTabController for better maintainability
class MediaOptionsSheet extends StatelessWidget {
  final VoidCallback onTakeMultiplePhotos;
  final VoidCallback onSelectMultiplePhotos;
  final VoidCallback onUploadDocuments;

  const MediaOptionsSheet({
    super.key,
    required this.onTakeMultiplePhotos,
    required this.onSelectMultiplePhotos,
    required this.onUploadDocuments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildOptionTile(
            icon: Icons.camera_alt,
            iconColor: Colors.blue.shade700,
            backgroundColor: Colors.blueAccent.shade100,
            title: 'Take Multiple Photos',
            subtitle: 'Take several photos in sequence',
            onTap: () {
              Navigator.pop(context);
              onTakeMultiplePhotos();
            },
          ),
          _buildOptionTile(
            icon: Icons.photo_library,
            iconColor: Colors.green.shade700,
            backgroundColor: Colors.greenAccent.shade100,
            title: 'Select Multiple Photos',
            subtitle: 'Choose multiple photos from gallery',
            onTap: () {
              Navigator.pop(context);
              onSelectMultiplePhotos();
            },
          ),
          _buildOptionTile(
            icon: Icons.file_upload,
            iconColor: Colors.orange.shade700,
            backgroundColor: Colors.orangeAccent.shade100,
            title: 'Upload Documents',
            subtitle: 'Select PDF, Word, Excel files',
            onTap: () {
              Navigator.pop(context);
              onUploadDocuments();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}