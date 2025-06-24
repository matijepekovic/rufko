import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/media/inspection_document.dart';

/// SQLite database operations for InspectionDocument
class InspectionDocumentDatabase {
  static const String tableName = 'inspection_documents';
  
  /// Create inspection documents table
  static String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      type TEXT NOT NULL CHECK (type IN ('note', 'pdf')),
      title TEXT NOT NULL,
      content TEXT,
      file_path TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      quote_id TEXT,
      file_size_bytes INTEGER,
      tags TEXT, -- JSON array
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE,
      FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE SET NULL
    );
  ''';

  /// Create indexes for better performance
  static List<String> get createIndexesSQL => [
    'CREATE INDEX IF NOT EXISTS idx_inspection_documents_customer_id ON $tableName (customer_id);',
    'CREATE INDEX IF NOT EXISTS idx_inspection_documents_quote_id ON $tableName (quote_id);',
    'CREATE INDEX IF NOT EXISTS idx_inspection_documents_type ON $tableName (type);',
    'CREATE INDEX IF NOT EXISTS idx_inspection_documents_sort_order ON $tableName (sort_order);',
    'CREATE INDEX IF NOT EXISTS idx_inspection_documents_created_at ON $tableName (created_at);',
  ];

  /// Insert an inspection document
  Future<void> insertInspectionDocument(Database db, InspectionDocument document) async {
    try {
      await db.insert(
        tableName,
        _documentToMap(document),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting inspection document ${document.id}: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple inspection documents
  Future<void> insertInspectionDocumentsBatch(Database db, List<InspectionDocument> documents) async {
    final batch = db.batch();
    
    for (final document in documents) {
      batch.insert(
        tableName,
        _documentToMap(document),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    try {
      await batch.commit(noResult: true);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${documents.length} inspection documents');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting inspection documents batch: $e');
      }
      rethrow;
    }
  }

  /// Get inspection document by ID
  Future<InspectionDocument?> getInspectionDocumentById(Database db, String id) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToDocument(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection document $id: $e');
      }
      return null;
    }
  }

  /// Get all inspection documents
  Future<List<InspectionDocument>> getAllInspectionDocuments(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'sort_order ASC, created_at DESC',
      );

      return maps.map((map) => _mapToDocument(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all inspection documents: $e');
      }
      return [];
    }
  }

  /// Get inspection documents by customer ID
  Future<List<InspectionDocument>> getInspectionDocumentsByCustomerId(Database db, String customerId) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'sort_order ASC, created_at DESC',
      );

      return maps.map((map) => _mapToDocument(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection documents for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Get inspection documents by quote ID
  Future<List<InspectionDocument>> getInspectionDocumentsByQuoteId(Database db, String quoteId) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'quote_id = ?',
        whereArgs: [quoteId],
        orderBy: 'sort_order ASC, created_at DESC',
      );

      return maps.map((map) => _mapToDocument(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection documents for quote $quoteId: $e');
      }
      return [];
    }
  }

  /// Get inspection documents by type
  Future<List<InspectionDocument>> getInspectionDocumentsByType(Database db, String customerId, String type) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'customer_id = ? AND type = ?',
        whereArgs: [customerId, type],
        orderBy: 'sort_order ASC, created_at DESC',
      );

      return maps.map((map) => _mapToDocument(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection documents by type $type for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Update inspection document
  Future<void> updateInspectionDocument(Database db, InspectionDocument document) async {
    try {
      final count = await db.update(
        tableName,
        _documentToMap(document),
        where: 'id = ?',
        whereArgs: [document.id],
      );
      
      if (count == 0) {
        throw Exception('Inspection document ${document.id} not found for update');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating inspection document ${document.id}: $e');
      }
      rethrow;
    }
  }

  /// Update inspection document sort orders
  Future<void> updateInspectionDocumentSortOrders(Database db, List<InspectionDocument> documents) async {
    try {
      await db.transaction((txn) async {
        for (int i = 0; i < documents.length; i++) {
          await txn.update(
            tableName,
            {
              'sort_order': i,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [documents[i].id],
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating inspection document sort orders: $e');
      }
      rethrow;
    }
  }

  /// Delete inspection document by ID
  Future<void> deleteInspectionDocument(Database db, String id) async {
    try {
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw Exception('Inspection document $id not found for deletion');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting inspection document $id: $e');
      }
      rethrow;
    }
  }

  /// Delete inspection documents by customer ID
  Future<void> deleteInspectionDocumentsByCustomerId(Database db, String customerId) async {
    try {
      await db.delete(
        tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting inspection documents for customer $customerId: $e');
      }
      rethrow;
    }
  }

  /// Clear all inspection documents
  Future<void> clearAllInspectionDocuments(Database db) async {
    try {
      await db.delete(tableName);
      if (kDebugMode) {
        debugPrint('✅ Cleared all inspection documents');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing inspection documents: $e');
      }
      rethrow;
    }
  }

  /// Get inspection document statistics
  Future<Map<String, dynamic>> getInspectionDocumentStatistics(Database db) async {
    try {
      final totalDocuments = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
      ) ?? 0;

      final typeStats = await db.rawQuery('''
        SELECT type, COUNT(*) as count 
        FROM $tableName 
        GROUP BY type 
        ORDER BY count DESC
      ''');

      final customerStats = await db.rawQuery('''
        SELECT customer_id, COUNT(*) as doc_count 
        FROM $tableName 
        GROUP BY customer_id 
        ORDER BY doc_count DESC 
        LIMIT 10
      ''');

      final totalSizeResult = await db.rawQuery(
        'SELECT SUM(file_size_bytes) as total_size FROM $tableName WHERE file_size_bytes IS NOT NULL',
      );
      
      final totalSize = totalSizeResult.isNotEmpty ? totalSizeResult.first['total_size'] : 0;

      return {
        'total_documents': totalDocuments,
        'total_size_bytes': totalSize,
        'type_breakdown': typeStats,
        'top_customers_by_doc_count': customerStats,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection document statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_documents': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Convert InspectionDocument to Map for database storage
  Map<String, dynamic> _documentToMap(InspectionDocument document) {
    return {
      'id': document.id,
      'customer_id': document.customerId,
      'type': document.type,
      'title': document.title,
      'content': document.content,
      'file_path': document.filePath,
      'sort_order': document.sortOrder,
      'created_at': document.createdAt.toIso8601String(),
      'updated_at': document.updatedAt.toIso8601String(),
      'quote_id': document.quoteId,
      'file_size_bytes': document.fileSizeBytes,
      'tags': jsonEncode(document.tags),
    };
  }

  /// Convert Map from database to InspectionDocument
  InspectionDocument _mapToDocument(Map<String, dynamic> map) {
    return InspectionDocument(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      filePath: map['file_path'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      quoteId: map['quote_id'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int?,
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
    );
  }
}