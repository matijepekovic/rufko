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
        final bool isSmallScreen = constraints.maxWidth < 600;
        final bool isVerySmall = constraints.maxWidth < 400;

        return Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            final allFields = appState.customAppDataFields;
            final filteredFields = _filterFields(allFields);
            final groupedFields = _groupFieldsByCategory(filteredFields);

            return Column(
              children: [
                // Compact Search and Filter Bar
                Container(
                  padding: EdgeInsets.all(isVerySmall ? 8 : 12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Compact Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search fields...',
                          hintStyle: TextStyle(fontSize: isVerySmall ? 14 : 16),
                          prefixIcon: Icon(Icons.search, size: isVerySmall ? 18 : 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: isVerySmall ? 8 : 12,
                              vertical: isVerySmall ? 6 : 8
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: isVerySmall ? 14 : 16),
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _searchQuery = value);
                          }
                        },
                      ),
                      SizedBox(height: isVerySmall ? 8 : 12),

                      // SIMPLE HORIZONTAL SCROLLING - THIS WILL WORK
                      Row(
                        children: [
                          // Horizontal scrolling filter
                          Expanded(
                            child: Container(
                              height: isVerySmall ? 32 : 36,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _buildFilterChips(appState).length,
                                itemBuilder: (context, index) {
                                  final chip = _buildFilterChips(appState)[index];
                                  final isSelected = _selectedCategory == chip['key'];

                                  return Container(
                                    margin: EdgeInsets.only(
                                      left: index == 0 ? 8 : 0,
                                      right: 8,
                                    ),
                                    child: FilterChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            chip['icon'] as IconData,
                                            size: 14,
                                            color: isSelected ? Colors.white : Colors.grey[600],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            chip['name'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected ? Colors.white : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      selected: isSelected,
                                      selectedColor: RufkoTheme.primaryColor,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = selected ? (chip['key'] as String) : 'all';
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Action buttons
                          if (!_isFieldSelectionMode)
                            _buildSelectButton(isVerySmall)
                          else
                            _buildSelectionActions(filteredFields, isVerySmall),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection mode info - more compact for mobile
                if (_isFieldSelectionMode)
                  _buildSelectionInfo(filteredFields, isVerySmall),

                // Fields content or empty state
                Expanded(
                  child: filteredFields.isEmpty
                      ? _buildEmptyState(isSmallScreen, isVerySmall)
                      : _buildFieldsList(groupedFields, isSmallScreen, isVerySmall),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // REMOVED - using simple inline approach above

  // REMOVED - using inline chip building above

  Widget _buildSelectButton(bool isVerySmall) {
    return SizedBox(
      height: isVerySmall ? 32 : 36,
      width: isVerySmall ? 32 : 36,
      child: IconButton(
        onPressed: _enterFieldSelectionMode,
        icon: Icon(Icons.checklist, size: isVerySmall ? 16 : 18),
        padding: EdgeInsets.all(isVerySmall ? 6 : 8),
        style: IconButton.styleFrom(
          backgroundColor: RufkoTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSelectionActions(List<CustomAppDataField> filteredFields, bool isVerySmall) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Select all/none
        SizedBox(
          height: isVerySmall ? 32 : 36,
          width: isVerySmall ? 32 : 36,
          child: IconButton(
            onPressed: _selectAllFields,
            icon: Icon(
              _selectedFieldIds.length == filteredFields.length
                  ? Icons.deselect
                  : Icons.select_all,
              size: isVerySmall ? 16 : 18,
            ),
            padding: EdgeInsets.all(isVerySmall ? 6 : 8),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
            ),
          ),
        ),

        SizedBox(width: isVerySmall ? 4 : 6),

        // Delete selected
        if (_selectedFieldIds.isNotEmpty)
          SizedBox(
            height: isVerySmall ? 32 : 36,
            width: isVerySmall ? 32 : 36,
            child: IconButton(
              onPressed: _deleteSelectedFields,
              icon: Icon(Icons.delete, size: isVerySmall ? 16 : 18),
              padding: EdgeInsets.all(isVerySmall ? 6 : 8),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
              ),
            ),
          ),

        if (_selectedFieldIds.isNotEmpty) SizedBox(width: isVerySmall ? 4 : 6),

        // Cancel
        SizedBox(
          height: isVerySmall ? 32 : 36,
          width: isVerySmall ? 32 : 36,
          child: IconButton(
            onPressed: _exitFieldSelectionMode,
            icon: Icon(Icons.close, size: isVerySmall ? 16 : 18),
            padding: EdgeInsets.all(isVerySmall ? 6 : 8),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionInfo(List<CustomAppDataField> filteredFields, bool isVerySmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 12),
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(isVerySmall ? 8 : 10),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: isVerySmall ? 16 : 18),
              SizedBox(width: isVerySmall ? 6 : 8),
              Expanded(
                child: Text(
                  _selectedFieldIds.isEmpty
                      ? 'Tap fields to select'
                      : '${_selectedFieldIds.length}/${filteredFields.length} selected',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                    fontSize: isVerySmall ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsList(Map<String, List<CustomAppDataField>> groupedFields, bool isSmallScreen, bool isVerySmall) {
    return ListView.builder(
      padding: EdgeInsets.all(isVerySmall ? 8 : 12),
      itemCount: groupedFields.length,
      itemBuilder: (context, index) {
        final category = groupedFields.keys.elementAt(index);
        final categoryFields = groupedFields[category]!;

        return _buildCategorySection(category, categoryFields, isSmallScreen, isVerySmall);
      },
    );
  }

  Widget _buildCategorySection(String category, List<CustomAppDataField> fields, bool isSmallScreen, bool isVerySmall) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: context.read<AppStateProvider>().getAllTemplateCategories(),
      builder: (context, snapshot) {
        String categoryDisplayName = formatCategoryName(category);

        if (snapshot.hasData) {
          final allCategories = snapshot.data!;
          final customFieldCategories = allCategories['custom_fields'] ?? [];

          for (final cat in customFieldCategories) {
            if (cat['key'] == category) {
              categoryDisplayName = cat['name'] as String;
              break;
            }
          }
        }

        return Card(
          margin: EdgeInsets.only(bottom: isVerySmall ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Category Header
              Container(
                padding: EdgeInsets.all(isVerySmall ? 8 : 12),
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
                      size: isVerySmall ? 16 : 18,
                    ),
                    SizedBox(width: isVerySmall ? 6 : 8),
                    Expanded(
                      child: Text(
                        categoryDisplayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: RufkoTheme.primaryColor,
                          fontSize: isVerySmall ? 13 : 15,
                        ),
                      ),
                    ),
                    Text(
                      '${fields.length}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isVerySmall ? 10 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Compact Fields List
              ...fields.map((field) => _buildCompactFieldTile(field, isSmallScreen, isVerySmall)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactFieldTile(CustomAppDataField field, bool isSmallScreen, bool isVerySmall) {
    final isSelected = _selectedFieldIds.contains(field.id);

    return InkWell(
      onTap: _isFieldSelectionMode
          ? () => _toggleFieldSelection(field.id)
          : () => _showEditFieldDialog(field),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmall ? 8 : 12,
          vertical: isVerySmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? RufkoTheme.primaryColor.withValues(alpha: 0.1) : null,
          border: isSelected
              ? Border.all(color: RufkoTheme.primaryColor, width: 1)
              : const Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
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
                      color: isSelected ? RufkoTheme.primaryColor : null,
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
                                ? RufkoTheme.primaryColor.withValues(alpha: 0.7)
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
                          vertical: isVerySmall ? 1 : 2
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? RufkoTheme.primaryColor.withValues(alpha: 0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        field.currentValue,
                        style: TextStyle(
                            fontSize: isVerySmall ? 9 : 10,
                            fontWeight: FontWeight.w500
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator or menu
            if (_isFieldSelectionMode)
              Container(
                width: isVerySmall ? 20 : 24,
                height: isVerySmall ? 20 : 24,
                decoration: BoxDecoration(
                  color: isSelected ? RufkoTheme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? RufkoTheme.primaryColor : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: isVerySmall ? 12 : 14)
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

  Widget _buildEmptyState(bool isSmallScreen, bool isVerySmall) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVerySmall ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_object,
              size: isVerySmall ? 40 : 56,
              color: Colors.grey[400],
            ),
            SizedBox(height: isVerySmall ? 12 : 16),
            Text(
              'No Custom Fields',
              style: TextStyle(
                fontSize: isVerySmall ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isVerySmall ? 6 : 8),
            Text(
              'Create fields for your PDF templates',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: isVerySmall ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isVerySmall ? 16 : 24),
            ElevatedButton.icon(
              onPressed: _showAddFieldDialog,
              icon: Icon(Icons.add, size: isVerySmall ? 16 : 18),
              label: Text(
                'Add Field',
                style: TextStyle(fontSize: isVerySmall ? 13 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RufkoTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmall ? 16 : 20,
                  vertical: isVerySmall ? 8 : 12,
                ),
              ),
            ),
          ],
        ),
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

  Map<String, List<CustomAppDataField>> _groupFieldsByCategory(List<CustomAppDataField> fields) {
    final grouped = <String, List<CustomAppDataField>>{};
    for (final field in fields) {
      grouped.putIfAbsent(field.category, () => []).add(field);
    }
    return grouped;
  }

  List<Map<String, dynamic>> _buildFilterChips(AppStateProvider appState) {
    final chips = <Map<String, dynamic>>[{
      'key': 'all',
      'name': 'All Fields',
      'icon': Icons.view_list
    }];

    final categories = appState.templateCategories
        .where((c) => c.templateType == 'custom_fields')
        .toList();
    for (final cat in categories) {
      chips.add({'key': cat.key, 'name': cat.name, 'icon': Icons.extension});
    }

    const defaults = [
      {'key': 'inspection', 'name': 'Inspection Fields', 'icon': Icons.checklist},
      {'key': 'company', 'name': 'Company Info', 'icon': Icons.business},
      {'key': 'contact', 'name': 'Contact Info', 'icon': Icons.contact_phone},
      {'key': 'legal', 'name': 'Legal', 'icon': Icons.gavel},
      {'key': 'pricing', 'name': 'Pricing', 'icon': Icons.attach_money},
      {'key': 'custom', 'name': 'Custom Fields', 'icon': Icons.extension},
    ];

    for (final d in defaults) {
      if (!chips.any((c) => c['key'] == d['key'])) {
        chips.add(d);
      }
    }

    return chips;
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

  void _showEditFieldDialog(CustomAppDataField field) {
    if (!mounted) return;
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

  @override
  void dispose() {
    // Cancel any pending operations
    super.dispose();
  }
}