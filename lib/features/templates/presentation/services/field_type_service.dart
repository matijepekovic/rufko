import 'package:flutter/material.dart';

/// Service for handling field type metadata and styling
/// Extracted from FieldsTab for better organization and reusability
class FieldTypeService {
  
  /// Get color for field type indicator
  static Color getFieldTypeColor(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Colors.blue;
      case 'number':
        return Colors.green;
      case 'email':
        return Colors.orange;
      case 'phone':
        return Colors.purple;
      case 'multiline':
        return Colors.teal;
      case 'date':
        return Colors.red;
      case 'currency':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for field type indicator
  static IconData getFieldTypeIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'multiline':
        return Icons.notes;
      case 'date':
        return Icons.calendar_today;
      case 'currency':
        return Icons.attach_money;
      default:
        return Icons.input;
    }
  }

  /// Get human-readable field type name
  static String getFieldTypeName(String fieldType) {
    switch (fieldType) {
      case 'text':
        return 'Text';
      case 'number':
        return 'Number';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone';
      case 'multiline':
        return 'Multi-line';
      case 'date':
        return 'Date';
      case 'currency':
        return 'Currency';
      default:
        return 'Unknown';
    }
  }

  /// Get all available field types
  static List<String> getAllFieldTypes() {
    return [
      'text',
      'number',
      'email',
      'phone',
      'multiline',
      'date',
      'currency',
    ];
  }

  /// Check if field type supports validation
  static bool supportsValidation(String fieldType) {
    return ['email', 'phone', 'number', 'currency'].contains(fieldType);
  }

  /// Check if field type supports multiple lines
  static bool isMultiLine(String fieldType) {
    return fieldType == 'multiline';
  }
}