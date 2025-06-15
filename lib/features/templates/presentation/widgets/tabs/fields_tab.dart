import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/settings/custom_app_data.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../app/theme/rufko_theme.dart';
import '../../../../../core/mixins/template_tab_mixin.dart';
import '../../controllers/field_operations_controller.dart';
import '../field_components/field_tile.dart';

/// Refactored FieldsTab with extracted components and controllers
/// Original 561-line monolithic widget broken down into manageable components
/// All original functionality preserved with improved maintainability
class FieldsTab extends StatefulWidget {
  const FieldsTab({super.key});

  @override
  State<FieldsTab> createState() => _FieldsTabState();
}

class _FieldsTabState extends State<FieldsTab> with TemplateTabMixin {
  late FieldOperationsController _fieldController;

  @override
  void initState() {
    super.initState();
    _fieldController = FieldOperationsController(context);
  }

  // Implement required mixin properties
  @override
  Color get primaryColor => RufkoTheme.primaryColor;

  @override
  String get itemTypeName => 'field';

  @override
  String get itemTypePlural => 'fields';

  @override
  IconData get tabIcon => Icons.data_object;

  @override
  String get searchHintText => 'Search fields...';

  @override
  String get categoryType => 'custom_fields';

  // Implement required data methods
  @override
  List<dynamic> getAllItems() {
    return context.read<AppStateProvider>().customAppDataFields;
  }

  @override
  List<dynamic> getFilteredItems() {
    var filtered = getAllItems().cast<CustomAppDataField>();

    if (selectedCategory != 'all') {
      filtered = filtered.where((f) => f.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((f) =>
              f.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              f.fieldName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> deleteItemById(String id) async {
    await context.read<AppStateProvider>().deleteCustomAppDataField(id);
  }

  @override
  String getItemId(dynamic item) {
    return (item as CustomAppDataField).id;
  }

  @override
  String getItemDisplayName(dynamic item) {
    return (item as CustomAppDataField).displayName;
  }

  // Implement required UI/navigation methods
  @override
  void navigateToEditor([dynamic existingItem]) {
    if (existingItem != null) {
      _fieldController.showEditFieldDialog(existingItem as CustomAppDataField);
    } else {
      _fieldController.showAddFieldDialog();
    }
  }

  @override
  Widget buildItemTile(
      dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall) {
    final field = item as CustomAppDataField;

    return FieldTile(
      field: field,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      isSmallScreen: isSmallScreen,
      isVerySmall: isVerySmall,
      primaryColor: primaryColor,
      onTap: isSelectionMode
          ? () => toggleSelection(getItemId(field))
          : () => navigateToEditor(field),
      onAction: _fieldController.handleFieldAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're embedded in Templates screen (no Scaffold needed)
    final bool isEmbedded =
        ModalRoute.of(context)?.settings.name != '/custom_app_data';

    if (isEmbedded) {
      // Return just the content without Scaffold/AppBar when embedded
      return Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return buildMainLayout(); // This comes from the mixin!
        },
      );
    }

    // Full screen version with AppBar (when accessed directly)
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Fields'),
        backgroundColor: RufkoTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => navigateToEditor(),
            tooltip: 'Add New Field',
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return buildMainLayout(); // This comes from the mixin!
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToEditor(),
        backgroundColor: RufkoTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
