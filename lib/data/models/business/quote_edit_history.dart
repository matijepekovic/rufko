import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Enum for different types of quote edit reasons
enum QuoteEditReason {
  customerRequest('customer_request', 'Customer Request'),
  priceCorrection('price_correction', 'Price Correction'),
  materialChange('material_change', 'Material Change'),
  other('other', 'Other');

  const QuoteEditReason(this.value, this.displayName);
  
  final String value;
  final String displayName;

  /// Get enum from string value
  static QuoteEditReason fromValue(String value) {
    return QuoteEditReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => QuoteEditReason.other,
    );
  }

  /// Get display icon for the edit reason
  String get icon {
    switch (this) {
      case QuoteEditReason.customerRequest:
        return '👤';
      case QuoteEditReason.priceCorrection:
        return '💰';
      case QuoteEditReason.materialChange:
        return '🔧';
      case QuoteEditReason.other:
        return '✏️';
    }
  }
}

/// Model for tracking quote edit history
class QuoteEditHistory {
  late String id;
  String quoteId;
  int version;
  QuoteEditReason editReason;
  String? editDescription;
  DateTime editedAt;
  Map<String, dynamic>? changesSummary;

  QuoteEditHistory({
    String? id,
    required this.quoteId,
    required this.version,
    required this.editReason,
    this.editDescription,
    DateTime? editedAt,
    this.changesSummary,
  }) : editedAt = editedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  /// Create from database map
  factory QuoteEditHistory.fromMap(Map<String, dynamic> map) {
    return QuoteEditHistory(
      id: map['id'],
      quoteId: map['quote_id'],  // Fixed: snake_case from database
      version: map['version']?.toInt() ?? 1,
      editReason: QuoteEditReason.fromValue(map['edit_reason'] ?? 'other'),  // Fixed: snake_case from database
      editDescription: map['edit_description'],  // Fixed: snake_case from database
      editedAt: DateTime.parse(map['edited_at']),  // Fixed: snake_case from database
      changesSummary: map['changes_summary'] != null  // Fixed: snake_case from database
          ? (map['changes_summary'] is String 
              ? jsonDecode(map['changes_summary']) 
              : Map<String, dynamic>.from(map['changes_summary']))
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,  // Fixed: snake_case for database
      'version': version,
      'edit_reason': editReason.value,  // Fixed: snake_case for database
      'edit_description': editDescription,  // Fixed: snake_case for database
      'edited_at': editedAt.toIso8601String(),  // Fixed: snake_case for database
      'changes_summary': changesSummary != null ? jsonEncode(changesSummary) : null,  // Fixed: snake_case for database and JSON encoding
    };
  }

  /// Get formatted display text for the history entry
  String get displayText {
    switch (editReason) {
      case QuoteEditReason.customerRequest:
        return editDescription ?? 'Customer requested changes';
      case QuoteEditReason.priceCorrection:
        return editDescription ?? 'Price corrected';
      case QuoteEditReason.materialChange:
        return editDescription ?? 'Materials updated';
      case QuoteEditReason.other:
        return editDescription ?? 'Quote updated';
    }
  }

  /// Get short summary for timeline display
  String get shortSummary {
    if (changesSummary != null && changesSummary!.isNotEmpty) {
      final changes = <String>[];
      
      if (changesSummary!.containsKey('priceChange')) {
        final oldPrice = changesSummary!['priceChange']['old'];
        final newPrice = changesSummary!['priceChange']['new'];
        changes.add('Price: \$$oldPrice → \$$newPrice');
      }
      
      if (changesSummary!.containsKey('levelChanges')) {
        changes.add('Levels modified');
      }
      
      if (changesSummary!.containsKey('addonChanges')) {
        changes.add('Add-ons updated');
      }
      
      if (changes.isNotEmpty) {
        return changes.join(', ');
      }
    }
    
    return displayText;
  }

  @override
  String toString() {
    return 'QuoteEditHistory(id: $id, quoteId: $quoteId, version: v$version, reason: ${editReason.displayName})';
  }
}