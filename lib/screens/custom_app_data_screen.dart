// lib/screens/custom_app_data_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_app_data.dart';
import '../providers/app_state_provider.dart';
import '../widgets/add_custom_field_dialog.dart';
import '../widgets/edit_custom_field_dialog.dart';

class CustomAppDataScreen extends StatefulWidget {
  const CustomAppDataScreen({super.key});

  @override
  State<CustomAppDataScreen> createState() => _CustomAppDataScreenState();
}

class _CustomAppDataScreenState extends State<CustomAppDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final TextEditingController _newCategoryController = TextEditingController();

  bool _isFieldSelectionMode = false;
  Set<String> _selectedFieldIds = <String>{};

  final List<String> _categories = [
    'all',
    'company',
    'contact',
    'legal',
    'pricing',
    'custom'
  ];

  final Map<String, String> _categoryNames = {
    'all': 'All Fields',
    'company': 'Company Info',
    'contact': 'Contact Info',
    'legal': 'Legal Info',
    'pricing': 'Pricing',
    'custom': 'Custom Fields',
  };

  final Map<String, IconData> _categoryIcons = {
    'all': Icons.view_list,
    'company': Icons.business,
    'contact': Icons.contact_phone,
    'legal': Icons.gavel,
    'pricing': Icons.attach_money,
    'custom': Icons.extension,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newCategoryController.dispose(); // ADD THIS LINE
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're embedded in Templates screen (no Scaffold needed)
    final bool isEmbedded = ModalRoute.of(context)?.settings.name != '/custom_app_data';

    if (isEmbedded) {
      // Return just the content without Scaffold/AppBar when embedded
      return _buildManageFieldsTab();
    }

    // Full screen version with AppBar and tabs (when accessed directly)
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Custom App Data'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Manage Fields'),
            Tab(icon: Icon(Icons.category), text: 'Manage Categories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFieldDialog,
            tooltip: 'Add New Field',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManageFieldsTab(),
          _buildManageCategoriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFieldDialog,
        backgroundColor: const Color(0xFF2E86AB),
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
            onPressed: () => Navigator.pop(context),
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
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${_selectedFieldIds.length} field${_selectedFieldIds.length == 1 ? '' : 's'}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting fields: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildManageFieldsTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final allFields = appState.customAppDataFields;
        final filteredFields = _filterFields(allFields);
        final groupedFields = _groupFieldsByCategory(filteredFields);

        return Column(
          children: [
            // Search and Filter Bar (ALWAYS SHOWN)
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
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Category Filter Chips + Actions
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _categoryIcons[category],
                                        size: 16,
                                        color: isSelected ? Colors.white : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(_categoryNames[category] ?? category),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? category : 'all';
                                    });
                                  },
                                  selectedColor: const Color(0xFF2E86AB),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Select Button
                      if (!_isFieldSelectionMode)
                        ElevatedButton.icon(
                          onPressed: _enterFieldSelectionMode,
                          icon: const Icon(Icons.checklist, size: 18),
                          label: const Text('Select'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E86AB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        )
                      else
                        Row(
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
                        ElevatedButton.icon(
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
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedFields.length,
                itemBuilder: (context, index) {
                  final category = groupedFields.keys.elementAt(index);
                  final categoryFields = groupedFields[category]!;

                  return _buildCategorySection(category, categoryFields);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(String category, List<CustomAppDataField> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E86AB).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _categoryIcons[category] ?? Icons.folder,
                  color: const Color(0xFF2E86AB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _categoryNames[category] ?? category.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E86AB),
                  ),
                ),
                const Spacer(),
                Text(
                  '${fields.length} fields',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Fields List
          ...fields.map((field) => _buildFieldTile(field)),
        ],
      ),
    );
  }

  Widget _buildFieldTile(CustomAppDataField field) {
    final isSelected = _selectedFieldIds.contains(field.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 3 : 1,
            color: isSelected ? const Color(0xFF2E86AB).withOpacity(0.1) : null,
            child: InkWell(
              onTap: _isFieldSelectionMode
                  ? () => _toggleFieldSelection(field.id)
                  : () => _showEditFieldDialog(field),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E86AB), width: 2),
                )
                    : null,
                child: ListTile(
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
                      color: isSelected ? const Color(0xFF2E86AB) : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Field: ${field.fieldName} • Type: ${field.fieldType}',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2E86AB).withOpacity(0.7)
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (field.currentValue.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2E86AB).withOpacity(0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Value: ${field.currentValue}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
                      color: Colors.black.withOpacity(0.2),
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
                  activeColor: const Color(0xFF2E86AB),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildManageCategoriesTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final currentCategories = List<String>.from(_categories.where((c) => c != 'all'));

        return Column(
          children: [
            // Header with add new category
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, color: const Color(0xFF2E86AB)),
                      const SizedBox(width: 8),
                      Text(
                        'Custom Field Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organize your custom fields into categories. You can add, edit, or remove categories as needed.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Add new category section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E86AB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2E86AB).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newCategoryController,
                            decoration: InputDecoration(
                              labelText: 'New Category Name',
                              hintText: 'e.g., Project Details',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.add, color: const Color(0xFF2E86AB)),
                            ),
                            onSubmitted: (_) => _addNewCategory(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addNewCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E86AB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Categories list
            Expanded(
              child: currentCategories.isEmpty
                  ? _buildEmptyCategoriesState()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentCategories.length,
                itemBuilder: (context, index) {
                  final category = currentCategories[index];
                  final fieldsInCategory = appState.customAppDataFields
                      .where((f) => f.category == category)
                      .length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(category),
                        child: Icon(
                          _categoryIcons[category] ?? Icons.folder,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _categoryNames[category] ?? category,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '$fieldsInCategory field${fieldsInCategory != 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: const Color(0xFF2E86AB)),
                            onPressed: () => _editCategory(category, index),
                            tooltip: 'Edit category',
                          ),
                          if (fieldsInCategory == 0)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                              onPressed: () => _deleteCategory(category, index),
                              tooltip: 'Delete category',
                            ),
                        ],
                      ),
                      onTap: () => _editCategory(category, index),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCategoriesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Custom Categories Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first category to organize custom fields',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'company': return Colors.indigo;
      case 'contact': return Colors.green;
      case 'legal': return Colors.orange;
      case 'pricing': return Colors.purple;
      case 'custom': return Colors.teal;
      default: return const Color(0xFF2E86AB);
    }
  }




  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.data_object,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Custom Fields Yet',
            style: TextStyle(
              fontSize: 18,
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
              backgroundColor: const Color(0xFF2E86AB),
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

  void _updateFieldValue(CustomAppDataField field, String value) {
    final appState = context.read<AppStateProvider>();
    appState.updateCustomAppDataField(field.id, value);
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

  // lib/screens/custom_app_data_screen.dart
// ... (inside _CustomAppDataScreenState class) ...

  void _showAddFieldDialog() {
    print('Show add field dialog - SIMPLIFIED with separate widget');

    showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AddCustomFieldDialog(
          categories: _categories,
          categoryNames: _categoryNames,
        );
      },
    ).then((returnedValue) {
      if (returnedValue != null) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        appState.addCustomAppDataField(returnedValue);

        // Manually trigger UI update if notifyListeners is commented out in provider
        if (mounted) {
          Provider.of<AppStateProvider>(context, listen: false).notifyListeners();
          print("Manually triggered notifyListeners from _showAddFieldDialog.then AFTER adding to provider");
        }
      }
    });
  }

  void _showEditFieldDialog(CustomAppDataField field) {
    print('Show edit field dialog for: ${field.fieldName}');

    showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return EditCustomFieldDialog(
          field: field,
          categories: _categories,
          categoryNames: _categoryNames,
        );
      },
    ).then((updatedField) async {
      if (updatedField != null) {
        try {
          final appState = Provider.of<AppStateProvider>(context, listen: false);
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
    });
  }



  void _deleteField(CustomAppDataField field) {
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field: ${field.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${field.fieldName}'),
                    Text('Category: ${_categoryNames[field.category] ?? field.category}'),
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
      if (confirmed == true) {
        try {
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          await appState.deleteCustomAppDataField(field.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted field: ${field.displayName}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
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

  // Category Management Methods
  void _addNewCategory() {
    final newCategoryName = _newCategoryController.text.trim();
    if (newCategoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create category key (lowercase, no spaces)
    final categoryKey = newCategoryName.toLowerCase().replaceAll(' ', '_');

    // Check if category already exists
    if (_categories.contains(categoryKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _categories.add(categoryKey);
      _categoryNames[categoryKey] = newCategoryName;
      _newCategoryController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added category: $newCategoryName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editCategory(String category, int index) {
    final TextEditingController editController = TextEditingController(
        text: _categoryNames[category] ?? category
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E86AB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: const Color(0xFF2E86AB)),
            ),
            const SizedBox(width: 12),
            const Text('Edit Category'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                prefixIcon: Icon(Icons.category, color: const Color(0xFF2E86AB)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF2E86AB), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _updateCategoryName(category, value.trim(), editController);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E86AB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E86AB).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF2E86AB), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Existing fields with this category will be updated automatically.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              editController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                _updateCategoryName(category, newName, editController);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _updateCategoryName(String category, String newName, TextEditingController controller) {
    if (newName == (_categoryNames[category] ?? category)) {
      // No change
      controller.dispose();
      Navigator.pop(context);
      return;
    }

    setState(() {
      _categoryNames[category] = newName;
    });

    controller.dispose();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category updated to "$newName"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteCategory(String category, int index) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final fieldsInCategory = appState.customAppDataFields
        .where((f) => f.category == category)
        .length;

    if (fieldsInCategory > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete category with $fieldsInCategory field${fieldsInCategory != 1 ? 's' : ''}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Delete Category'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_categoryNames[category] ?? category}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _categories.remove(category);
                _categoryNames.remove(category);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted category: ${_categoryNames[category] ?? category}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


}