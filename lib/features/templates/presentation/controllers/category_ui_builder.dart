import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../app/theme/rufko_theme.dart';
import 'category_data_controller.dart';
import 'category_dialog_manager.dart';

class CategoryUIBuilder {
  CategoryUIBuilder(this.context, this.dataController, this.dialogManager);

  final BuildContext context;
  final CategoryDataController dataController;
  final CategoryDialogManager dialogManager;

  Widget buildCategoryTab(String templateType, bool isPhone) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final allCategories = dataController.getCachedCategories(templateType);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(
                    Icons.category,
                    color: RufkoTheme.primaryColor,
                    size: isPhone ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$templateType Categories',
                      style: TextStyle(
                        fontSize: isPhone ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isPhone)
                    IconButton(
                      onPressed: () =>
                          dialogManager.showAddCategoryDialog(templateType),
                      icon: const Icon(Icons.add),
                      color: RufkoTheme.primaryColor,
                      tooltip: 'Add Category',
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () =>
                          dialogManager.showAddCategoryDialog(templateType),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RufkoTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: allCategories.isEmpty
                  ? buildEmptyState(templateType)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final category = allCategories[index];
                        return buildCategoryCard(templateType, category);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget buildCategoryCard(String templateType, Map<String, dynamic> category) {
    final String categoryKey = category['key'];
    final String categoryName = category['name'];
    final int usageCount = category['usageCount'] ?? 0;
    final bool isProtected = category['isProtected'] ?? false;
    final bool canDelete = usageCount == 0 && !isProtected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isProtected
              ? Colors.blue.shade700
              : getCategoryColor(templateType),
          child: Icon(
            isProtected ? Icons.security : getCategoryIcon(templateType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              categoryName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (isProtected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'PROTECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          usageCount > 0
              ? '$usageCount field${usageCount != 1 ? 's' : ''} in this category'
              : 'No fields in this category',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isProtected)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => dialogManager.showEditCategoryDialog(
                    templateType, categoryKey, categoryName),
                tooltip: 'Edit category name',
              ),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                onPressed: () => dialogManager.showDeleteCategoryDialog(
                    templateType, categoryKey, categoryName),
                tooltip: 'Delete category',
              ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState(String templateType) {
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

  Color getCategoryColor(String templateType) {
    switch (templateType) {
      case 'PDF':
        return RufkoTheme.primaryColor;
      case 'Message Templates':
        return Colors.green;
      case 'Email Templates':
        return Colors.orange;
      case 'Fields':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData getCategoryIcon(String templateType) {
    switch (templateType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Message Templates':
        return Icons.sms;
      case 'Email Templates':
        return Icons.email;
      case 'Fields':
        return Icons.data_object;
      default:
        return Icons.category;
    }
  }
}
