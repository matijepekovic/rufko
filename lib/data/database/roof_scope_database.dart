import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/business/roof_scope_data.dart';

/// SQLite database operations for RoofScopeData
class RoofScopeDatabase {
  static const String tableName = 'roof_scope_data';
  
  /// Create roof scope data table
  static String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      source_file_name TEXT,
      roof_area REAL NOT NULL DEFAULT 0.0,
      number_of_squares REAL NOT NULL DEFAULT 0.0,
      pitch REAL NOT NULL DEFAULT 0.0,
      valley_length REAL NOT NULL DEFAULT 0.0,
      hip_length REAL NOT NULL DEFAULT 0.0,
      ridge_length REAL NOT NULL DEFAULT 0.0,
      perimeter_length REAL NOT NULL DEFAULT 0.0,
      eave_length REAL NOT NULL DEFAULT 0.0,
      gutter_length REAL NOT NULL DEFAULT 0.0,
      chimney_count INTEGER NOT NULL DEFAULT 0,
      skylight_count INTEGER NOT NULL DEFAULT 0,
      flashing_length REAL NOT NULL DEFAULT 0.0,
      additional_measurements TEXT, -- JSON field
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
    );
  ''';

  /// Create indexes for better performance
  static List<String> get createIndexesSQL => [
    'CREATE INDEX IF NOT EXISTS idx_roof_scope_customer_id ON $tableName (customer_id);',
    'CREATE INDEX IF NOT EXISTS idx_roof_scope_created_at ON $tableName (created_at);',
  ];

  /// Insert a roof scope data record
  Future<void> insertRoofScopeData(Database db, RoofScopeData roofScope) async {
    try {
      await db.insert(
        tableName,
        _roofScopeToMap(roofScope),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting roof scope data ${roofScope.id}: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple roof scope data records
  Future<void> insertRoofScopeDataBatch(Database db, List<RoofScopeData> roofScopes) async {
    final batch = db.batch();
    
    for (final roofScope in roofScopes) {
      batch.insert(
        tableName,
        _roofScopeToMap(roofScope),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    try {
      await batch.commit(noResult: true);
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

  /// Get roof scope data by ID
  Future<RoofScopeData?> getRoofScopeDataById(Database db, String id) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToRoofScope(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting roof scope data $id: $e');
      }
      return null;
    }
  }

  /// Get all roof scope data
  Future<List<RoofScopeData>> getAllRoofScopeData(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToRoofScope(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all roof scope data: $e');
      }
      return [];
    }
  }

  /// Get roof scope data by customer ID
  Future<List<RoofScopeData>> getRoofScopeDataByCustomerId(Database db, String customerId) async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToRoofScope(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting roof scope data for customer $customerId: $e');
      }
      return [];
    }
  }

  /// Update roof scope data
  Future<void> updateRoofScopeData(Database db, RoofScopeData roofScope) async {
    try {
      final count = await db.update(
        tableName,
        _roofScopeToMap(roofScope),
        where: 'id = ?',
        whereArgs: [roofScope.id],
      );
      
      if (count == 0) {
        throw Exception('Roof scope data ${roofScope.id} not found for update');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating roof scope data ${roofScope.id}: $e');
      }
      rethrow;
    }
  }

  /// Delete roof scope data by ID
  Future<void> deleteRoofScopeData(Database db, String id) async {
    try {
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw Exception('Roof scope data $id not found for deletion');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting roof scope data $id: $e');
      }
      rethrow;
    }
  }

  /// Delete roof scope data by customer ID
  Future<void> deleteRoofScopeDataByCustomerId(Database db, String customerId) async {
    try {
      await db.delete(
        tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting roof scope data for customer $customerId: $e');
      }
      rethrow;
    }
  }

  /// Clear all roof scope data
  Future<void> clearAllRoofScopeData(Database db) async {
    try {
      await db.delete(tableName);
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
  Future<Map<String, dynamic>> getRoofScopeStatistics(Database db) async {
    try {
      final totalCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
      ) ?? 0;

      final avgArea = await db.rawQuery(
        'SELECT AVG(roof_area) as avg_area FROM $tableName WHERE roof_area > 0',
      );
      
      final avgSquares = await db.rawQuery(
        'SELECT AVG(number_of_squares) as avg_squares FROM $tableName WHERE number_of_squares > 0',
      );

      final customerCounts = await db.rawQuery('''
        SELECT customer_id, COUNT(*) as scope_count 
        FROM $tableName 
        GROUP BY customer_id 
        ORDER BY scope_count DESC 
        LIMIT 10
      ''');

      return {
        'total_roof_scopes': totalCount,
        'average_roof_area': avgArea.isNotEmpty ? avgArea.first['avg_area'] : 0.0,
        'average_squares': avgSquares.isNotEmpty ? avgSquares.first['avg_squares'] : 0.0,
        'top_customers_by_scope_count': customerCounts,
        'timestamp': DateTime.now().toIso8601String(),
      };
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

  /// Convert RoofScopeData to Map for database storage
  Map<String, dynamic> _roofScopeToMap(RoofScopeData roofScope) {
    return {
      'id': roofScope.id,
      'customer_id': roofScope.customerId,
      'source_file_name': roofScope.sourceFileName,
      'roof_area': roofScope.roofArea,
      'number_of_squares': roofScope.numberOfSquares,
      'pitch': roofScope.pitch,
      'valley_length': roofScope.valleyLength,
      'hip_length': roofScope.hipLength,
      'ridge_length': roofScope.ridgeLength,
      'perimeter_length': roofScope.perimeterLength,
      'eave_length': roofScope.eaveLength,
      'gutter_length': roofScope.gutterLength,
      'chimney_count': roofScope.chimneyCount,
      'skylight_count': roofScope.skylightCount,
      'flashing_length': roofScope.flashingLength,
      'additional_measurements': jsonEncode(roofScope.additionalMeasurements),
      'created_at': roofScope.createdAt.toIso8601String(),
      'updated_at': roofScope.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map from database to RoofScopeData
  RoofScopeData _mapToRoofScope(Map<String, dynamic> map) {
    return RoofScopeData(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      sourceFileName: map['source_file_name'] as String?,
      roofArea: (map['roof_area'] as num?)?.toDouble() ?? 0.0,
      numberOfSquares: (map['number_of_squares'] as num?)?.toDouble() ?? 0.0,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 0.0,
      valleyLength: (map['valley_length'] as num?)?.toDouble() ?? 0.0,
      hipLength: (map['hip_length'] as num?)?.toDouble() ?? 0.0,
      ridgeLength: (map['ridge_length'] as num?)?.toDouble() ?? 0.0,
      perimeterLength: (map['perimeter_length'] as num?)?.toDouble() ?? 0.0,
      eaveLength: (map['eave_length'] as num?)?.toDouble() ?? 0.0,
      gutterLength: (map['gutter_length'] as num?)?.toDouble() ?? 0.0,
      chimneyCount: (map['chimney_count'] as int?) ?? 0,
      skylightCount: (map['skylight_count'] as int?) ?? 0,
      flashingLength: (map['flashing_length'] as num?)?.toDouble() ?? 0.0,
      additionalMeasurements: map['additional_measurements'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['additional_measurements'] as String))
          : {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}