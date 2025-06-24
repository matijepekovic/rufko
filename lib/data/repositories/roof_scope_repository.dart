import 'package:flutter/foundation.dart';
import '../models/business/roof_scope_data.dart';
import '../database/roof_scope_database.dart';
import '../database/database_helper.dart';

/// Repository for RoofScopeData operations using SQLite
class RoofScopeRepository {
  final RoofScopeDatabase _database = RoofScopeDatabase();

  /// Create a new roof scope data record
  Future<void> createRoofScopeData(RoofScopeData roofScope) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertRoofScopeData(db, roofScope);
      if (kDebugMode) {
        debugPrint('✅ Created roof scope data: ${roofScope.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating roof scope data: $e');
      }
      rethrow;
    }
  }

  /// Get roof scope data by ID
  Future<RoofScopeData?> getRoofScopeDataById(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getRoofScopeDataById(db, id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting roof scope data $id: $e');
      }
      return null;
    }
  }

  /// Get all roof scope data
  Future<List<RoofScopeData>> getAllRoofScopeData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getAllRoofScopeData(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all roof scope data: $e');
      }
      return [];
    }
  }

  /// Get roof scope data by customer ID
  Future<List<RoofScopeData>> getRoofScopeDataByCustomerId(String customerId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getRoofScopeDataByCustomerId(db, customerId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting roof scope data for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Update roof scope data
  Future<void> updateRoofScopeData(RoofScopeData roofScope) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.updateRoofScopeData(db, roofScope);
      if (kDebugMode) {
        debugPrint('✅ Updated roof scope data: ${roofScope.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating roof scope data: $e');
      }
      rethrow;
    }
  }

  /// Delete roof scope data by ID
  Future<void> deleteRoofScopeData(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteRoofScopeData(db, id);
      if (kDebugMode) {
        debugPrint('✅ Deleted roof scope data: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting roof scope data: $e');
      }
      rethrow;
    }
  }

  /// Delete roof scope data by customer ID
  Future<void> deleteRoofScopeDataByCustomerId(String customerId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.deleteRoofScopeDataByCustomerId(db, customerId);
      if (kDebugMode) {
        debugPrint('✅ Deleted roof scope data for customer: $customerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting roof scope data for customer: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple roof scope data records
  Future<void> insertRoofScopeDataBatch(List<RoofScopeData> roofScopes) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.insertRoofScopeDataBatch(db, roofScopes);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${roofScopes.length} roof scope data records');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting roof scope data batch: $e');
      }
      rethrow;
    }
  }

  /// Clear all roof scope data
  Future<void> clearAllRoofScopeData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _database.clearAllRoofScopeData(db);
      if (kDebugMode) {
        debugPrint('✅ Cleared all roof scope data');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing roof scope data: $e');
      }
      rethrow;
    }
  }

  /// Get roof scope data statistics
  Future<Map<String, dynamic>> getRoofScopeStatistics() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await _database.getRoofScopeStatistics(db);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting roof scope statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_roof_scopes': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Search roof scope data by source file name
  Future<List<RoofScopeData>> searchBySourceFileName(String fileName) async {
    try {
      final allRoofScopes = await getAllRoofScopeData();
      return allRoofScopes.where((roofScope) {
        return roofScope.sourceFileName?.toLowerCase().contains(fileName.toLowerCase()) ?? false;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching roof scope data by file name: $e');
      }
      return [];
    }
  }

  /// Get roof scope data with minimum area
  Future<List<RoofScopeData>> getRoofScopeDataWithMinArea(double minArea) async {
    try {
      final allRoofScopes = await getAllRoofScopeData();
      return allRoofScopes.where((roofScope) => roofScope.roofArea >= minArea).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting roof scope data with min area: $e');
      }
      return [];
    }
  }

  /// Get roof scope data summary for customer
  Future<Map<String, dynamic>> getRoofScopeSummaryForCustomer(String customerId) async {
    try {
      final roofScopes = await getRoofScopeDataByCustomerId(customerId);
      
      if (roofScopes.isEmpty) {
        return {
          'customer_id': customerId,
          'total_roof_scopes': 0,
          'total_area': 0.0,
          'average_area': 0.0,
          'total_squares': 0.0,
          'average_pitch': 0.0,
        };
      }

      final totalArea = roofScopes.fold(0.0, (sum, scope) => sum + scope.roofArea);
      final totalSquares = roofScopes.fold(0.0, (sum, scope) => sum + scope.numberOfSquares);
      final averagePitch = roofScopes.fold(0.0, (sum, scope) => sum + scope.pitch) / roofScopes.length;

      return {
        'customer_id': customerId,
        'total_roof_scopes': roofScopes.length,
        'total_area': totalArea,
        'average_area': totalArea / roofScopes.length,
        'total_squares': totalSquares,
        'average_pitch': averagePitch,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting roof scope summary for customer: $e');
      }
      return {
        'customer_id': customerId,
        'error': e.toString(),
        'total_roof_scopes': 0,
      };
    }
  }
}