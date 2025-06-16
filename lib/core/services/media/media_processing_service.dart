import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../data/models/media/project_media.dart';

/// Service layer for media processing operations
/// Contains pure business logic without UI dependencies
class MediaProcessingService {
  /// Create ProjectMedia from file
  /// Business logic copied exactly from MediaOperationsController._createMediaItemFromFile()
  static Future<ProjectMedia?> createMediaItemFromFile({
    required File file,
    required String customerId,
    required String defaultType,
    required String category,
  }) async {
    try {
      final fileSize = await file.length();
      final fileName = path.basename(file.path);
      final fileType = detectFileType(fileName, defaultType);

      return ProjectMedia(
        customerId: customerId,
        filePath: file.path,
        fileName: fileName,
        fileType: fileType,
        category: category,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      return null;
    }
  }

  /// Detect file type from extension
  /// Business logic copied exactly from MediaOperationsController._detectFileType()
  static String detectFileType(String fileName, String defaultType) {
    final fileExtension = path.extension(fileName).toLowerCase();

    if (fileExtension == '.pdf') {
      return 'pdf';
    } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(fileExtension)) {
      return 'image';
    }
    return defaultType;
  }

  /// Get available categories
  /// Business logic copied exactly from MediaOperationsController._getCategories()
  static List<String> getCategories() {
    return [
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
  }

  /// Get formatted category name with emoji
  /// Business logic copied exactly from MediaOperationsController.getFormattedCategoryName()
  static String getFormattedCategoryName(String category) {
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

  /// Get default category for file type
  /// Business logic for determining default category
  static String getDefaultCategory(String fileType) {
    return fileType == 'image' ? 'before_photos' : 'general';
  }
}