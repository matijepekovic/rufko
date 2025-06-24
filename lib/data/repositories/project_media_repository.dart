import 'package:flutter/foundation.dart';
import '../models/media/project_media.dart';
import '../database/project_media_database.dart';
import '../database/database_helper.dart';

/// Repository for ProjectMedia operations using SQLite
class ProjectMediaRepository {
  final ProjectMediaDatabase _database = ProjectMediaDatabase();

  /// Create a new project media record
  Future<void> createProjectMedia(ProjectMedia media) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertProjectMedia(db, media);
      if (kDebugMode) {
        debugPrint('✅ Created project media: ${media.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating project media: $e');
      }
      rethrow;
    }
  }

  /// Get project media by ID
  Future<ProjectMedia?> getProjectMediaById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getProjectMediaById(db, id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media $id: $e');
      }
      return null;
    }
  }

  /// Get all project media
  Future<List<ProjectMedia>> getAllProjectMedia() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getAllProjectMedia(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all project media: $e');
      }
      return [];
    }
  }

  /// Get project media by customer ID
  Future<List<ProjectMedia>> getProjectMediaByCustomerId(String customerId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getProjectMediaByCustomerId(db, customerId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Get project media by quote ID
  Future<List<ProjectMedia>> getProjectMediaByQuoteId(String quoteId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getProjectMediaByQuoteId(db, quoteId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media for quote $quoteId: $e');
      }
      return [];
    }
  }

  /// Get project media by category
  Future<List<ProjectMedia>> getProjectMediaByCategory(String category) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getProjectMediaByCategory(db, category);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media for category $category: $e');
      }
      return [];
    }
  }

  /// Update project media
  Future<void> updateProjectMedia(ProjectMedia media) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.updateProjectMedia(db, media);
      if (kDebugMode) {
        debugPrint('✅ Updated project media: ${media.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating project media: $e');
      }
      rethrow;
    }
  }

  /// Delete project media by ID
  Future<void> deleteProjectMedia(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteProjectMedia(db, id);
      if (kDebugMode) {
        debugPrint('✅ Deleted project media: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting project media: $e');
      }
      rethrow;
    }
  }

  /// Delete project media by customer ID
  Future<void> deleteProjectMediaByCustomerId(String customerId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteProjectMediaByCustomerId(db, customerId);
      if (kDebugMode) {
        debugPrint('✅ Deleted project media for customer: $customerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting project media for customer: $e');
      }
      rethrow;
    }
  }

  /// Delete project media by quote ID
  Future<void> deleteProjectMediaByQuoteId(String quoteId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteProjectMediaByQuoteId(db, quoteId);
      if (kDebugMode) {
        debugPrint('✅ Deleted project media for quote: $quoteId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting project media for quote: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple project media records
  Future<void> insertProjectMediaBatch(List<ProjectMedia> mediaList) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertProjectMediaBatch(db, mediaList);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${mediaList.length} project media records');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting project media batch: $e');
      }
      rethrow;
    }
  }

  /// Clear all project media
  Future<void> clearAllProjectMedia() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.clearAllProjectMedia(db);
      if (kDebugMode) {
        debugPrint('✅ Cleared all project media');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing project media: $e');
      }
      rethrow;
    }
  }

  /// Get project media statistics
  Future<Map<String, dynamic>> getProjectMediaStatistics() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getProjectMediaStatistics(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_media_files': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Search project media by file name
  Future<List<ProjectMedia>> searchByFileName(String fileName) async {
    try {
      final allMedia = await getAllProjectMedia();
      return allMedia.where((media) {
        return media.fileName.toLowerCase().contains(fileName.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching project media by file name: $e');
      }
      return [];
    }
  }

  /// Search project media by tags
  Future<List<ProjectMedia>> searchByTags(List<String> tags) async {
    try {
      final allMedia = await getAllProjectMedia();
      return allMedia.where((media) {
        return tags.any((tag) => media.tags.contains(tag));
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching project media by tags: $e');
      }
      return [];
    }
  }

  /// Get project media by file type
  Future<List<ProjectMedia>> getProjectMediaByFileType(String fileType) async {
    try {
      final allMedia = await getAllProjectMedia();
      return allMedia.where((media) => media.fileType == fileType).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media by file type: $e');
      }
      return [];
    }
  }

  /// Get project media size summary for customer
  Future<Map<String, dynamic>> getMediaSummaryForCustomer(String customerId) async {
    try {
      final mediaList = await getProjectMediaByCustomerId(customerId);
      
      if (mediaList.isEmpty) {
        return {
          'customer_id': customerId,
          'total_files': 0,
          'total_size_bytes': 0,
          'categories': <String, int>{},
          'file_types': <String, int>{},
        };
      }

      final totalSize = mediaList.fold(0, (sum, media) => sum + (media.fileSizeBytes ?? 0));
      
      final categories = <String, int>{};
      final fileTypes = <String, int>{};
      
      for (final media in mediaList) {
        categories[media.category] = (categories[media.category] ?? 0) + 1;
        fileTypes[media.fileType] = (fileTypes[media.fileType] ?? 0) + 1;
      }

      return {
        'customer_id': customerId,
        'total_files': mediaList.length,
        'total_size_bytes': totalSize,
        'categories': categories,
        'file_types': fileTypes,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting media summary for customer: $e');
      }
      return {
        'customer_id': customerId,
        'error': e.toString(),
        'total_files': 0,
      };
    }
  }

  /// Get recent project media (last 30 days)
  Future<List<ProjectMedia>> getRecentProjectMedia() async {
    try {
      final allMedia = await getAllProjectMedia();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      return allMedia.where((media) => media.createdAt.isAfter(thirtyDaysAgo)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recent project media: $e');
      }
      return [];
    }
  }
}