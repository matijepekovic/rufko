// lib/screens/custom_app_data_screen.dart - FIXED FILTER CHIP DATA SOURCE

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_app_data.dart';
import '../providers/app_state_provider.dart';
import '../widgets/add_custom_field_dialog.dart';
import '../widgets/edit_custom_field_dialog.dart';
import '../utils/common_utils.dart';
import '../theme/rufko_theme.dart';

class CustomAppDataScreen extends StatefulWidget {
  const CustomAppDataScreen({super.key});

  @override
  State<CustomAppDataScreen> createState() => _CustomAppDataScreenState();
}

class _CustomAppDataScreenState extends State<CustomAppDataScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  bool _isFieldSelectionMode = false;
  Set<String> _selectedFieldIds = <String>{};

  @override
  Widget build(BuildContext context) {
    // Check if we're embedded in Templates screen (no Scaffold needed)
    final bool isEmbedded = ModalRoute.of(context)?.settings.name != '/custom_app_data';

    if (isEmbedded) {
      // Return just the content without Scaffold/AppBar when embedded
      return _buildManageFieldsTab();
    }

    // Full screen version with AppBar (when accessed directly)
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Custom App Data'),
        backgroundColor: RufkoTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFieldDialog,
            tooltip: 'Add New Field',
          ),
        ],
      ),
      body: _buildManageFieldsTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFieldDialog,
        backgroundColor: RufkoTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Field Selection Mode Methods
  void _enterFieldSelectionMode() {
    setState(() {
      _isFieldSelectionMode = true;
      _selectedFieldIds.clear();
    });
  }

  void _exitFieldSelectionMode() {
    setState(() {
      _isFieldSelectionMode = false;
      _selectedFieldIds.clear();
    });
  }

  void _toggleFieldSelection(String fieldId) {
    setState(() {
      if (_selectedFieldIds.contains(fieldId)) {
        _selectedFieldIds.remove(fieldId);
      } else {
        _selectedFieldIds.add(fieldId);
      }
    });
  }

  void _selectAllFields() {
    final appState = context.read<AppStateProvider>();
    final fields = _filterFields(appState.customAppDataFields);

    setState(() {
      if (_selectedFieldIds.length == fields.length) {
        _selectedFieldIds.clear();
      } else {
        _selectedFieldIds = fields.map((f) => f.id).toSet();
      }
    });
  }

  void _deleteSelectedFields() {
    if (_selectedFieldIds.isEmpty) return;

    // Store context reference before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedFieldIds.length} field${_selectedFieldIds.length == 1 ? '' : 's'}'),
        content: Text(
            _selectedFieldIds.length == 1
                ? 'Are you sure you want to delete this custom field?'
                : 'Are you sure you want to delete these ${_selectedFieldIds.length} custom fields?'
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final appState = context.read<AppStateProvider>();

                for (final fieldId in _selectedFieldIds) {
                  await appState.deleteCustomAppDataField(fieldId);
                }

                _exitFieldSelectionMode();
                navigator.pop();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Deleted ${_selectedFieldIds.length} field${_selectedFieldIds.length == 1 ? '' : 's'}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                navigator.pop();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting fields: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildManageFieldsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isPhone = constraints.maxWidth < 600;
        return Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            final allFields = appState.customAppDataFields;
            final filteredFields = _filterFields(allFields);
            final groupedFields = _groupFieldsByCategory(filteredFields);

            return Column(
              children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search custom fields...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      if (mounted) {
                        setState(() => _searchQuery = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🚀 FIXED: Use the same async data source as other tabs
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                            future: appState.getAllTemplateCategories(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(height: 40); // Placeholder while loading
                              }

                              final allCategories = snapshot.data!;
                              final customFieldCategories = allCategories['custom_fields'] ?? [];

                              if (kDebugMode) {
                                debugPrint('🔍 Custom Fields tab found ${customFieldCategories.length} categories from async source:');
                                for (final cat in customFieldCategories) {
                                  debugPrint('  - ${cat['key']}: ${cat['name']}');
                                }
                              }

                              return Row(
                                children: [
                                  // "All Fields" chip
                                  _buildCategoryFilterChip(
                                    'All Fields',
                                    Icons.view_list,
                                    _selectedCategory == 'all',
                                    'all',
                                  ),
                                  // Dynamic category chips from database
                                  ...customFieldCategories.map((category) {
                                    final categoryKey = category['key'] as String;
                                    final categoryName = category['name'] as String;
                                    return _buildCategoryFilterChip(
                                      categoryName,
                                      Icons.data_object,
                                      _selectedCategory == categoryKey,
                                      categoryKey,
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Select Button
                      if (!_isFieldSelectionMode)
                        isPhone
                            ? IconButton(
                                onPressed: _enterFieldSelectionMode,
                                icon: const Icon(Icons.checklist),
                                color: RufkoTheme.primaryColor,
                                tooltip: 'Select',
                              )
                            : ElevatedButton.icon(
                                onPressed: _enterFieldSelectionMode,
                                icon: const Icon(Icons.checklist, size: 18),
                                label: const Text('Select'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: RufkoTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              )
                      else
                        isPhone
                            ? Row(
                                children: [
                                  IconButton(
                                    onPressed: _selectAllFields,
                                    icon: const Icon(Icons.select_all),
                                    tooltip: _selectedFieldIds.length == filteredFields.length
                                        ? 'Deselect All'
                                        : 'Select All',
                                  ),
                                  IconButton(
                                    onPressed: _exitFieldSelectionMode,
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Cancel',
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _selectAllFields,
                                    icon: const Icon(Icons.select_all, size: 18),
                                    label: Text(
                                      _selectedFieldIds.length == filteredFields.length
                                          ? 'Deselect All'
                                          : 'Select All',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _exitFieldSelectionMode,
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Cancel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                    ],
                  ),
                ],
              ),
            ),

            // Selection mode info
            if (_isFieldSelectionMode) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFieldIds.isEmpty
                              ? 'Tap custom fields to select them'
                              : '${_selectedFieldIds.length} of ${filteredFields.length} fields selected',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_selectedFieldIds.isNotEmpty)
                        isPhone
                            ? IconButton(
                                onPressed: _deleteSelectedFields,
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                tooltip: 'Delete',
                              )
                            : ElevatedButton.icon(
                                onPressed: _deleteSelectedFields,
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Fields content or empty state
            Expanded(
              child: filteredFields.isEmpty
                  ? _buildEmptyState(isPhone)
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedFields.length,
                itemBuilder: (context, index) {
                  final category = groupedFields.keys.elementAt(index);
                  final categoryFields = groupedFields[category]!;

                  return _buildCategorySection(category, categoryFields, isPhone);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 🚀 NEW: Consistent filter chip builder (matches other tabs)
  Widget _buildCategoryFilterChip(String label, IconData icon, bool isSelected, String categoryKey) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: RufkoTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? categoryKey : 'all';
          });
        },
      ),
    );
  }

  Widget _buildCategorySection(String category, List<CustomAppDataField> fields, bool isPhone) {
    // 🚀 FIXED: Get category display name from async data source
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: context.read<AppStateProvider>().getAllTemplateCategories(),
      builder: (context, snapshot) {
        String categoryDisplayName = formatCategoryName(category);

        if (snapshot.hasData) {
          final allCategories = snapshot.data!;
          final customFieldCategories = allCategories['custom_fields'] ?? [];

          // Find the category display name from the database
          for (final cat in customFieldCategories) {
            if (cat['key'] == category) {
              categoryDisplayName = cat['name'] as String;
              break;
            }
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Container(
                padding: EdgeInsets.all(isPhone ? 12 : 16),
                decoration: BoxDecoration(
                  color: RufkoTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: RufkoTheme.primaryColor,
                      size: isPhone ? 18 : 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryDisplayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: RufkoTheme.primaryColor,
                        fontSize: isPhone ? 14 : 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${fields.length} fields',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isPhone ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Fields List
              ...fields.map((field) => _buildFieldTile(field, isPhone)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldTile(CustomAppDataField field, bool isPhone) {
    final isSelected = _selectedFieldIds.contains(field.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 3 : 1,
            color: isSelected ? RufkoTheme.primaryColor.withValues(alpha: 0.1) : null,
            child: InkWell(
              onTap: _isFieldSelectionMode
                  ? () => _toggleFieldSelection(field.id)
                  : () => _showEditFieldDialog(field),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RufkoTheme.primaryColor, width: 2),
                )
                    : null,
                  child: ListTile(
                    dense: isPhone,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 8 : 16,
                      vertical: isPhone ? 4 : 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _getFieldTypeColor(field.fieldType),
                      child: Icon(
                        _getFieldTypeIcon(field.fieldType),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  title: Text(
                    field.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? RufkoTheme.primaryColor : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Field: ${field.fieldName} • Type: ${field.fieldType}',
                        style: TextStyle(
                          color: isSelected
                              ? RufkoTheme.primaryColor.withValues(alpha: 0.7)
                              : Colors.grey[600],
                          fontSize: isPhone ? 11 : 12,
                        ),
                      ),
                      if (field.currentValue.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? RufkoTheme.primaryColor.withValues(alpha: 0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Value: ${field.currentValue}',
                            style: TextStyle(fontSize: isPhone ? 10 : 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: _isFieldSelectionMode
                      ? null
                      : PopupMenuButton<String>(
                    onSelected: (action) => _handleFieldAction(action, field),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Field'),
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
                ),
              ),
            ),
          ),

          // Selection checkbox
          if (_isFieldSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) => _toggleFieldSelection(field.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: RufkoTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isPhone) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.data_object,
            size: isPhone ? 48 : 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Custom Fields Yet',
            style: TextStyle(
              fontSize: isPhone ? 16 : 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create custom fields to use in your PDF templates',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddFieldDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Field'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RufkoTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<CustomAppDataField> _filterFields(List<CustomAppDataField> fields) {
    var filtered = fields;

    if (_selectedCategory != 'all') {
      filtered = filtered.where((f) => f.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((f) =>
      f.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.fieldName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Map<String, List<CustomAppDataField>> _groupFieldsByCategory(
      List<CustomAppDataField> fields) {
    final grouped = <String, List<CustomAppDataField>>{};
    for (final field in fields) {
      grouped.putIfAbsent(field.category, () => []).add(field);
    }
    return grouped;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all': return Icons.view_list;
      case 'company': return Icons.business;
      case 'contact': return Icons.contact_phone;
      case 'legal': return Icons.gavel;
      case 'pricing': return Icons.attach_money;
      case 'custom': return Icons.extension;
      case 'inspection': return Icons.checklist;
      default: return Icons.folder;
    }
  }

  Color _getFieldTypeColor(String fieldType) {
    switch (fieldType) {
      case 'text': return Colors.blue;
      case 'number': return Colors.green;
      case 'email': return Colors.orange;
      case 'phone': return Colors.purple;
      case 'multiline': return Colors.teal;
      case 'date': return Colors.red;
      case 'currency': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getFieldTypeIcon(String fieldType) {
    switch (fieldType) {
      case 'text': return Icons.text_fields;
      case 'number': return Icons.numbers;
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'multiline': return Icons.notes;
      case 'date': return Icons.calendar_today;
      case 'currency': return Icons.attach_money;
      default: return Icons.input;
    }
  }

  void _handleFieldAction(String action, CustomAppDataField field) {
    switch (action) {
      case 'edit':
        _showEditFieldDialog(field);
        break;
      case 'delete':
        _deleteField(field);
        break;
    }
  }

  void _showAddFieldDialog() {
    if (!mounted) return;

    // 🚀 FIXED: Use async data source for consistency
    showDialog<CustomAppDataField?>(
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

            // Build available categories and names
            final availableCategories = <String>['custom'];
            final categoryNames = <String, String>{'custom': 'Custom Fields'};

            for (final category in customFieldCategories) {
              final categoryKey = category['key'] as String;
              final categoryName = category['name'] as String;
              if (!availableCategories.contains(categoryKey)) {
                availableCategories.add(categoryKey);
                categoryNames[categoryKey] = categoryName;
              }
            }

            return AddCustomFieldDialog(
              categories: availableCategories,
              categoryNames: categoryNames,
            );
          },
        );
      },
    ).then((returnedValue) {
      if (returnedValue != null && mounted) {
        final appState = context.read<AppStateProvider>();
        appState.addCustomAppDataField(returnedValue).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding field: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Cancel any pending operations
    super.dispose();
  }


  void _showEditFieldDialog(CustomAppDataField field) {
    if (!mounted) return;

    // 🚀 FIXED: Use async data source for consistency
    showDialog<CustomAppDataField?>(
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

            // Build available categories including current field's category
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

            // Add defaults if missing
            final defaults = ['custom', 'inspection', 'company', 'contact', 'legal', 'pricing'];
            for (final defaultCat in defaults) {
              if (!availableCategories.contains(defaultCat)) {
                availableCategories.add(defaultCat);
                categoryNames[defaultCat] = defaultCat == 'inspection'
                    ? 'Inspection Fields'
                    : formatCategoryName(defaultCat);
              }
            }

            return EditCustomFieldDialog(
              field: field,
              categories: availableCategories,
              categoryNames: categoryNames,
            );
          },
        );
      },
    ).then((updatedField) async {
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
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _deleteField(CustomAppDataField field) {
    // Store context reference before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Custom Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this field?'),
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
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        try {
          final appState = context.read<AppStateProvider>();
          await appState.deleteCustomAppDataField(field.id);

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
    });
  }
}