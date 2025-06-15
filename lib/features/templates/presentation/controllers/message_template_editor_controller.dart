import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/templates/message_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for managing message template editor state and operations
/// Extracted from MessageTemplateEditorScreen to separate business logic from UI
class MessageTemplateEditorController extends ChangeNotifier {
  final BuildContext context;
  final MessageTemplate? initialTemplate;
  final String? initialCategory;

  // Form key and controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController templateNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController messageContentController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // State variables
  String? _selectedCategoryKey;
  bool _isActive = true;
  List<String> _detectedPlaceholders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounceTimer;

  MessageTemplateEditorController({
    required this.context,
    this.initialTemplate,
    this.initialCategory,
  }) {
    _initializeFormData();
    _setupListeners();
  }

  // Getters
  bool get isEditing => initialTemplate != null;
  String? get selectedCategoryKey => _selectedCategoryKey;
  bool get isActive => _isActive;
  List<String> get detectedPlaceholders => _detectedPlaceholders;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Setters with notification
  set selectedCategoryKey(String? value) {
    _selectedCategoryKey = value;
    notifyListeners();
  }

  set isActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  /// Initialize form data from existing template or defaults
  void _initializeFormData() {
    _selectedCategoryKey = initialTemplate?.userCategoryKey ?? initialCategory;
    
    if (initialTemplate != null) {
      _loadExistingTemplate();
    }
  }

  /// Setup text controller listeners
  void _setupListeners() {
    messageContentController.addListener(_onContentChanged);
    searchController.addListener(_onSearchChanged);
  }

  /// Load existing template data
  void _loadExistingTemplate() {
    final template = initialTemplate!;
    templateNameController.text = template.templateName;
    descriptionController.text = template.description;
    messageContentController.text = template.messageContent;
    _selectedCategoryKey = template.userCategoryKey;
    _isActive = template.isActive;
    _detectedPlaceholders = List.from(template.placeholders);
    debugPrint('📝 Loaded existing message template: ${template.templateName}');
  }

  /// Handle content changes for placeholder detection with debouncing
  void _onContentChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final allPlaceholders = MessageTemplate.extractPlaceholders(
        messageContentController.text,
      );

      if (!_listEquals(_detectedPlaceholders, allPlaceholders)) {
        _detectedPlaceholders = allPlaceholders;
        notifyListeners();
      }
    });
  }

  /// Helper to compare lists
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Handle search query changes
  void _onSearchChanged() {
    _searchQuery = searchController.text.toLowerCase();
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    searchController.clear();
    _searchQuery = '';
    notifyListeners();
  }

  /// Validate form
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedCategoryKey == null || _selectedCategoryKey!.isEmpty) {
      return false;
    }

    return true;
  }

  /// Save template
  Future<bool> saveTemplate() async {
    if (!validateForm()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final appState = context.read<AppStateProvider>();
      
      if (isEditing) {
        await _updateExistingTemplate(appState);
      } else {
        await _createNewTemplate(appState);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error saving template: $e');
      return false;
    }
  }

  /// Update existing template
  Future<void> _updateExistingTemplate(AppStateProvider appState) async {
    final template = initialTemplate!;
    
    final updatedTemplate = MessageTemplate(
      id: template.id,
      templateName: templateNameController.text.trim(),
      description: descriptionController.text.trim(),
      category: _selectedCategoryKey!,
      messageContent: messageContentController.text.trim(),
      userCategoryKey: _selectedCategoryKey!,
      isActive: _isActive,
      placeholders: _detectedPlaceholders,
      createdAt: template.createdAt,
      updatedAt: DateTime.now(),
    );

    await appState.updateMessageTemplate(updatedTemplate);
  }

  /// Create new template
  Future<void> _createNewTemplate(AppStateProvider appState) async {
    final template = MessageTemplate(
      templateName: templateNameController.text.trim(),
      description: descriptionController.text.trim(),
      category: _selectedCategoryKey!,
      messageContent: messageContentController.text.trim(),
      userCategoryKey: _selectedCategoryKey!,
      isActive: _isActive,
      placeholders: _detectedPlaceholders,
    );

    await appState.addMessageTemplate(template);
  }

  /// Create new category
  Future<String?> createCategory(String categoryName) async {
    try {
      final appState = context.read<AppStateProvider>();
      final categoryKey = categoryName.toLowerCase().replaceAll(' ', '_');

      await appState.addTemplateCategory('message_templates', categoryKey, categoryName);
      
      _selectedCategoryKey = categoryKey;
      notifyListeners();
      
      return categoryKey;
    } catch (e) {
      debugPrint('Error creating category: $e');
      return null;
    }
  }

  /// Get filtered field categories for search
  Map<String, List<String>> getFilteredFieldCategories() {
    final appState = context.read<AppStateProvider>();
    final availableProducts = appState.products;
    final customFields = appState.customAppDataFields;

    final categorizedFields = MessageTemplate.getCategorizedAppDataFieldTypes(
      availableProducts,
      customFields,
    );

    if (_searchQuery.isEmpty) {
      return categorizedFields;
    }

    final filteredCategories = <String, List<String>>{};

    for (final entry in categorizedFields.entries) {
      final categoryName = entry.key;
      final fields = entry.value;

      final filteredFields = fields.where((field) {
        final fieldDisplayName = MessageTemplate.getFieldDisplayName(field, customFields);
        return fieldDisplayName.toLowerCase().contains(_searchQuery) ||
            field.toLowerCase().contains(_searchQuery) ||
            categoryName.toLowerCase().contains(_searchQuery);
      }).toList();

      if (filteredFields.isNotEmpty) {
        filteredCategories[categoryName] = filteredFields;
      }
    }

    return filteredCategories;
  }

  /// Get field display name
  String getFieldDisplayName(String fieldType) {
    final appState = context.read<AppStateProvider>();
    final customFields = appState.customAppDataFields;
    return MessageTemplate.getFieldDisplayName(fieldType, customFields);
  }

  /// Get field hint text
  String getFieldHint(String appDataType) {
    if (appDataType.contains('Name')) return 'Name field';
    if (appDataType.contains('Phone')) return 'Phone number';
    if (appDataType.contains('Email')) return 'Email address';
    if (appDataType.contains('Address')) return 'Address info';
    if (appDataType.contains('company')) return 'Business info';
    if (appDataType.contains('customer')) return 'Customer info';
    if (appDataType.contains('quote')) return 'Quote data';
    return 'Insert field';
  }

  /// Get category icon
  Widget getCategoryIcon(String categoryName) {
    IconData iconData;
    Color iconColor;

    if (categoryName.contains('Customer')) {
      iconData = Icons.person;
      iconColor = Colors.blue.shade600;
    } else if (categoryName.contains('Company')) {
      iconData = Icons.business;
      iconColor = Colors.indigo.shade600;
    } else if (categoryName.contains('Quote')) {
      iconData = Icons.description;
      iconColor = Colors.purple.shade600;
    } else if (categoryName.contains('Products')) {
      iconData = Icons.inventory;
      iconColor = Colors.green.shade600;
    } else if (categoryName.contains('Calculations')) {
      iconData = Icons.calculate;
      iconColor = Colors.orange.shade600;
    } else {
      iconData = Icons.settings;
      iconColor = Colors.grey.shade600;
    }
    return Icon(iconData, size: 18, color: iconColor);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    templateNameController.dispose();
    descriptionController.dispose();
    messageContentController.dispose();
    searchController.dispose();
    super.dispose();
  }
}