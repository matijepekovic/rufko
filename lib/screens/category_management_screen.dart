// lib/screens/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF Templates'),
            Tab(icon: Icon(Icons.sms), text: 'Messages'),
            Tab(icon: Icon(Icons.email), text: 'Emails'),
            Tab(icon: Icon(Icons.data_object), text: 'Custom Fields'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab('PDF Templates'),
          _buildCategoryTab('Message Templates'),
          _buildCategoryTab('Email Templates'),
          _buildCategoryTab('Custom Fields'),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String templateType) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadCategoriesForType(templateType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final actualCategories = snapshot.data ?? [];

        return Column(
          children: [
            // Header with add button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.category, color: const Color(0xFF2E86AB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$templateType Categories',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCategoryDialog(templateType),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E86AB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Categories list
            Expanded(
              child: actualCategories.isEmpty
                  ? _buildEmptyState(templateType)
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: actualCategories.length,
                itemBuilder: (context, index) {
                  final category = actualCategories[index];
                  return _buildCategoryCard(templateType, category);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  String _getTemplateTypeKey(String templateType) {
    switch (templateType) {
      case 'PDF Templates':
        return 'pdf_templates';
      case 'Message Templates':
        return 'message_templates';
      case 'Email Templates':
        return 'email_templates';
      case 'Custom Fields':
        return 'custom_fields';
      default:
        return templateType.toLowerCase().replaceAll(' ', '_');
    }
  }
  Future<List<Map<String, dynamic>>> _loadCategoriesForType(String templateType) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final allCategories = await appState.getAllTemplateCategories();

    final templateTypeKey = _getTemplateTypeKey(templateType);
    final categories = allCategories[templateTypeKey] ?? [];

    // Add usage counts to each category
    final categoriesWithUsage = <Map<String, dynamic>>[];
    for (final category in categories) {
      final usageCount = await appState.getCategoryUsageCount(templateType, category['key']);
      categoriesWithUsage.add({
        ...category,
        'usageCount': usageCount,
      });
    }

    return categoriesWithUsage;
  }

  Widget _buildCategoryCard(String templateType, Map<String, dynamic> category) {
    final String categoryKey = category['key'];
    final String categoryName = category['name'];
    final int usageCount = category['usageCount'] ?? 0;
    final bool canDelete = usageCount == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(templateType),
          child: Icon(
            _getCategoryIcon(templateType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          usageCount > 0
              ? '$usageCount template${usageCount != 1 ? 's' : ''} using this category'
              : 'No templates using this category',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditCategoryDialog(templateType, categoryKey, categoryName),
              tooltip: 'Edit category name',
            ),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                onPressed: () => _showDeleteCategoryDialog(templateType, categoryKey, categoryName),
                tooltip: 'Delete category',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String templateType) {
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
            'No $templateType Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first category to organize templates',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Placeholder methods for getting categories (hardcoded for now)
  // Real data methods using AppStateProvider
  List<Map<String, dynamic>> _getPDFCategories() {
    return [];  // Will be loaded from FutureBuilder
  }

  List<Map<String, dynamic>> _getMessageCategories() {
    return [];  // Will be loaded from FutureBuilder
  }

  List<Map<String, dynamic>> _getEmailCategories() {
    return [];  // Will be loaded from FutureBuilder
  }

  List<Map<String, dynamic>> _getCustomFieldCategories() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final categories = ['company', 'contact', 'legal', 'pricing', 'custom'];

    return categories.map((categoryKey) {
      final fieldsInCategory = appState.customAppDataFields
          .where((field) => field.category == categoryKey)
          .length;

      final categoryNames = {
        'company': 'Company Information',
        'contact': 'Contact Information',
        'legal': 'Legal Information',
        'pricing': 'Pricing Information',
        'custom': 'Custom Fields',
      };

      return {
        'key': categoryKey,
        'name': categoryNames[categoryKey] ?? categoryKey,
        'usageCount': fieldsInCategory,
      };
    }).toList();
  }

  Color _getCategoryColor(String templateType) {
    switch (templateType) {
      case 'PDF Templates': return const Color(0xFF2E86AB);
      case 'Message Templates': return Colors.green;
      case 'Email Templates': return Colors.orange;
      case 'Custom Fields': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String templateType) {
    switch (templateType) {
      case 'PDF Templates': return Icons.picture_as_pdf;
      case 'Message Templates': return Icons.sms;
      case 'Email Templates': return Icons.email;
      case 'Custom Fields': return Icons.data_object;
      default: return Icons.category;
    }
  }

  void _showAddCategoryDialog(String templateType) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $templateType Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Contract Templates',
                prefixIcon: const Icon(Icons.category),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addCategory(templateType, value.trim(), controller);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Category keys will be auto-generated in lowercase with underscores.',
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
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _addCategory(templateType, newName, controller);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(String templateType, String categoryKey, String categoryName) {
    final TextEditingController controller = TextEditingController(text: categoryName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Category Name',
                prefixIcon: const Icon(Icons.edit),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _editCategory(templateType, categoryKey, value.trim(), controller);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Existing templates will automatically use the new category name.',
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
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _editCategory(templateType, categoryKey, newName, controller);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(String templateType, String categoryKey, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this category?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: $categoryName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Type: $templateType'),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(templateType, categoryKey, categoryName);
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

  // Action methods (placeholders for now)
  // Real action methods with database integration
  Future<void> _addCategory(String templateType, String categoryName, TextEditingController controller) async {
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      // Generate category key from name
      final categoryKey = categoryName.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');

      final templateTypeKey = _getTemplateTypeKey(templateType);
      await appState.addTemplateCategory(templateTypeKey, categoryKey, categoryName);

      controller.dispose();
      Navigator.pop(context);

      setState(() {}); // Refresh the UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$categoryName" to $templateType successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editCategory(String templateType, String categoryKey, String newName, TextEditingController controller) async {
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      await appState.updateTemplateCategory(templateType, categoryKey, newName);

      controller.dispose();
      Navigator.pop(context);

      setState(() {}); // Refresh the UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated category to "$newName" successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCategory(String templateType, String categoryKey, String categoryName) async {
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      await appState.deleteTemplateCategory(templateType, categoryKey);

      setState(() {}); // Refresh the UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "$categoryName" successfully!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}