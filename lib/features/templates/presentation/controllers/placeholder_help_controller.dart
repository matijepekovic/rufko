import 'package:flutter/material.dart';

import '../../../../../data/models/templates/email_template.dart';
import '../../../../../data/models/business/product.dart';
import '../../../../../data/providers/state/app_state_provider.dart';

/// Controller for filtering template placeholder fields by search query.
class PlaceholderHelpController extends ChangeNotifier {
  PlaceholderHelpController({required AppStateProvider appState})
      : _availableProducts = appState.products,
        _customFields = appState.customAppDataFields {
    _categorizedFields = EmailTemplate.getCategorizedAppDataFieldTypes(
      _availableProducts,
      _customFields,
    );
  }

  final List<Product> _availableProducts;
  final List<dynamic> _customFields;
  late final Map<String, List<String>> _categorizedFields;

  String _searchQuery = '';

  /// Current search query (lowercase).
  String get searchQuery => _searchQuery;
  set searchQuery(String value) {
    _searchQuery = value.toLowerCase();
    notifyListeners();
  }

  /// Filtered categories based on the current search query.
  Map<String, List<String>> get filteredCategories {
    final filtered = <String, List<String>>{};
    for (final entry in _categorizedFields.entries) {
      final categoryName = entry.key;
      final fields = entry.value;
      final filteredFields = fields.where((field) {
        if (_searchQuery.isEmpty) return true;
        final fieldDisplayName =
            EmailTemplate.getFieldDisplayName(field, _customFields);
        return fieldDisplayName.toLowerCase().contains(_searchQuery) ||
            field.toLowerCase().contains(_searchQuery) ||
            categoryName.toLowerCase().contains(_searchQuery);
      }).toList();
      if (filteredFields.isNotEmpty) {
        filtered[categoryName] = filteredFields;
      }
    }
    return filtered;
  }

  List<dynamic> get customFields => _customFields;
}
