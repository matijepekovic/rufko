import 'package:flutter/foundation.dart';
import '../models/media/inspection_document.dart';
import '../database/inspection_document_database.dart';
import '../database/database_helper.dart';

/// Repository for InspectionDocument operations using SQLite
class InspectionDocumentRepository {
  final InspectionDocumentDatabase _database = InspectionDocumentDatabase();

  /// Create a new inspection document
  Future<void> createInspectionDocument(InspectionDocument document) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertInspectionDocument(db, document);
      if (kDebugMode) {
        debugPrint('✅ Created inspection document: ${document.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating inspection document: $e');
      }
      rethrow;
    }
  }

  /// Get inspection document by ID
  Future<InspectionDocument?> getInspectionDocumentById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getInspectionDocumentById(db, id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection document $id: $e');
      }
      return null;
    }
  }

  /// Get all inspection documents
  Future<List<InspectionDocument>> getAllInspectionDocuments() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getAllInspectionDocuments(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all inspection documents: $e');
      }
      return [];
    }
  }

  /// Get inspection documents by customer ID
  Future<List<InspectionDocument>> getInspectionDocumentsByCustomerId(String customerId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getInspectionDocumentsByCustomerId(db, customerId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection documents for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Get inspection documents by quote ID
  Future<List<InspectionDocument>> getInspectionDocumentsByQuoteId(String quoteId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getInspectionDocumentsByQuoteId(db, quoteId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection documents for quote $quoteId: $e');
      }
      return [];
    }
  }

  /// Get inspection documents by type
  Future<List<InspectionDocument>> getInspectionDocumentsByType(String customerId, String type) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getInspectionDocumentsByType(db, customerId, type);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting inspection documents by type $type for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Update inspection document
  Future<void> updateInspectionDocument(InspectionDocument document) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.updateInspectionDocument(db, document);
      if (kDebugMode) {
        debugPrint('✅ Updated inspection document: ${document.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating inspection document: $e');
      }
      rethrow;
    }
  }

  /// Update inspection document sort orders
  Future<void> updateInspectionDocumentSortOrders(List<InspectionDocument> documents) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.updateInspectionDocumentSortOrders(db, documents);
      if (kDebugMode) {
        debugPrint('✅ Updated sort orders for ${documents.length} inspection documents');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating inspection document sort orders: $e');
      }
      rethrow;
    }
  }

  /// Delete inspection document by ID
  Future<void> deleteInspectionDocument(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteInspectionDocument(db, id);
      if (kDebugMode) {
        debugPrint('✅ Deleted inspection document: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting inspection document: $e');
      }
      rethrow;
    }
  }

  /// Delete inspection documents by customer ID
  Future<void> deleteInspectionDocumentsByCustomerId(String customerId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteInspectionDocumentsByCustomerId(db, customerId);
      if (kDebugMode) {
        debugPrint('✅ Deleted inspection documents for customer: $customerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting inspection documents for customer: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple inspection documents
  Future<void> insertInspectionDocumentsBatch(List<InspectionDocument> documents) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertInspectionDocumentsBatch(db, documents);
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

  /// Clear all inspection documents
  Future<void> clearAllInspectionDocuments() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.clearAllInspectionDocuments(db);
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
  Future<Map<String, dynamic>> getInspectionDocumentStatistics() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getInspectionDocumentStatistics(db);
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

  /// Get notes only
  Future<List<InspectionDocument>> getNotes(String customerId) async {
    try {
      return await getInspectionDocumentsByType(customerId, 'note');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting notes for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Get PDFs only
  Future<List<InspectionDocument>> getPdfs(String customerId) async {
    try {
      return await getInspectionDocumentsByType(customerId, 'pdf');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDFs for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Search inspection documents by title
  Future<List<InspectionDocument>> searchByTitle(String searchTerm) async {
    try {
      final allDocuments = await getAllInspectionDocuments();
      return allDocuments.where((document) {
        return document.title.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching inspection documents by title: $e');
      }
      return [];
    }
  }

  /// Search inspection documents by content (notes only)
  Future<List<InspectionDocument>> searchByContent(String searchTerm) async {
    try {
      final allDocuments = await getAllInspectionDocuments();
      return allDocuments.where((document) {
        return document.type == 'note' && 
               document.content != null &&
               document.content!.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching inspection documents by content: $e');
      }
      return [];
    }
  }

  /// Search inspection documents by tags
  Future<List<InspectionDocument>> searchByTags(List<String> tags) async {
    try {
      final allDocuments = await getAllInspectionDocuments();
      return allDocuments.where((document) {
        return tags.any((tag) => document.tags.contains(tag));
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching inspection documents by tags: $e');
      }
      return [];
    }
  }

  /// Get inspection document type summary for customer
  Future<Map<String, dynamic>> getDocumentTypeSummaryForCustomer(String customerId) async {
    try {
      final documents = await getInspectionDocumentsByCustomerId(customerId);
      
      if (documents.isEmpty) {
        return {
          'customer_id': customerId,
          'total_documents': 0,
          'notes': 0,
          'pdfs': 0,
          'total_size_bytes': 0,
        };
      }

      int noteCount = 0;
      int pdfCount = 0;
      int totalSize = 0;
      
      for (final document in documents) {
        if (document.type == 'note') {
          noteCount++;
        } else if (document.type == 'pdf') {
          pdfCount++;
          totalSize += document.fileSizeBytes ?? 0;
        }
      }

      return {
        'customer_id': customerId,
        'total_documents': documents.length,
        'notes': noteCount,
        'pdfs': pdfCount,
        'total_size_bytes': totalSize,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting document type summary for customer: $e');
      }
      return {
        'customer_id': customerId,
        'error': e.toString(),
        'total_documents': 0,
      };
    }
  }

  /// Get recent inspection documents (last 30 days)
  Future<List<InspectionDocument>> getRecentInspectionDocuments() async {
    try {
      final allDocuments = await getAllInspectionDocuments();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      return allDocuments.where((document) => document.createdAt.isAfter(thirtyDaysAgo)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting recent inspection documents: $e');
      }
      return [];
    }
  }

  /// Get inspection documents with file size (PDFs only)
  Future<List<InspectionDocument>> getDocumentsWithFileSize() async {
    try {
      final allDocuments = await getAllInspectionDocuments();
      return allDocuments.where((document) => 
          document.type == 'pdf' && document.fileSizeBytes != null).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting documents with file size: $e');
      }
      return [];
    }
  }

  /// Get total file size for customer (PDFs only)
  Future<int> getTotalFileSizeForCustomer(String customerId) async {
    try {
      final pdfs = await getPdfs(customerId);
      return pdfs.fold<int>(0, (sum, pdf) => sum + (pdf.fileSizeBytes ?? 0));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting total file size for customer: $e');
      }
      return 0;
    }
  }

  /// Reorder inspection documents for customer
  Future<void> reorderDocumentsForCustomer(String customerId, List<String> documentIds) async {
    try {
      final documents = await getInspectionDocumentsByCustomerId(customerId);
      final reorderedDocuments = <InspectionDocument>[];
      
      // Create new list in the specified order
      for (int i = 0; i < documentIds.length; i++) {
        final document = documents.firstWhere((doc) => doc.id == documentIds[i]);
        final updatedDocument = InspectionDocument(
          id: document.id,
          customerId: document.customerId,
          type: document.type,
          title: document.title,
          content: document.content,
          filePath: document.filePath,
          sortOrder: i,
          createdAt: document.createdAt,
          updatedAt: DateTime.now(),
          quoteId: document.quoteId,
          fileSizeBytes: document.fileSizeBytes,
          tags: document.tags,
        );
        reorderedDocuments.add(updatedDocument);
      }
      
      await updateInspectionDocumentSortOrders(reorderedDocuments);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error reordering documents for customer: $e');
      }
      rethrow;
    }
  }
}