import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/media/project_media.dart';

/// SQLite database operations for ProjectMedia
class ProjectMediaDatabase {
  static const String tableName = 'project_media';
  
  /// Create project media table
  static String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      quote_id TEXT,
      file_path TEXT NOT NULL,
      file_name TEXT NOT NULL,
      file_type TEXT NOT NULL,
      description TEXT,
      tags TEXT, -- JSON array
      category TEXT NOT NULL,
      file_size_bytes INTEGER,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE,
      FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
    );
  ''';

  /// Create indexes for better performance
  static List<String> get createIndexesSQL => [
    'CREATE INDEX IF NOT EXISTS idx_project_media_customer_id ON $tableName (customer_id);',
    'CREATE INDEX IF NOT EXISTS idx_project_media_quote_id ON $tableName (quote_id);',
    'CREATE INDEX IF NOT EXISTS idx_project_media_category ON $tableName (category);',
    'CREATE INDEX IF NOT EXISTS idx_project_media_file_type ON $tableName (file_type);',
    'CREATE INDEX IF NOT EXISTS idx_project_media_created_at ON $tableName (created_at);',
  ];

  /// Insert a project media record
  Future<void> insertProjectMedia(Database db, ProjectMedia media) async {
    try {
      await db.insert(
        tableName,
        _mediaToMap(media),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting project media ${media.id}: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple project media records
  Future<void> insertProjectMediaBatch(Database db, List<ProjectMedia> mediaList) async {
    final batch = db.batch();
    
    for (final media in mediaList) {
      batch.insert(
        tableName,
        _mediaToMap(media),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    try {
      await batch.commit(noResult: true);
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

  /// Get project media by ID
  Future<ProjectMedia?> getProjectMediaById(Database db, String id) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToMedia(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media $id: $e');
      }
      return null;
    }
  }

  /// Get all project media
  Future<List<ProjectMedia>> getAllProjectMedia(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToMedia(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all project media: $e');
      }
      return [];
    }
  }

  /// Get project media by customer ID
  Future<List<ProjectMedia>> getProjectMediaByCustomerId(Database db, String customerId) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToMedia(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Get project media by quote ID
  Future<List<ProjectMedia>> getProjectMediaByQuoteId(Database db, String quoteId) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'quote_id = ?',
        whereArgs: [quoteId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToMedia(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media for quote $quoteId: $e');
      }
      return [];
    }
  }

  /// Get project media by category
  Future<List<ProjectMedia>> getProjectMediaByCategory(Database db, String category) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToMedia(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting project media for category $category: $e');
      }
      return [];
    }
  }

  /// Update project media
  Future<void> updateProjectMedia(Database db, ProjectMedia media) async {
    try {
      final count = await db.update(
        tableName,
        _mediaToMap(media),
        where: 'id = ?',
        whereArgs: [media.id],
      );
      
      if (count == 0) {
        throw Exception('Project media ${media.id} not found for update');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating project media ${media.id}: $e');
      }
      rethrow;
    }
  }

  /// Delete project media by ID
  Future<void> deleteProjectMedia(Database db, String id) async {
    try {
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw Exception('Project media $id not found for deletion');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting project media $id: $e');
      }
      rethrow;
    }
  }

  /// Delete project media by customer ID
  Future<void> deleteProjectMediaByCustomerId(Database db, String customerId) async {
    try {
      await db.delete(
        tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting project media for customer $customerId: $e');
      }
      rethrow;
    }
  }

  /// Delete project media by quote ID
  Future<void> deleteProjectMediaByQuoteId(Database db, String quoteId) async {
    try {
      await db.delete(
        tableName,
        where: 'quote_id = ?',
        whereArgs: [quoteId],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting project media for quote $quoteId: $e');
      }
      rethrow;
    }
  }

  /// Clear all project media
  Future<void> clearAllProjectMedia(Database db) async {
    try {
      await db.delete(tableName);
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
  Future<Map<String, dynamic>> getProjectMediaStatistics(Database db) async {
    try {
      final totalCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
      ) ?? 0;

      final categoryStats = await db.rawQuery('''
        SELECT category, COUNT(*) as count 
        FROM $tableName 
        GROUP BY category 
        ORDER BY count DESC
      ''');

      final fileTypeStats = await db.rawQuery('''
        SELECT file_type, COUNT(*) as count 
        FROM $tableName 
        GROUP BY file_type 
        ORDER BY count DESC
      ''');

      final totalSizeResult = await db.rawQuery(
        'SELECT SUM(file_size_bytes) as total_size FROM $tableName WHERE file_size_bytes IS NOT NULL',
      );
      
      final totalSize = totalSizeResult.isNotEmpty ? totalSizeResult.first['total_size'] : 0;

      return {
        'total_media_files': totalCount,
        'total_size_bytes': totalSize,
        'category_breakdown': categoryStats,
        'file_type_breakdown': fileTypeStats,
        'timestamp': DateTime.now().toIso8601String(),
      };
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

  /// Convert ProjectMedia to Map for database storage
  Map<String, dynamic> _mediaToMap(ProjectMedia media) {
    return {
      'id': media.id,
      'customer_id': media.customerId,
      'quote_id': media.quoteId,
      'file_path': media.filePath,
      'file_name': media.fileName,
      'file_type': media.fileType,
      'description': media.description,
      'tags': jsonEncode(media.tags),
      'category': media.category,
      'file_size_bytes': media.fileSizeBytes,
      'created_at': media.createdAt.toIso8601String(),
      'updated_at': media.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map from database to ProjectMedia
  ProjectMedia _mapToMedia(Map<String, dynamic> map) {
    return ProjectMedia(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      quoteId: map['quote_id'] as String?,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileType: map['file_type'] as String,
      description: map['description'] as String?,
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      category: map['category'] as String,
      fileSizeBytes: map['file_size_bytes'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}