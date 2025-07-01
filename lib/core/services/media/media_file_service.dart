import 'dart:io';
import '../../../data/models/media/project_media.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Result object for media file operations
class MediaFileResult {
  final bool isSuccess;
  final String? errorMessage;
  final int? successCount;

  const MediaFileResult({
    required this.isSuccess,
    this.errorMessage,
    this.successCount,
  });

  factory MediaFileResult.success({int? successCount}) {
    return MediaFileResult(isSuccess: true, successCount: successCount);
  }

  factory MediaFileResult.error(String message) {
    return MediaFileResult(isSuccess: false, errorMessage: message);
  }
}

/// Service layer for media file operations
/// Contains pure business logic without UI dependencies
class MediaFileService {
  /// Process bulk media files
  /// Business logic extracted from MediaOperationsController.processBulkMedia()
  static Future<MediaFileResult> processBulkMedia({
    required List<File> files,
    required String customerId,
    required String defaultType,
    required String selectedCategory,
    required AppStateProvider appState,
    required Future<ProjectMedia?> Function(File, String, String, String) createMediaItem,
  }) async {
    if (files.isEmpty) {
      return MediaFileResult.error('No files to process');
    }

    try {
      int successCount = 0;

      for (final file in files) {
        try {
          final mediaItem = await createMediaItem(file, customerId, defaultType, selectedCategory);
          if (mediaItem != null) {
            await appState.addProjectMedia(mediaItem);
            successCount++;
          }
        } catch (e) {
          // Continue processing other files
        }
      }

      return MediaFileResult.success(successCount: successCount);
    } catch (e) {
      return MediaFileResult.error('Error processing files: $e');
    }
  }

  /// Delete media file and data
  /// Business logic extracted from MediaOperationsController.deleteMedia()
  static Future<MediaFileResult> deleteMedia({
    required ProjectMedia mediaItem,
    required AppStateProvider appState,
  }) async {
    try {
      final file = File(mediaItem.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      await appState.deleteProjectMedia(mediaItem.id);
      return MediaFileResult.success();
    } catch (e) {
      return MediaFileResult.error('Error deleting media: $e');
    }
  }

  /// Update media data
  /// Business logic for media updates
  static Future<MediaFileResult> updateMedia({
    required ProjectMedia updatedMedia,
    required AppStateProvider appState,
  }) async {
    try {
      await appState.updateProjectMedia(updatedMedia);
      return MediaFileResult.success();
    } catch (e) {
      return MediaFileResult.error('Error updating media: $e');
    }
  }
}