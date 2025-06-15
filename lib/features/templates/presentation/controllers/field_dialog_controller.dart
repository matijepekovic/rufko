import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/custom_app_data.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for managing field dialog state and operations
/// Extracted from FieldDialog to separate business logic from UI
class FieldDialogController extends ChangeNotifier {
  final BuildContext context;
  final FieldDialogMode mode;
  final CustomAppDataField? existingField;
  final String? preSelectedCategory;

  // Form controllers
  final TextEditingController fieldNameController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController valueTextController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // State variables
  String _selectedFieldCategory = '';
  String _selectedFieldType = 'text';
  bool _isRequired = false;
  bool _isLoading = false;
  bool _checkboxValue = false;
  List<String> _currentCategories = [];
  Map<String, String> _currentCategoryNames = {};

  static const String createNewCategoryValue = '__create_new_category__';

  FieldDialogController({
    required this.context,
    required this.mode,
    this.existingField,
    this.preSelectedCategory,
    required List<String> initialCategories,
    required Map<String, String> initialCategoryNames,
  }) {
    _currentCategories = List.from(initialCategories);
    _currentCategoryNames = Map.from(initialCategoryNames);
    _initializeFields();
  }

  // Getters
  String get selectedFieldCategory => _selectedFieldCategory;
  String get selectedFieldType => _selectedFieldType;
  bool get isRequired => _isRequired;
  bool get isLoading => _isLoading;
  bool get checkboxValue => _checkboxValue;
  List<String> get currentCategories => _currentCategories;
  Map<String, String> get currentCategoryNames => _currentCategoryNames;

  // Setters with notification
  set selectedFieldCategory(String value) {
    _selectedFieldCategory = value;
    notifyListeners();
  }

  set selectedFieldType(String value) {
    _selectedFieldType = value;
    if (value == 'checkbox') {
      _checkboxValue = valueTextController.text.toLowerCase() == 'true';
    }
    notifyListeners();
  }

  set isRequired(bool value) {
    _isRequired = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set checkboxValue(bool value) {
    _checkboxValue = value;
    valueTextController.text = value.toString();
    notifyListeners();
  }

  /// Initialize field values based on mode and existing data
  void _initializeFields() {
    if (mode == FieldDialogMode.edit && existingField != null) {
      final field = existingField!;
      fieldNameController.text = field.fieldName;
      displayNameController.text = field.displayName;
      valueTextController.text = field.currentValue;

      if (_currentCategories.contains(field.category)) {
        _selectedFieldCategory = field.category;
      } else if (_currentCategories.isNotEmpty) {
        _selectedFieldCategory = _currentCategories.first;
      } else {
        _selectedFieldCategory = field.category;
      }

      _selectedFieldType = field.fieldType;
      _isRequired = field.isRequired;

      if (_selectedFieldType == 'checkbox') {
        _checkboxValue = field.currentValue.toLowerCase() == 'true';
      }
    } else {
      // Add mode initialization
      if (preSelectedCategory != null && _currentCategories.contains(preSelectedCategory!)) {
        _selectedFieldCategory = preSelectedCategory!;
      } else if (_currentCategories.isNotEmpty) {
        _selectedFieldCategory = _currentCategories.first;
      } else {
        _selectedFieldCategory = createNewCategoryValue;
      }
      _selectedFieldType = 'text';
      _isRequired = false;
      valueTextController.text = 'false';
    }

    debugPrint('🎯 FieldDialogController initialized: $_selectedFieldCategory, $_selectedFieldType');
  }

  /// Auto-generate display name from field name
  String generateDisplayName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  /// Handle field name changes and auto-generate display name for add mode
  void onFieldNameChanged(String value) {
    if (mode == FieldDialogMode.add) {
      if (displayNameController.text.isEmpty || 
          displayNameController.text == generateDisplayName(fieldNameController.text)) {
        displayNameController.text = generateDisplayName(value);
      }
    }
  }

  /// Validate field name uniqueness and format
  String? validateFieldName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter field name';
    }
    if (value.contains(' ')) return 'No spaces allowed';

    final appState = context.read<AppStateProvider>();
    if (mode == FieldDialogMode.edit) {
      if (value.trim() != existingField!.fieldName &&
          appState.customAppDataFields.any((f) =>
              f.fieldName == value.trim() &&
              f.category == _selectedFieldCategory &&
              f.id != existingField!.id)) {
        return 'Name already exists';
      }
    } else {
      if (appState.customAppDataFields.any((f) =>
          f.fieldName == value.trim() &&
          f.category == _selectedFieldCategory)) {
        return 'Name already exists in this category';
      }
    }
    return null;
  }

  /// Validate display name
  String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter display name';
    }
    return null;
  }

  /// Validate current/default value
  String? validateValue(String? value) {
    if (value == null || value.isEmpty) {
      return mode == FieldDialogMode.add
          ? 'Enter default value'
          : 'Enter current value';
    }
    return null;
  }

  /// Validate category selection
  String? validateCategory(String? value) {
    return value == null || value == createNewCategoryValue
        ? 'Select category'
        : null;
  }

  /// Validate field type selection
  String? validateFieldType(String? value) {
    return value == null ? 'Select type' : null;
  }

  /// Handle category selection change
  Future<void> onCategoryChanged(String? newValue) async {
    if (newValue == createNewCategoryValue) {
      final newCategory = await _createNewCategoryAndReturn();
      if (newCategory != null) {
        await _refreshCategories();
        _selectedFieldCategory = newCategory;
        notifyListeners();
      }
    } else if (newValue != null && newValue != createNewCategoryValue) {
      _selectedFieldCategory = newValue;
      notifyListeners();
    }
  }

  /// Create new category and return its key
  Future<String?> _createNewCategoryAndReturn() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _buildNewCategoryDialog(controller);
      },
    );
  }

  /// Build new category creation dialog
  Widget _buildNewCategoryDialog(TextEditingController controller) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNewCategoryHeader(),
            _buildNewCategoryContent(controller),
            _buildNewCategoryActions(controller),
          ],
        ),
      ),
    );
  }

  /// Build new category dialog header
  Widget _buildNewCategoryHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3), // RufkoTheme.primaryColor
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Create Field Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build new category dialog content
  Widget _buildNewCategoryContent(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create a new category for fields:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g., Project Info, Client Details, Inspection',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 14),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  /// Build new category dialog actions
  Widget _buildNewCategoryActions(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _handleCreateCategory(controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3), // RufkoTheme.primaryColor
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Handle category creation
  Future<void> _handleCreateCategory(TextEditingController controller) async {
    final categoryName = controller.text.trim();
    if (categoryName.isNotEmpty) {
      try {
        final appState = context.read<AppStateProvider>();
        final categoryKey = categoryName.toLowerCase().replaceAll(' ', '_');

        await appState.addTemplateCategory('custom_fields', categoryKey, categoryName);

        if (context.mounted) {
          Navigator.of(context).pop(categoryKey);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created category: $categoryName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Refresh categories from app state
  Future<void> _refreshCategories() async {
    final appState = context.read<AppStateProvider>();
    await appState.loadTemplateCategories();

    final updatedCategories = appState.templateCategories
        .where((cat) => cat.templateType == 'custom_fields')
        .toList();

    _currentCategories.clear();
    _currentCategoryNames.clear();

    for (final category in updatedCategories) {
      _currentCategories.add(category.key);
      _currentCategoryNames[category.key] = category.name;
    }

    debugPrint('🔄 Refreshed categories: ${_currentCategories.length}');
  }

  /// Handle save operation
  Future<CustomAppDataField?> handleSave() async {
    if (!formKey.currentState!.validate()) {
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (mode == FieldDialogMode.add) {
        final newField = CustomAppDataField(
          fieldName: fieldNameController.text.trim(),
          displayName: displayNameController.text.trim(),
          fieldType: _selectedFieldType,
          category: _selectedFieldCategory,
          currentValue: valueTextController.text.trim(),
          placeholder: null,
          description: null,
          isRequired: _isRequired,
        );
        debugPrint('✅ Created new field: ${newField.fieldName}');
        return newField;
      } else {
        final updatedField = CustomAppDataField(
          id: existingField!.id,
          fieldName: fieldNameController.text.trim(),
          displayName: displayNameController.text.trim(),
          fieldType: _selectedFieldType,
          category: _selectedFieldCategory,
          currentValue: valueTextController.text.trim(),
          placeholder: null,
          description: null,
          isRequired: _isRequired,
          sortOrder: existingField!.sortOrder,
          createdAt: existingField!.createdAt,
          updatedAt: DateTime.now(),
        );
        debugPrint('✅ Updated field: ${updatedField.fieldName}');
        return updatedField;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mode == FieldDialogMode.add
                ? 'Error adding field: $e'
                : 'Error saving field: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Save field failed: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fieldNameController.dispose();
    displayNameController.dispose();
    valueTextController.dispose();
    debugPrint('🧹 FieldDialogController disposed');
    super.dispose();
  }
}

/// Enum for field dialog modes
enum FieldDialogMode { add, edit }