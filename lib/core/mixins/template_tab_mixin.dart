import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/state/app_state_provider.dart';

mixin TemplateTabMixin<T extends StatefulWidget> on State<T> {
  // Selection state
  bool _isSelectionMode = false;
  Set<String> _selectedIds = <String>{};

  // Search/filter state
  String _searchQuery = '';
  String _selectedCategory = 'all'; // Back to 'all' as default

  // Abstract methods each tab must implement
  Color get primaryColor;
  String get itemTypeName;        // 'template', 'field'
  String get itemTypePlural;      // 'templates', 'fields'
  IconData get tabIcon;
  String get searchHintText;      // 'Search message templates...'
  String get categoryType;        // 'message_templates', 'email_templates', 'custom_fields'

  // Data methods
  List<dynamic> getAllItems();
  List<dynamic> getFilteredItems();
  Future<void> deleteItemById(String id);
  String getItemId(dynamic item);
  String getItemDisplayName(dynamic item);

  // Navigation/UI methods
  void navigateToEditor([dynamic existingItem]);
  Widget buildItemTile(dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall);

  // Getters for state access
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => _selectedIds;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Responsive UI helpers
  bool isSmallScreen(BoxConstraints constraints) => constraints.maxWidth < 600;
  bool isVerySmall(BoxConstraints constraints) => constraints.maxWidth < 400;

  // Selection methods
  void enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
    });
  }

  void exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void toggleSelection(String itemId) {
    setState(() {
      if (_selectedIds.contains(itemId)) {
        _selectedIds.remove(itemId);
      } else {
        _selectedIds.add(itemId);
      }
    });
  }

  void selectAllItems() {
    final filtered = getFilteredItems();
    setState(() {
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds = filtered.map((item) => getItemId(item)).toSet();
      }
    });
  }

  // Filter methods
  void updateSearchQuery(String query) {
    setState(() => _searchQuery = query);
  }

  void updateSelectedCategory(String category) {
    setState(() => _selectedCategory = category);
  }

  // Delete functionality
  void deleteSelectedItems() {
    if (_selectedIds.isEmpty) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} $itemTypeName${_selectedIds.length == 1 ? '' : 's'}'),
        content: Text(
            _selectedIds.length == 1
                ? 'Are you sure you want to delete this $itemTypeName?'
                : 'Are you sure you want to delete these ${_selectedIds.length} $itemTypePlural?'
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                for (final itemId in _selectedIds) {
                  await deleteItemById(itemId);
                }

                exitSelectionMode();
                navigator.pop();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Deleted ${_selectedIds.length} $itemTypeName${_selectedIds.length == 1 ? '' : 's'}'),
                      backgroundColor: primaryColor,
                    ),
                  );
                }
              } catch (e) {
                navigator.pop();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting $itemTypePlural: $e'),
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

  // UI Builders
  Widget buildSelectButton(bool isVerySmall) {
    return SizedBox(
      width: isVerySmall ? 32 : 36,
      height: isVerySmall ? 32 : 36,
      child: Material(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => enterSelectionMode(),
          child: Icon(
            Icons.checklist,
            size: isVerySmall ? 18 : 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildSelectionActions(bool isVerySmall) {
    final filteredItems = getFilteredItems();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Select all/none - with text and original icon
        Container(
          margin: const EdgeInsets.only(right: 8),
          height: isVerySmall ? 32 : 36,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: selectAllItems,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_box_outline_blank,
                      size: isVerySmall ? 14 : 16,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: isVerySmall ? 4 : 6),
                    Text(
                      _selectedIds.length == filteredItems.length ? 'None' : 'All',
                      style: TextStyle(
                        fontSize: isVerySmall ? 11 : 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Delete selected - icon only
        if (_selectedIds.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: isVerySmall ? 32 : 36,
            height: isVerySmall ? 32 : 36,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: deleteSelectedItems,
                child: Icon(
                  Icons.delete_outline,
                  size: isVerySmall ? 18 : 20,
                  color: Colors.red[600],
                ),
              ),
            ),
          ),

        // Cancel selection mode - icon only
        SizedBox(
          width: isVerySmall ? 32 : 36,
          height: isVerySmall ? 32 : 36,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: exitSelectionMode,
              child: Icon(
                Icons.close,
                size: isVerySmall ? 18 : 20,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSelectionInfo(bool isVerySmall) {
    final filteredItems = getFilteredItems();

    // Get proper color shades instead of transparent overlays
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (primaryColor == Colors.green) {
      backgroundColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
      textColor = Colors.green.shade800;
    } else if (primaryColor == Colors.orange) {
      backgroundColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade700;
      textColor = Colors.orange.shade800;
    } else {
      // For RufkoTheme.primaryColor (blue) and others
      backgroundColor = Colors.blue.shade50;
      iconColor = Colors.blue.shade700;
      textColor = Colors.blue.shade800;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 12),
      child: Card(
        color: backgroundColor,
        child: Padding(
          padding: EdgeInsets.all(isVerySmall ? 8 : 10),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: iconColor, size: isVerySmall ? 16 : 18),
              SizedBox(width: isVerySmall ? 6 : 8),
              Expanded(
                child: Text(
                  _selectedIds.isEmpty
                      ? 'Tap $itemTypePlural to select'
                      : '${_selectedIds.length}/${filteredItems.length} selected',
                  style: TextStyle(
                    color: textColor,
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

  // FIXED: Brought back "All Categories" option
  Widget buildSearchAndFilterBar(bool isVerySmall) {
    return Container(
      padding: EdgeInsets.all(isVerySmall ? 8 : 12),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: searchHintText,
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
            onChanged: updateSearchQuery,
          ),
          SizedBox(height: isVerySmall ? 8 : 12),

          // Filter Chips and Actions
          Row(
            children: [
              // Filter chips - RESTORED ALL CATEGORIES OPTION
              Expanded(
                child: SizedBox(
                  height: isVerySmall ? 32 : 36,
                  child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                    future: context.read<AppStateProvider>().getAllTemplateCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }
                      final cats = snapshot.data![categoryType] ?? [];

                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // NORMAL MODE: Show all chips INCLUDING "All Categories"
                          if (!_isSelectionMode) ...[
                            Container(
                              margin: const EdgeInsets.only(left: 8, right: 8),
                              child: buildFilterChip('All Categories', Icons.view_list, 'all', isVerySmall),
                            ),
                            ...cats.map((c) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: buildFilterChip(
                                  c['name'] as String,
                                  tabIcon,
                                  c['key'] as String,
                                  isVerySmall
                              ),
                            )),
                          ]
                          // SELECTION MODE: Show only the currently active filter chip
                          else ...[
                            Container(
                              margin: const EdgeInsets.only(left: 8, right: 8),
                              child: _selectedCategory == 'all'
                                  ? buildFilterChip('All Categories', Icons.view_list, 'all', isVerySmall)
                                  : buildFilterChip(
                                  _getCategoryNameByKey(cats, _selectedCategory),
                                  tabIcon,
                                  _selectedCategory,
                                  isVerySmall
                              ),
                            ),
                          ]
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Action buttons
              if (!_isSelectionMode)
                buildSelectButton(isVerySmall)
              else
                buildSelectionActions(isVerySmall),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get category name by key
  String _getCategoryNameByKey(List<Map<String, dynamic>> categories, String key) {
    try {
      final category = categories.firstWhere(
              (c) => c['key'] == key,
          orElse: () => {'name': key.capitalize(), 'key': key}
      );
      return category['name'] as String;
    } catch (e) {
      return key.capitalize();
    }
  }

  Widget buildFilterChip(String label, IconData icon, String key, bool isVerySmall) {
    final selected = _selectedCategory == key;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : Colors.grey[700],
        ),
        overflow: TextOverflow.visible,
        maxLines: 1,
        softWrap: false,
      ),
      selected: selected,
      selectedColor: primaryColor,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (selected) {
        updateSelectedCategory(selected ? key : 'all');
      },
    );
  }

  Widget buildEmptyState(bool isSmallScreen, bool isVerySmall, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVerySmall ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tabIcon,
              size: isVerySmall ? 40 : 56,
              color: Colors.grey[400],
            ),
            SizedBox(height: isVerySmall ? 12 : 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isVerySmall ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isVerySmall ? 6 : 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: isVerySmall ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMainLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = isSmallScreen(constraints);
        final bool isVerySmall = this.isVerySmall(constraints);

        final filteredItems = getFilteredItems();

        return Column(
          children: [
            // Search and Filter Bar
            buildSearchAndFilterBar(isVerySmall),

            // Selection mode info
            if (_isSelectionMode)
              buildSelectionInfo(isVerySmall),

            // Content or empty state
            Expanded(
              child: filteredItems.isEmpty
                  ? buildEmptyState(isSmall, isVerySmall, 'No ${itemTypePlural.capitalize()}', 'Create your first $itemTypeName to get started')
                  : buildItemsList(filteredItems, isSmall, isVerySmall),
            ),
          ],
        );
      },
    );
  }

  Widget buildItemsList(List<dynamic> items, bool isSmallScreen, bool isVerySmall) {
    return ListView.builder(
      padding: EdgeInsets.all(isVerySmall ? 8 : 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIds.contains(getItemId(item));
        return buildItemTile(item, isSelected, isSmallScreen, isVerySmall);
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}