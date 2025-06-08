// lib/screens/templates_screen.dart - CUSTOMER DETAIL STYLE DESIGN

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message_template.dart';
import '../models/pdf_template.dart';
import '../providers/app_state_provider.dart';
import '../services/template_service.dart';
import 'template_editor_screen.dart';
import 'pdf_preview_screen.dart';
import 'custom_app_data_screen.dart';
import '../theme/rufko_theme.dart';
import 'message_template_editor_screen.dart';
import 'email_template_editor_screen.dart';
import '../models/email_template.dart';
import 'category_management_screen.dart';
import '../models/custom_app_data.dart';
import '../widgets/add_custom_field_dialog.dart';


class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter state variables
  String _selectedPDFCategoryKey = 'all'; // <<< RENAMED
  String _selectedMessageCategoryKey = 'all'; // <<< RENAMED
  String _selectedEmailCategoryKey = 'all'; // <<< RENAMED

  // Selection states for each tab
  bool _isPDFSelectionMode = false;
  bool _isMessageSelectionMode = false;
  bool _isEmailSelectionMode = false;
  Set<String> _selectedPDFIds = <String>{};
  Set<String> _selectedMessageIds = <String>{};
  Set<String> _selectedEmailIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen for tab changes to exit selection modes
    _tabController.addListener(() {
      if (_isPDFSelectionMode && _tabController.index != 0) {
        _exitPDFSelectionMode();
      }
      if (_isMessageSelectionMode && _tabController.index != 1) {
        _exitMessageSelectionMode();
      }
      if (_isEmailSelectionMode && _tabController.index != 2) {
        _exitEmailSelectionMode();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // PDF Selection Mode Methods
  void _enterPDFSelectionMode() {
    setState(() {
      _isPDFSelectionMode = true;
      _selectedPDFIds.clear();
    });
  }

  void _exitPDFSelectionMode() {
    setState(() {
      _isPDFSelectionMode = false;
      _selectedPDFIds.clear();
    });
  }

  void _togglePDFSelection(String templateId) {
    setState(() {
      if (_selectedPDFIds.contains(templateId)) {
        _selectedPDFIds.remove(templateId);
      } else {
        _selectedPDFIds.add(templateId);
      }
    });
  }

  void _selectAllPDF() {
    final appState = context.read<AppStateProvider>();
    final templates = _filterPDFTemplates(appState.pdfTemplates);

    setState(() {
      if (_selectedPDFIds.length == templates.length) {
        _selectedPDFIds.clear();
      } else {
        _selectedPDFIds = templates.map((t) => t.id).toSet();
      }
    });
  }

// Message Selection Mode Methods
  void _enterMessageSelectionMode() {
    setState(() {
      _isMessageSelectionMode = true;
      _selectedMessageIds.clear();
    });
  }

  void _exitMessageSelectionMode() {
    setState(() {
      _isMessageSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _selectAllMessages() {
    final categories = _getTextMessageCategories();
    final filteredCategories = _selectedMessageCategoryKey == 'all'
        ? categories
        : categories
            .where((cat) =>
                _getCategoryKey(cat['name']) == _selectedMessageCategoryKey)
            .toList();

    setState(() {
      if (_selectedMessageIds.length == filteredCategories.length) {
        _selectedMessageIds.clear();
      } else {
        _selectedMessageIds =
            filteredCategories.map((c) => c['name'].toString()).toSet();
      }
    });
  }

  void _deleteSelectedMessages() {
    if (_selectedMessageIds.isEmpty) return;
    _showErrorSnackBar(
        'Delete ${_selectedMessageIds.length} message template${_selectedMessageIds.length == 1 ? '' : 's'} - Coming soon!');
    _exitMessageSelectionMode();
  }

// Email Selection Mode Methods
  void _enterEmailSelectionMode() {
    setState(() {
      _isEmailSelectionMode = true;
      _selectedEmailIds.clear();
    });
  }

  void _exitEmailSelectionMode() {
    setState(() {
      _isEmailSelectionMode = false;
      _selectedEmailIds.clear();
    });
  }

  void _selectAllEmails() {
    final categories = _getEmailCategories();
    final filteredCategories = _selectedEmailCategoryKey == 'all'
        ? categories
        : categories
            .where((cat) =>
                _getCategoryKey(cat['name']) == _selectedEmailCategoryKey)
            .toList();

    setState(() {
      if (_selectedEmailIds.length == filteredCategories.length) {
        _selectedEmailIds.clear();
      } else {
        _selectedEmailIds =
            filteredCategories.map((c) => c['name'].toString()).toSet();
      }
    });
  }

  void _deleteSelectedEmails() {
    if (_selectedEmailIds.isEmpty) return;
    _showErrorSnackBar(
        'Delete ${_selectedEmailIds.length} email template${_selectedEmailIds.length == 1 ? '' : 's'} - Coming soon!');
    _exitEmailSelectionMode();
  }

  void _deleteSelectedPDF() {
    if (_selectedPDFIds.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Delete ${_selectedPDFIds.length} template${_selectedPDFIds.length == 1 ? '' : 's'}'),
        content: Text(_selectedPDFIds.length == 1
            ? 'Are you sure you want to delete this PDF template?'
            : 'Are you sure you want to delete these ${_selectedPDFIds.length} PDF templates?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final appState = context.read<AppStateProvider>();

                for (final templateId in _selectedPDFIds) {
                  await appState.deletePDFTemplate(templateId);
                }

                _exitPDFSelectionMode();

                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        'Deleted ${_selectedPDFIds.length} template${_selectedPDFIds.length == 1 ? '' : 's'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                navigator.pop();
                _showErrorSnackBar('Error deleting templates: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPDFSelectionMode &&
          !_isMessageSelectionMode &&
          !_isEmailSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isPDFSelectionMode) {
            _exitPDFSelectionMode();
          } else if (_isMessageSelectionMode) {
            _exitMessageSelectionMode();
          } else if (_isEmailSelectionMode) {
            _exitEmailSelectionMode();
          }
        }
      },
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  _buildModernSliverAppBar(appState),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPDFTemplatesTab(),
                  _buildTextTemplatesTab(),
                  _buildEmailTemplatesTab(),
                  _buildCustomDataTab(),
                ],
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(),
          );
        },
      ),
    );
  }

  Widget _buildModernSliverAppBar(AppStateProvider appState) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RufkoTheme.primaryColor,
                RufkoTheme.primaryDarkColor,
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Settings only
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showTemplateSettings,
          tooltip: 'Template Settings',
          color: Colors.white,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(
            icon: Icon(_isPDFSelectionMode && _tabController.index == 0
                ? Icons.checklist
                : Icons.picture_as_pdf),
            text: _isPDFSelectionMode && _tabController.index == 0
                ? '${_selectedPDFIds.length} selected'
                : 'PDF Templates',
          ),
          Tab(
            icon: Icon(_isMessageSelectionMode && _tabController.index == 1
                ? Icons.checklist
                : Icons.sms),
            text: _isMessageSelectionMode && _tabController.index == 1
                ? '${_selectedMessageIds.length} selected'
                : 'Message Templates',
          ),
          Tab(
            icon: Icon(_isEmailSelectionMode && _tabController.index == 2
                ? Icons.checklist
                : Icons.email),
            text: _isEmailSelectionMode && _tabController.index == 2
                ? '${_selectedEmailIds.length} selected'
                : 'Email Templates',
          ),
          const Tab(icon: Icon(Icons.data_object), text: 'Custom Fields'),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final currentTab = _tabController.index;

        // PDF tab with selection mode
        if (currentTab == 0 && _isPDFSelectionMode) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_selectedPDFIds.isNotEmpty)
                FloatingActionButton(
                  heroTag: "delete_selected_pdf_fab",
                  onPressed: _deleteSelectedPDF,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: "cancel_pdf_selection_fab",
                onPressed: _exitPDFSelectionMode,
                backgroundColor: Colors.grey,
                child: const Icon(Icons.close),
              ),
            ],
          );
        }

        // Regular FABs for each tab
        switch (currentTab) {
          case 0: // PDF Templates tab
            return FloatingActionButton.extended(
              heroTag: "pdf_fab",
              onPressed: _createNewPDFTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New PDF Template'),
              backgroundColor: RufkoTheme.primaryColor,
            );
          case 1: // Message Templates tab
            return FloatingActionButton.extended(
              heroTag: "message_fab",
              onPressed: _createNewTextTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New Message Template'),
              backgroundColor: Colors.green,
            );
          case 2: // Email Templates tab
            return FloatingActionButton.extended(
              heroTag: "email_fab",
              onPressed: _createNewEmailTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New Email Template'),
              backgroundColor: Colors.orange,
            );
          case 3: // Custom Fields tab
            return FloatingActionButton.extended(
              heroTag: "custom_fields_fab",
              onPressed: _createNewCustomField,
              icon: const Icon(Icons.add),
              label: const Text('New Custom Field'),
              backgroundColor: RufkoTheme.primaryColor,
            );
          default:
            return FloatingActionButton.extended(
              heroTag: "default_fab",
              onPressed: _createNewPDFTemplate,
              icon: const Icon(Icons.add),
              label: const Text('New Template'),
              backgroundColor: RufkoTheme.primaryColor,
            );
        }
      },
    );
  }

  // TAB CONTENT BUILDERS

  Widget _buildPDFTemplatesTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final templates = _filterPDFTemplates(appState.pdfTemplates);

        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group templates by user category
        final groupedTemplates = <String, List<PDFTemplate>>{};
        for (final template in templates) {
          final categoryKey = template.userCategoryKey ?? 'uncategorized';
          groupedTemplates.putIfAbsent(categoryKey, () => []).add(template);
        }

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
                      hintText: 'Search PDF templates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                          child: FutureBuilder<
                              Map<String, List<Map<String, dynamic>>>>(
                            future: appState.getAllTemplateCategories(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                    height: 40); // Placeholder while loading
                              }

                              final allCategories = snapshot.data!;
                              final pdfCategories =
                                  allCategories['pdf_templates'] ?? [];

                              return Row(
                                children: [
                                  // "All Categories" chip
                                  _buildPDFFilterChip(
                                      'All Categories',
                                      Icons.view_list,
                                      _selectedPDFCategoryKey == 'all'),
                                  // Dynamic user category chips
                                  ...pdfCategories.map((category) {
                                    final categoryKey =
                                        category['key'] as String;
                                    final categoryName =
                                        category['name'] as String;
                                    return _buildPDFFilterChip(
                                        categoryName,
                                        Icons.description,
                                        _selectedPDFCategoryKey == categoryKey,
                                        categoryKey);
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Select Button
                      if (!_isPDFSelectionMode)
                        ElevatedButton.icon(
                          onPressed: _enterPDFSelectionMode,
                          icon: const Icon(Icons.checklist, size: 18),
                          label: const Text('Select'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )
                      else
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _selectAllPDF,
                              icon: const Icon(Icons.select_all, size: 18),
                              label: Text(
                                _selectedPDFIds.length == templates.length
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _exitPDFSelectionMode,
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
            if (_isPDFSelectionMode) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedPDFIds.isEmpty
                              ? 'Tap PDF templates to select them'
                              : '${_selectedPDFIds.length} of ${templates.length} templates selected',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_selectedPDFIds.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _deleteSelectedPDF,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Templates content or empty state
            Expanded(
              child: templates.isEmpty
                  ? _buildEmptyPDFState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedTemplates.length,
                      itemBuilder: (context, index) {
                        final categoryKey =
                            groupedTemplates.keys.elementAt(index);
                        final categoryTemplates =
                            groupedTemplates[categoryKey]!;

                        return _buildPDFCategorySection(
                            categoryKey, categoryTemplates);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPDFFilterChip(String label, IconData icon, bool isSelected,
      [String? categoryKey]) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
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
            if (label == 'All Categories') {
              _selectedPDFCategoryKey = 'all';
            } else {
              _selectedPDFCategoryKey =
                  selected ? (categoryKey ?? label.toLowerCase()) : 'all';
            }
          });
        },
      ),
    );
  }

  String _getCategoryDisplayName(String categoryKey) {
    if (categoryKey == 'uncategorized') return 'Uncategorized Templates';

    // For now, just use the key - we'll improve this later
    return '$categoryKey Templates';
  }

  Widget _buildPDFCategorySection(
      String templateType, List<PDFTemplate> typeTemplates) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor(templateType).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(_getTypeIcon(templateType),
                    color: _getTypeColor(templateType), size: 20),
                const SizedBox(width: 8),
                Text(
                  _getCategoryDisplayName(templateType),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(templateType),
                  ),
                ),
                const Spacer(),
                Text(
                  '${typeTemplates.length} template${typeTemplates.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Templates in this category
          ...typeTemplates.map((template) => _isPDFSelectionMode
              ? _buildSelectablePDFCard(template)
              : _buildPDFTemplateCard(template)),
        ],
      ),
    );
  }

  Widget _buildTextTemplatesTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        // Filter templates by user categories
        final allTemplates = appState.messageTemplates;
        final filteredTemplates = _filterMessageTemplates(allTemplates);

        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group templates by user category
        final groupedTemplates = <String, List<MessageTemplate>>{};
        for (final template in filteredTemplates) {
          final categoryKey = template.userCategoryKey ?? 'uncategorized';
          groupedTemplates.putIfAbsent(categoryKey, () => []).add(template);
        }

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
                      hintText: 'Search message templates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dynamic Category Filter Chips + Actions
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: FutureBuilder<
                              Map<String, List<Map<String, dynamic>>>>(
                            future: appState.getAllTemplateCategories(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(height: 40);
                              }

                              final allCategories = snapshot.data!;
                              final messageCategories =
                                  allCategories['message_templates'] ?? [];

                              return Row(
                                children: [
                                  _buildTextFilterChip(
                                      'All Categories',
                                      Icons.view_list,
                                      _selectedMessageCategoryKey == 'all'),
                                  ...messageCategories.map((category) {
                                    final categoryKey =
                                        category['key'] as String;
                                    final categoryName =
                                        category['name'] as String;
                                    return _buildTextFilterChip(
                                        categoryName,
                                        Icons.sms,
                                        _selectedMessageCategoryKey ==
                                            categoryKey,
                                        categoryKey);
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Select Button
                      if (!_isMessageSelectionMode)
                        ElevatedButton.icon(
                          onPressed: _enterMessageSelectionMode,
                          icon: const Icon(Icons.checklist, size: 18),
                          label: const Text('Select'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )
                      else
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _selectAllMessages,
                              icon: const Icon(Icons.select_all, size: 18),
                              label: Text(
                                _selectedMessageIds.length ==
                                        filteredTemplates.length
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _exitMessageSelectionMode,
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
            if (_isMessageSelectionMode) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedMessageIds.isEmpty
                              ? 'Tap message templates to select them'
                              : '${_selectedMessageIds.length} of ${filteredTemplates.length} templates selected',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_selectedMessageIds.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _deleteSelectedMessages,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Templates content or empty state
            Expanded(
              child: filteredTemplates.isEmpty
                  ? _buildEmptyMessageState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedTemplates.length,
                      itemBuilder: (context, index) {
                        final categoryKey =
                            groupedTemplates.keys.elementAt(index);
                        final categoryTemplates =
                            groupedTemplates[categoryKey]!;

                        return _buildMessageCategorySection(
                            categoryKey, categoryTemplates);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<MessageTemplate> _filterMessageTemplates(
      List<MessageTemplate> templates) {
    var filtered = templates;

    // Filter by user category
    if (_selectedMessageCategoryKey != 'all') {
      filtered = filtered
          .where((template) =>
              template.userCategoryKey == _selectedMessageCategoryKey)
          .toList();
    }

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered
          .where((template) =>
              template.templateName.toLowerCase().contains(lowerQuery) ||
              template.description.toLowerCase().contains(lowerQuery) ||
              template.messageContent.toLowerCase().contains(lowerQuery))
          .toList();
    }

    return filtered;
  }

  Widget _buildMessageCategorySection(
      String categoryKey, List<MessageTemplate> categoryTemplates) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.sms, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getMessageCategoryDisplayName(categoryKey),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Text(
                  '${categoryTemplates.length} template${categoryTemplates.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Templates in this category
          ...categoryTemplates.map((template) => _isMessageSelectionMode
              ? _buildSelectableMessageCard(template)
              : _buildMessageTemplateCard(template)),
        ],
      ),
    );
  }

  String _getMessageCategoryDisplayName(String categoryKey) {
    if (categoryKey == 'uncategorized') return 'Uncategorized Templates';
    return '$categoryKey Templates';
  }

  Widget _buildEmptyMessageState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sms_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Message Templates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first message template to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewTextTemplate,
            icon: const Icon(Icons.add),
            label: const Text('Create Message Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFilterChip(String label, IconData icon, bool isSelected,
      [String? categoryKey]) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: Colors.green,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
        onSelected: (selected) {
          setState(() {
            if (label == 'All Categories') {
              _selectedMessageCategoryKey = 'all';
            } else {
              _selectedMessageCategoryKey =
                  selected ? (categoryKey ?? label.toLowerCase()) : 'all';
            }
          });
        },
      ),
    );
  }

  Widget _buildEmailTemplatesTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        // Filter templates by user categories
        final allTemplates = appState.emailTemplates;
        final filteredTemplates = _filterEmailTemplates(allTemplates);

        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group templates by user category
        final groupedTemplates = <String, List<EmailTemplate>>{};
        for (final template in filteredTemplates) {
          final categoryKey = template.userCategoryKey ?? 'uncategorized';
          groupedTemplates.putIfAbsent(categoryKey, () => []).add(template);
        }

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
                      hintText: 'Search email templates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dynamic Category Filter Chips + Actions
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: FutureBuilder<
                              Map<String, List<Map<String, dynamic>>>>(
                            future: appState.getAllTemplateCategories(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(height: 40);
                              }

                              final allCategories = snapshot.data!;
                              final emailCategories =
                                  allCategories['email_templates'] ?? [];

                              return Row(
                                children: [
                                  _buildEmailFilterChip(
                                      'All Categories',
                                      Icons.view_list,
                                      _selectedEmailCategoryKey == 'all'),
                                  ...emailCategories.map((category) {
                                    final categoryKey =
                                        category['key'] as String;
                                    final categoryName =
                                        category['name'] as String;
                                    return _buildEmailFilterChip(
                                        categoryName,
                                        Icons.email,
                                        _selectedEmailCategoryKey ==
                                            categoryKey,
                                        categoryKey);
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Select Button
                      if (!_isEmailSelectionMode)
                        ElevatedButton.icon(
                          onPressed: _enterEmailSelectionMode,
                          icon: const Icon(Icons.checklist, size: 18),
                          label: const Text('Select'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )
                      else
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _selectAllEmails,
                              icon: const Icon(Icons.select_all, size: 18),
                              label: Text(
                                _selectedEmailIds.length ==
                                        filteredTemplates.length
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _exitEmailSelectionMode,
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
            if (_isEmailSelectionMode) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedEmailIds.isEmpty
                              ? 'Tap email templates to select them'
                              : '${_selectedEmailIds.length} of ${filteredTemplates.length} templates selected',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_selectedEmailIds.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _deleteSelectedEmails,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Templates content or empty state
            Expanded(
              child: filteredTemplates.isEmpty
                  ? _buildEmptyEmailState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedTemplates.length,
                      itemBuilder: (context, index) {
                        final categoryKey =
                            groupedTemplates.keys.elementAt(index);
                        final categoryTemplates =
                            groupedTemplates[categoryKey]!;

                        return _buildEmailCategorySection(
                            categoryKey, categoryTemplates);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<EmailTemplate> _filterEmailTemplates(List<EmailTemplate> templates) {
    var filtered = templates;

    // Filter by user category
    if (_selectedEmailCategoryKey != 'all') {
      filtered = filtered
          .where((template) =>
              template.userCategoryKey == _selectedEmailCategoryKey)
          .toList();
    }

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered
          .where((template) =>
              template.templateName.toLowerCase().contains(lowerQuery) ||
              template.description.toLowerCase().contains(lowerQuery) ||
              template.subject.toLowerCase().contains(lowerQuery) ||
              template.emailContent.toLowerCase().contains(lowerQuery))
          .toList();
    }

    return filtered;
  }
  Widget _buildEmptyEmailState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.email_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Email Templates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first email template to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewEmailTemplate,
            icon: const Icon(Icons.add),
            label: const Text('Create Email Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmailFilterChip(String label, IconData icon, bool isSelected, [String? categoryKey]) {
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
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
        onSelected: (selected) {
          setState(() {
            if (label == 'All Categories') {
              _selectedEmailCategoryKey = 'all';
            } else {
              _selectedEmailCategoryKey = selected ? (categoryKey ?? label.toLowerCase()) : 'all';
            }
          });
        },
      ),
    );
  }



  Widget _buildCustomDataTab() {
    return const CustomAppDataScreen(); // No preview, direct content
  }

  String _getEmailCategoryDisplayName(String categoryKey) {
    if (categoryKey == 'uncategorized') return 'Uncategorized Templates';
    return '$categoryKey Templates';
  }

  Widget _buildEmailCategorySection(String categoryKey, List<EmailTemplate> categoryTemplates) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.email, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getEmailCategoryDisplayName(categoryKey),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                Text(
                  '${categoryTemplates.length} template${categoryTemplates.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Templates in this category
          ...categoryTemplates.map((template) =>
          _isEmailSelectionMode
              ? _buildSelectableEmailCard(template)
              : _buildEmailTemplateCard(template)
          ),
        ],
      ),
    );
  }

  // CARD BUILDERS

  Widget _buildSelectablePDFCard(PDFTemplate template) {
    final isSelected = _selectedPDFIds.contains(template.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 3 : 1.5,
            color: isSelected ? Colors.blue.shade50 : null,
            child: InkWell(
              onTap: _isPDFSelectionMode
                  ? () => _togglePDFSelection(template.id)
                  : () => _editPDFTemplate(template),
              onLongPress: !_isPDFSelectionMode
                  ? () => _showPDFTemplateContextMenu(template)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                      )
                    : null,
                child: _buildPDFTemplateCardContent(template, isSelected),
              ),
            ),
          ),
          if (_isPDFSelectionMode)
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
                  onChanged: (bool? value) => _togglePDFSelection(template.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPDFTemplateCard(PDFTemplate template) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editPDFTemplate(template),
        onLongPress: () => _showPDFTemplateContextMenu(template),
        borderRadius: BorderRadius.circular(12),
        child: _buildPDFTemplateCardContent(template, false),
      ),
    );
  }

  String? _getTemplateCategoryName(String? categoryKey) {
    if (categoryKey == null) return null;
    // This will be replaced with proper category lookup
    return categoryKey; // For now, just return the key
  }

  Widget _buildPDFTemplateCardContent(PDFTemplate template, bool isSelected) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: template.isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: template.isActive
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.templateName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue.shade800 : null,
                          ),
                    ),
                    if (template.description.isNotEmpty)
                      Text(
                        template.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.blue.shade600
                                  : Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: template.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  template.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Template details
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  Icons.layers,
                  'Category: ${_getTemplateCategoryName(template.userCategoryKey) ?? 'No Category'}',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.text_fields,
                  '${template.fieldMappings.length} fields',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.calendar_today,
                  dateFormat.format(template.updatedAt),
                  isSelected: isSelected,
                ),
              ),
            ],
          ),

          if (!_isPDFSelectionMode) ...[
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editPDFTemplate(template),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previewPDFTemplate(template),
                    icon: const Icon(Icons.preview, size: 18),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handlePDFTemplateAction(action, template),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            template.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(template.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // EMPTY STATES

  Widget _buildEmptyPDFState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No PDF Templates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first PDF template to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewPDFTemplate,
            icon: const Icon(Icons.add),
            label: const Text('Create PDF Template'),
          ),
        ],
      ),
    );
  }

  // HELPER METHODS

  List<PDFTemplate> _filterPDFTemplates(List<PDFTemplate> templates) {
    var filtered = templates;

    // Filter by type first
    if (_selectedPDFCategoryKey != 'all') {
      filtered = filtered
          .where(
              (template) => template.userCategoryKey == _selectedPDFCategoryKey)
          .toList();
    }

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered
          .where((template) =>
              template.templateName.toLowerCase().contains(lowerQuery) ||
              template.description.toLowerCase().contains(lowerQuery) ||
              template.templateType.toLowerCase().contains(lowerQuery))
          .toList();
    }

    return filtered;
  }

  String _getCategoryKey(String categoryName) {
    // Convert category names to consistent keys
    switch (categoryName) {
      case 'Quote Notifications':
        return 'quote_notifications';
      case 'Appointments':
        return 'appointment_reminders';
      case 'Job Updates':
        return 'job_status_updates';
      case 'Payment':
        return 'payment_reminders';
      case 'Follow-ups':
        return 'follow-ups';
      case 'Emergency':
        return 'emergency/urgent';
      case 'Quote Emails':
        return 'quote_emails';
      case 'Contracts':
        return 'contract_emails';
      case 'Invoices':
        return 'invoice_emails';
      case 'Appointment Emails':
        return 'appointment_emails';
      case 'Marketing':
        return 'marketing/newsletter';
      default:
        return categoryName.toLowerCase().replaceAll(' ', '_');
    }
  }

  Widget _buildDetailChip(IconData icon, String text,
      {bool isSelected = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: isSelected ? Colors.blue.shade600 : Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue.shade600 : Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String categoryKey) {
    // For user categories, use a consistent blue color (like the old "quote" color)
    if (categoryKey == 'uncategorized') {
      return Colors.grey;
    }

    // Use the original blue color for all user categories
    return Colors.blue;
  }

  IconData _getTypeIcon(String categoryKey) {
    // For user categories, use category icon
    if (categoryKey == 'uncategorized') {
      return Icons.folder_outlined;
    }

    // Use category icon for all user categories
    return Icons.description;
  }


  List<Map<String, dynamic>> _getTextMessageCategories() {
    return [
      {
        'name': 'Quote Notifications',
        'description': 'Notify customers about quote status',
        'icon': Icons.notifications,
        'color': Colors.blue
      },
      {
        'name': 'Appointment Reminders',
        'description': 'Remind customers of scheduled visits',
        'icon': Icons.schedule,
        'color': Colors.green
      },
      {
        'name': 'Job Status Updates',
        'description': 'Update customers on work progress',
        'icon': Icons.construction,
        'color': Colors.orange
      },
      {
        'name': 'Payment Reminders',
        'description': 'Send payment due notifications',
        'icon': Icons.payment,
        'color': Colors.red
      },
      {
        'name': 'Follow-ups',
        'description': 'Check in with customers',
        'icon': Icons.chat,
        'color': Colors.purple
      },
      {
        'name': 'Emergency/Urgent',
        'description': 'Urgent communication templates',
        'icon': Icons.warning,
        'color': Colors.red.shade700
      },
    ];
  }

  List<Map<String, dynamic>> _getEmailCategories() {
    return [
      {
        'name': 'Quote Emails',
        'description': 'Send quotes and estimates via email',
        'icon': Icons.email,
        'color': Colors.blue
      },
      {
        'name': 'Contract Emails',
        'description': 'Send contracts and agreements',
        'icon': Icons.assignment,
        'color': Colors.green
      },
      {
        'name': 'Invoice Emails',
        'description': 'Send invoices and billing',
        'icon': Icons.receipt,
        'color': Colors.orange
      },
      {
        'name': 'Follow-up Emails',
        'description': 'Customer follow-up communications',
        'icon': Icons.reply,
        'color': Colors.purple
      },
      {
        'name': 'Appointment Emails',
        'description': 'Schedule confirmations and reminders',
        'icon': Icons.event,
        'color': Colors.teal
      },
      {
        'name': 'Marketing/Newsletter',
        'description': 'Promotional and newsletter emails',
        'icon': Icons.campaign,
        'color': Colors.pink
      },
    ];
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ACTION HANDLERS

  void _createNewPDFTemplate() async {
    // Show category selection dialog first
    final selectedCategory = await _showCategorySelectionDialog();

    if (selectedCategory != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateEditorScreen(
            preselectedCategory: selectedCategory,
          ),
        ),
      );
    }
  }

  Future<String?> _showCategorySelectionDialog() async {
    final appState = context.read<AppStateProvider>();
    final allCategories = await appState.getAllTemplateCategories();
    final pdfCategories = allCategories['pdf_templates'] ?? [];

    if (!mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Template Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "No Category" option
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('No Category'),
                subtitle: const Text('Create template without a specific category'),
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(),
              // User-defined categories
              ...pdfCategories.map<Widget>((category) {
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(category['name'] as String),
                  onTap: () => Navigator.pop(context, category['key'] as String),
                );
              }),
              const Divider(),
              // Option to create new category
              ListTile(
                leading: const Icon(Icons.add, color: Colors.blue),
                title: const Text('Create New Category'),
                subtitle: const Text('Add a new template category'),
                onTap: () {
                  Navigator.pop(context);
                  _showTemplateSettings(); // This opens category management
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _editPDFTemplate(PDFTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _previewPDFTemplate(PDFTemplate template) async {
    final navigator = Navigator.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating preview...'),
            ],
          ),
        ),
      );

      final previewPath =
          await TemplateService.instance.generateTemplatePreview(template);

      navigator.pop(); // Close loading dialog

      navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: previewPath,
            suggestedFileName: 'Preview_${template.templateName}.pdf',
            title: 'Template Preview: ${template.templateName}',
            isPreview: true,
          ),
        ),
      );
    } catch (e) {
      navigator.pop(); // Close loading dialog
      _showErrorSnackBar('Error generating preview: $e');
    }
  }

  void _handlePDFTemplateAction(String action, PDFTemplate template) {
    switch (action) {
      case 'toggle_active':
        context.read<AppStateProvider>().togglePDFTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
          ),
        );
        break;

      case 'duplicate':
        _duplicatePDFTemplate(template);
        break;

      case 'delete':
        _showPDFDeleteConfirmation(template);
        break;
    }
  }

  void _showPDFTemplateContextMenu(PDFTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.pop(context);
                _editPDFTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('Preview'),
              onTap: () {
                Navigator.pop(context);
                _previewPDFTemplate(template);
              },
            ),
            ListTile(
              leading: Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(template.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _handlePDFTemplateAction('toggle_active', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _handlePDFTemplateAction('duplicate', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handlePDFTemplateAction('delete', template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _duplicatePDFTemplate(PDFTemplate template) async {
    try {
      final duplicatedTemplate = template.clone();
      duplicatedTemplate.templateName = '${template.templateName} (Copy)';

      await context.read<AppStateProvider>().addPDFTemplate(duplicatedTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error duplicating template: $e');
      }
    }
  }

  void _showPDFDeleteConfirmation(PDFTemplate template) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?\n\n'
          'This action cannot be undone and will also delete the associated PDF file.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();

              try {
                await context
                    .read<AppStateProvider>()
                    .deletePDFTemplate(template.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Template deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorSnackBar('Error deleting template: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _createNewTextTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessageTemplateEditorScreen(),
      ),
    );
  }

  void _createNewEmailTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailTemplateEditorScreen(),
      ),
    );
  }

  // ADD THIS NEW METHOD HERE:
  void _createNewCustomField() {
    // Get the app state provider
    final appState = context.read<AppStateProvider>();

    // Get categories synchronously from already-loaded data
    final allTemplateCategories = appState.templateCategories;
    final customFieldCategories = allTemplateCategories
        .where((cat) => cat.templateType == 'custom_fields')
        .toList();

    final availableCategories = <String>['custom'];
    final categoryNames = <String, String>{'custom': 'Custom Fields'};

    // Add loaded categories
    for (final category in customFieldCategories) {
      availableCategories.add(category.key);
      categoryNames[category.key] = category.name;
    }



    showDialog<CustomAppDataField?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AddCustomFieldDialog(
          categories: availableCategories,
          categoryNames: categoryNames,
        );
      },
    ).then((returnedValue) {
      if (returnedValue != null && mounted) {
        appState.addCustomAppDataField(returnedValue).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added custom field: ${returnedValue.displayName}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }).catchError((error) {
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

  void _showTemplateSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }


  // NEW MESSAGE TEMPLATE CARD BUILDERS
  Widget _buildSelectableMessageCard(MessageTemplate template) {
    final isSelected = _selectedMessageIds.contains(template.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 3 : 1.5,
            color: isSelected ? Colors.green.shade50 : null,
            child: InkWell(
              onTap: _isMessageSelectionMode
                  ? () => _toggleMessageSelection(template.id)
                  : () => _editMessageTemplate(template),
              onLongPress: !_isMessageSelectionMode
                  ? () => _showMessageTemplateContextMenu(template)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      )
                    : null,
                child: _buildMessageTemplateCardContent(template, isSelected),
              ),
            ),
          ),
          if (_isMessageSelectionMode)
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
                  onChanged: (bool? value) =>
                      _toggleMessageSelection(template.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageTemplateCard(MessageTemplate template) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editMessageTemplate(template),
        onLongPress: () => _showMessageTemplateContextMenu(template),
        borderRadius: BorderRadius.circular(12),
        child: _buildMessageTemplateCardContent(template, false),
      ),
    );
  }

  Widget _buildMessageTemplateCardContent(
      MessageTemplate template, bool isSelected) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: template.isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sms,
                  color: template.isActive
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.templateName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green.shade800 : null,
                          ),
                    ),
                    if (template.description.isNotEmpty)
                      Text(
                        template.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.green.shade600
                                  : Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: template.isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  template.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Template preview
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              template.messageContent.length > 100
                  ? '${template.messageContent.substring(0, 100)}...'
                  : template.messageContent,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Template details
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  Icons.category,
                  'Category: ${template.userCategoryKey ?? 'No Category'}',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.dynamic_form,
                  '${template.placeholders.length} placeholders',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.calendar_today,
                  dateFormat.format(template.updatedAt),
                  isSelected: isSelected,
                ),
              ),
            ],
          ),

          if (!_isMessageSelectionMode) ...[
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editMessageTemplate(template),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendTestMessage(template),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Test'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleMessageTemplateAction(action, template),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            template.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(template.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Message template selection helpers
  void _toggleMessageSelection(String templateId) {
    setState(() {
      if (_selectedMessageIds.contains(templateId)) {
        _selectedMessageIds.remove(templateId);
      } else {
        _selectedMessageIds.add(templateId);
      }
    });
  }

  void _editMessageTemplate(MessageTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MessageTemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _sendTestMessage(MessageTemplate template) {
    _showErrorSnackBar('Test message sending coming soon!');
  }

  void _handleMessageTemplateAction(String action, MessageTemplate template) {
    switch (action) {
      case 'toggle_active':
        context
            .read<AppStateProvider>()
            .toggleMessageTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
          ),
        );
        break;

      case 'duplicate':
        _duplicateMessageTemplate(template);
        break;

      case 'delete':
        _showMessageDeleteConfirmation(template);
        break;
    }
  }

  void _showMessageTemplateContextMenu(MessageTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.pop(context);
                _editMessageTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send Test'),
              onTap: () {
                Navigator.pop(context);
                _sendTestMessage(template);
              },
            ),
            ListTile(
              leading: Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(template.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _handleMessageTemplateAction('toggle_active', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _handleMessageTemplateAction('duplicate', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleMessageTemplateAction('delete', template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _duplicateMessageTemplate(MessageTemplate template) async {
    try {
      final duplicatedTemplate = template.copyWith(
        templateName: '${template.templateName} (Copy)',
        updatedAt: DateTime.now(),
      );

      // Create a new template (copyWith keeps the same ID, but we need a new one)
      final newTemplate = MessageTemplate(
        templateName: duplicatedTemplate.templateName,
        description: duplicatedTemplate.description,
        category: duplicatedTemplate.category,
        messageContent: duplicatedTemplate.messageContent,
        placeholders: List.from(duplicatedTemplate.placeholders),
        isActive: duplicatedTemplate.isActive,
        sortOrder: duplicatedTemplate.sortOrder,
      );

      await context.read<AppStateProvider>().addMessageTemplate(newTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message template duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error duplicating template: $e');
      }
    }
  }

  void _showMessageDeleteConfirmation(MessageTemplate template) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();

              try {
                await context
                    .read<AppStateProvider>()
                    .deleteMessageTemplate(template.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Message template deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorSnackBar('Error deleting template: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

// Email template selection helpers
  void _toggleEmailSelection(String templateId) {
    setState(() {
      if (_selectedEmailIds.contains(templateId)) {
        _selectedEmailIds.remove(templateId);
      } else {
        _selectedEmailIds.add(templateId);
      }
    });
  }

  void _editEmailTemplate(EmailTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmailTemplateEditorScreen(existingTemplate: template),
      ),
    );
  }

  void _showEmailTemplateContextMenu(EmailTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Template'),
              onTap: () {
                Navigator.pop(context);
                _editEmailTemplate(template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send Test'),
              onTap: () {
                Navigator.pop(context);
                _sendTestEmail(template);
              },
            ),
            ListTile(
              leading: Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(template.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _handleEmailTemplateAction('toggle_active', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _handleEmailTemplateAction('duplicate', template);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleEmailTemplateAction('delete', template);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestEmail(EmailTemplate template) {
    _showErrorSnackBar('Test email sending coming soon!');
  }

  void _handleEmailTemplateAction(String action, EmailTemplate template) {
    switch (action) {
      case 'toggle_active':
        context.read<AppStateProvider>().toggleEmailTemplateActive(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              template.isActive ? 'Template deactivated' : 'Template activated',
            ),
          ),
        );
        break;

      case 'duplicate':
        _duplicateEmailTemplate(template);
        break;

      case 'delete':
        _showEmailDeleteConfirmation(template);
        break;
    }
  }

  void _duplicateEmailTemplate(EmailTemplate template) async {
    try {
      final duplicatedTemplate = template.copyWith(
        templateName: '${template.templateName} (Copy)',
        updatedAt: DateTime.now(),
      );

      // Create a new template (copyWith keeps the same ID, but we need a new one)
      final newTemplate = EmailTemplate(
        templateName: duplicatedTemplate.templateName,
        description: duplicatedTemplate.description,
        category: duplicatedTemplate.category,
        subject: duplicatedTemplate.subject,
        emailContent: duplicatedTemplate.emailContent,
        placeholders: List.from(duplicatedTemplate.placeholders),
        isActive: duplicatedTemplate.isActive,
        isHtml: duplicatedTemplate.isHtml,
        sortOrder: duplicatedTemplate.sortOrder,
      );

      await context.read<AppStateProvider>().addEmailTemplate(newTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email template duplicated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error duplicating template: $e');
      }
    }
  }

  void _showEmailDeleteConfirmation(EmailTemplate template) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();

              try {
                await context
                    .read<AppStateProvider>()
                    .deleteEmailTemplate(template.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Email template deleted successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                _showErrorSnackBar('Error deleting template: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTemplateCardContent(
      EmailTemplate template, bool isSelected) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: template.isActive
                      ? Colors.orange.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.email,
                  color: template.isActive
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.templateName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.orange.shade800 : null,
                          ),
                    ),
                    if (template.description.isNotEmpty)
                      Text(
                        template.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.orange.shade600
                                  : Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: template.isActive ? Colors.orange : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  template.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Email preview
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.subject.isNotEmpty) ...[
                  Text(
                    'Subject: ${template.subject.length > 50 ? '${template.subject.substring(0, 50)}...' : template.subject}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  template.emailContent.length > 100
                      ? '${template.emailContent.substring(0, 100)}...'
                      : template.emailContent,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Template details
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  Icons.category,
                  'Category: ${template.category}',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.dynamic_form,
                  '${template.placeholders.length} placeholders',
                  isSelected: isSelected,
                ),
              ),
              Expanded(
                child: _buildDetailChip(
                  Icons.calendar_today,
                  dateFormat.format(template.updatedAt),
                  isSelected: isSelected,
                ),
              ),
            ],
          ),

          if (!_isEmailSelectionMode) ...[
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editEmailTemplate(template),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendTestEmail(template),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Test'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleEmailTemplateAction(action, template),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            template.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(template.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

// EMAIL TEMPLATE CARD BUILDERS (NEW - ADDITION TO EXISTING MESSAGE METHODS)
  Widget _buildSelectableEmailCard(EmailTemplate template) {
    final isSelected = _selectedEmailIds.contains(template.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 3 : 1.5,
            color: isSelected ? Colors.orange.shade50 : null,
            child: InkWell(
              onTap: _isEmailSelectionMode
                  ? () => _toggleEmailSelection(template.id)
                  : () => _editEmailTemplate(template),
              onLongPress: !_isEmailSelectionMode
                  ? () => _showEmailTemplateContextMenu(template)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      )
                    : null,
                child: _buildEmailTemplateCardContent(template, isSelected),
              ),
            ),
          ),
          if (_isEmailSelectionMode)
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
                  onChanged: (bool? value) =>
                      _toggleEmailSelection(template.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailTemplateCard(EmailTemplate template) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editEmailTemplate(template),
        onLongPress: () => _showEmailTemplateContextMenu(template),
        borderRadius: BorderRadius.circular(12),
        child: _buildEmailTemplateCardContent(template, false),
      ),
    );
  }
}
