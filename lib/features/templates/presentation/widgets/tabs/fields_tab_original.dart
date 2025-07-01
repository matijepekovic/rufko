import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/models/settings/custom_app_data.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../dialogs/field_dialog.dart';
import '../../../../../core/utils/helpers/common_utils.dart';
import '../../../../../app/theme/rufko_theme.dart';
import '../../../../../core/mixins/template_tab_mixin.dart';

class FieldsTab extends StatefulWidget {
  const FieldsTab({super.key});

  @override
  State<FieldsTab> createState() => _FieldsTabState();
}

class _FieldsTabState extends State<FieldsTab> with TemplateTabMixin {
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
      _showEditFieldDialog(existingItem as CustomAppDataField);
    } else {
      _showAddFieldDialog();
    }
  }

  @override
  Widget buildItemTile(
      dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall) {
    final field = item as CustomAppDataField;

    return InkWell(
      onTap: isSelectionMode
          ? () => toggleSelection(getItemId(field))
          : () => navigateToEditor(field),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmall ? 8 : 12,
          vertical: isVerySmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
          border: isSelected
              ? Border.all(color: primaryColor, width: 1)
              : const Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: Row(
          children: [
            // Field type indicator
            Container(
              width: isVerySmall ? 24 : 28,
              height: isVerySmall ? 24 : 28,
              decoration: BoxDecoration(
                color: _getFieldTypeColor(field.fieldType),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getFieldTypeIcon(field.fieldType),
                color: Colors.white,
                size: isVerySmall ? 12 : 14,
              ),
            ),

            SizedBox(width: isVerySmall ? 8 : 12),

            // Field info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isVerySmall ? 13 : 14,
                      color: isSelected ? primaryColor : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isVerySmall ? 2 : 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.fieldName,
                          style: TextStyle(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.7)
                                : Colors.grey[600],
                            fontSize: isVerySmall ? 10 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        field.fieldType,
                        style: TextStyle(
                          color: _getFieldTypeColor(field.fieldType),
                          fontSize: isVerySmall ? 9 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (field.currentValue.isNotEmpty) ...[
                    SizedBox(height: isVerySmall ? 2 : 3),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isVerySmall ? 4 : 6,
                          vertical: isVerySmall ? 1 : 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        field.currentValue,
                        style: TextStyle(
                            fontSize: isVerySmall ? 9 : 10,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator or menu
            if (isSelectionMode)
              Container(
                width: isVerySmall ? 20 : 24,
                height: isVerySmall ? 20 : 24,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? Icon(Icons.check,
                        color: Colors.white, size: isVerySmall ? 12 : 14)
                    : null,
              )
            else
              PopupMenuButton<String>(
                onSelected: (action) => _handleFieldAction(action, field),
                icon: Icon(
                  Icons.more_vert,
                  size: isVerySmall ? 16 : 18,
                  color: Colors.grey[600],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
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

  // Field-specific helper methods (these are unique to fields)
  Color _getFieldTypeColor(String fieldType) {
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

  IconData _getFieldTypeIcon(String fieldType) {
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

  void _handleFieldAction(String action, CustomAppDataField field) {
    switch (action) {
      case 'edit':
        navigateToEditor(field);
        break;
      case 'delete':
        _deleteField(field);
        break;
    }
  }

  void _showAddFieldDialog() async {
    if (!mounted) return;
    final returnedValue = await showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: context.read<AppStateProvider>().getAllTemplateCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: CircularProgressIndicator(),
              );
            }

            final allCategories = snapshot.data!;
            final customFieldCategories = allCategories['custom_fields'] ?? [];

            final availableCategories = <String>[];
            final categoryNames = <String, String>{};

            for (final category in customFieldCategories) {
              final categoryKey = category['key'] as String;
              final categoryName = category['name'] as String;
              availableCategories.add(categoryKey);
              categoryNames[categoryKey] = categoryName;
            }

            return FieldDialog.add(
              categories: availableCategories,
              categoryNames: categoryNames,
            );
          },
        );
      },
    );
    
    if (returnedValue != null && mounted) {
      final appState = context.read<AppStateProvider>();
      try {
        await appState.addCustomAppDataField(returnedValue);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding field: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditFieldDialog(CustomAppDataField field) async {
    if (!mounted) return;
    final updatedField = await showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: context.read<AppStateProvider>().getAllTemplateCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: CircularProgressIndicator(),
              );
            }

            final allCategories = snapshot.data!;
            final customFieldCategories = allCategories['custom_fields'] ?? [];

            final availableCategories = <String>[field.category];
            final categoryNames = <String, String>{
              field.category: formatCategoryName(field.category)
            };

            for (final category in customFieldCategories) {
              final categoryKey = category['key'] as String;
              final categoryName = category['name'] as String;
              if (!availableCategories.contains(categoryKey)) {
                availableCategories.add(categoryKey);
                categoryNames[categoryKey] = categoryName;
              }
            }

            return FieldDialog.edit(
              field,
              categories: availableCategories,
              categoryNames: categoryNames,
            );
          },
        );
      },
    );
    
    if (updatedField != null && mounted) {
      try {
        final appState = context.read<AppStateProvider>();
        await appState.updateCustomAppDataFieldStructure(updatedField);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated field: ${updatedField.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating field: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteField(CustomAppDataField field) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this field?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field: ${field.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${field.fieldName}'),
                    Text('Category: ${field.category}'),
                    if (field.currentValue.isNotEmpty)
                      Text('Value: ${field.currentValue}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true && mounted) {
      try {
        await deleteItemById(field.id);

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Deleted field: ${field.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error deleting field: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}