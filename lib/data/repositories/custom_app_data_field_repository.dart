import 'package:flutter/foundation.dart';
import '../models/settings/custom_app_data.dart';
import '../database/custom_field_database.dart';

/// Repository for CustomAppDataField operations using SQLite
class CustomAppDataFieldRepository {
  final CustomFieldDatabase _database = CustomFieldDatabase();

  /// Create a new custom app data field
  Future<void> createCustomAppDataField(CustomAppDataField field) async {
    try {
      await _database.insertCustomField(field);
      if (kDebugMode) {
        debugPrint('✅ Created custom app data field: ${field.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating custom app data field: $e');
      }
      rethrow;
    }
  }

  /// Get custom app data field by ID
  Future<CustomAppDataField?> getCustomAppDataFieldById(String id) async {
    try {
      return await _database.getCustomFieldById(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting custom app data field $id: $e');
      }
      return null;
    }
  }

  /// Get all custom app data fields
  Future<List<CustomAppDataField>> getAllCustomAppDataFields() async {
    try {
      return await _database.getAllCustomFields();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all custom app data fields: $e');
      }
      return [];
    }
  }

  /// Get custom app data fields by category
  Future<List<CustomAppDataField>> getCustomAppDataFieldsByCategory(String category) async {
    try {
      return await _database.getCustomFieldsByCategory(category);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting custom app data fields for category $category: $e');
      }
      return [];
    }
  }

  /// Get custom app data field by field name
  Future<CustomAppDataField?> getCustomAppDataFieldByName(String fieldName) async {
    try {
      final fields = await _database.searchCustomFields(fieldName);
      return fields.isNotEmpty ? fields.first : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting custom app data field by name $fieldName: $e');
      }
      return null;
    }
  }

  /// Update custom app data field
  Future<void> updateCustomAppDataField(CustomAppDataField field) async {
    try {
      await _database.updateCustomField(field);
      if (kDebugMode) {
        debugPrint('✅ Updated custom app data field: ${field.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating custom app data field: $e');
      }
      rethrow;
    }
  }

  /// Update field value only
  Future<void> updateFieldValue(String fieldId, String newValue) async {
    try {
      final field = await getCustomAppDataFieldById(fieldId);
      if (field != null) {
        field.updateValue(newValue);
        await updateCustomAppDataField(field);
      } else {
        throw Exception('Custom app data field $fieldId not found');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating field value: $e');
      }
      rethrow;
    }
  }

  /// Delete custom app data field by ID
  Future<void> deleteCustomAppDataField(String id) async {
    try {
      await _database.deleteCustomField(id);
      if (kDebugMode) {
        debugPrint('✅ Deleted custom app data field: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting custom app data field: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple custom app data fields
  Future<void> insertCustomAppDataFieldsBatch(List<CustomAppDataField> fields) async {
    try {
      await _database.insertCustomFields(fields);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${fields.length} custom app data fields');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting custom app data fields batch: $e');
      }
      rethrow;
    }
  }

  /// Clear all custom app data fields
  Future<void> clearAllCustomAppDataFields() async {
    try {
      await _database.clearAllCustomFields();
      if (kDebugMode) {
        debugPrint('✅ Cleared all custom app data fields');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing custom app data fields: $e');
      }
      rethrow;
    }
  }

  /// Get custom app data field statistics
  Future<Map<String, dynamic>> getCustomAppDataFieldStatistics() async {
    try {
      return await _database.getCustomFieldStatistics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting custom app data field statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_fields': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get required fields only
  Future<List<CustomAppDataField>> getRequiredFields() async {
    try {
      final allFields = await getAllCustomAppDataFields();
      return allFields.where((field) => field.isRequired).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting required fields: $e');
      }
      return [];
    }
  }

  /// Get fields with empty values
  Future<List<CustomAppDataField>> getFieldsWithEmptyValues() async {
    try {
      final allFields = await getAllCustomAppDataFields();
      return allFields.where((field) => field.currentValue.isEmpty).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting fields with empty values: $e');
      }
      return [];
    }
  }

  /// Get fields by type
  Future<List<CustomAppDataField>> getFieldsByType(String fieldType) async {
    try {
      final allFields = await getAllCustomAppDataFields();
      return allFields.where((field) => field.fieldType == fieldType).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting fields by type $fieldType: $e');
      }
      return [];
    }
  }

  /// Get field category summary
  Future<Map<String, dynamic>> getCategorySummary() async {
    try {
      final fields = await getAllCustomAppDataFields();
      
      if (fields.isEmpty) {
        return {
          'total_fields': 0,
          'categories': <String, int>{},
          'field_types': <String, int>{},
          'required_fields': 0,
          'empty_fields': 0,
        };
      }

      final categories = <String, int>{};
      final fieldTypes = <String, int>{};
      int requiredCount = 0;
      int emptyCount = 0;
      
      for (final field in fields) {
        categories[field.category] = (categories[field.category] ?? 0) + 1;
        fieldTypes[field.fieldType] = (fieldTypes[field.fieldType] ?? 0) + 1;
        if (field.isRequired) requiredCount++;
        if (field.currentValue.isEmpty) emptyCount++;
      }

      return {
        'total_fields': fields.length,
        'categories': categories,
        'field_types': fieldTypes,
        'required_fields': requiredCount,
        'empty_fields': emptyCount,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting category summary: $e');
      }
      return {
        'error': e.toString(),
        'total_fields': 0,
      };
    }
  }

  /// Search fields by display name
  Future<List<CustomAppDataField>> searchByDisplayName(String searchTerm) async {
    try {
      final allFields = await getAllCustomAppDataFields();
      return allFields.where((field) {
        return field.displayName.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching fields by display name: $e');
      }
      return [];
    }
  }

  /// Get fields ordered by sort order
  Future<List<CustomAppDataField>> getFieldsOrderedBySortOrder() async {
    try {
      final allFields = await getAllCustomAppDataFields();
      allFields.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return allFields;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting fields ordered by sort order: $e');
      }
      return [];
    }
  }

  /// Get dropdown fields with their options
  Future<List<CustomAppDataField>> getDropdownFields() async {
    try {
      final allFields = await getAllCustomAppDataFields();
      return allFields.where((field) => 
          field.dropdownOptions != null && field.dropdownOptions!.isNotEmpty).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting dropdown fields: $e');
      }
      return [];
    }
  }

  /// Validate required fields
  Future<Map<String, dynamic>> validateRequiredFields() async {
    try {
      final requiredFields = await getRequiredFields();
      final emptyRequiredFields = requiredFields.where((field) => field.currentValue.isEmpty).toList();
      
      return {
        'is_valid': emptyRequiredFields.isEmpty,
        'total_required_fields': requiredFields.length,
        'empty_required_fields': emptyRequiredFields.length,
        'missing_fields': emptyRequiredFields.map((field) => {
          'id': field.id,
          'field_name': field.fieldName,
          'display_name': field.displayName,
          'category': field.category,
        }).toList(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error validating required fields: $e');
      }
      return {
        'is_valid': false,
        'error': e.toString(),
      };
    }
  }

  /// Get field values as a map (for use in templates, etc.)
  Future<Map<String, String>> getFieldValuesAsMap() async {
    try {
      final fields = await getAllCustomAppDataFields();
      final Map<String, String> fieldValues = {};
      
      for (final field in fields) {
        fieldValues[field.fieldName] = field.currentValue;
      }
      
      return fieldValues;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting field values as map: $e');
      }
      return {};
    }
  }
}