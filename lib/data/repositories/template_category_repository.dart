import 'package:flutter/foundation.dart';
import '../database/template_category_database.dart';
import '../models/templates/template_category.dart';

/// Repository for TemplateCategory data access operations
/// Handles category management for organizing templates
class TemplateCategoryRepository {
  final TemplateCategoryDatabase _database = TemplateCategoryDatabase();

  /// Get all template categories
  Future<List<TemplateCategory>> getAllTemplateCategories() async {
    try {
      return await _database.getAllTemplateCategories();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all template categories: $e');
      }
      return [];
    }
  }

  /// Get template categories structured for UI display
  /// Returns a map with keys like 'pdf_templates', 'message_templates', etc.
  Future<Map<String, List<Map<String, dynamic>>>> getTemplateCategoriesForUI() async {
    try {
      return await _database.getTemplateCategoriesForUI();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting template categories for UI: $e');
      }
      return {
        'pdf_templates': [],
        'message_templates': [],
        'email_templates': [],
        'fields': [],
      };
    }
  }

  /// Get raw categories (for compatibility with existing code)
  Future<List<TemplateCategory>> getRawCategoriesBoxValues() async {
    return await getAllTemplateCategories();
  }

  /// Get template categories by template type
  Future<List<TemplateCategory>> getTemplateCategoriesByType(String templateType) async {
    try {
      return await _database.getTemplateCategoriesByType(templateType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting template categories by type $templateType: $e');
      }
      return [];
    }
  }

  /// Get template category by ID
  Future<TemplateCategory?> getTemplateCategoryById(String categoryId) async {
    try {
      return await _database.getTemplateCategoryById(categoryId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting template category by ID $categoryId: $e');
      }
      return null;
    }
  }

  /// Get template category by key and template type
  Future<TemplateCategory?> getTemplateCategoryByKey(String key, String templateType) async {
    try {
      return await _database.getTemplateCategoryByKey(key, templateType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting template category by key $key and type $templateType: $e');
      }
      return null;
    }
  }

  /// Save (create or update) a template category
  Future<void> saveTemplateCategory(TemplateCategory category) async {
    try {
      // Check if category already exists
      final existing = await _database.getTemplateCategoryById(category.id);
      
      if (existing != null) {
        await _database.updateTemplateCategory(category);
        if (kDebugMode) {
          debugPrint('✅ Updated template category: ${category.name}');
        }
      } else {
        await _database.insertTemplateCategory(category);
        if (kDebugMode) {
          debugPrint('✅ Created template category: ${category.name}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving template category: $e');
      }
      rethrow;
    }
  }

  /// Create a new template category
  Future<void> createTemplateCategory(TemplateCategory category) async {
    try {
      await _database.insertTemplateCategory(category);
      if (kDebugMode) {
        debugPrint('✅ Created template category: ${category.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating template category: $e');
      }
      rethrow;
    }
  }

  /// Insert multiple template categories
  Future<void> insertTemplateCategories(List<TemplateCategory> categories) async {
    try {
      await _database.insertTemplateCategories(categories);
      if (kDebugMode) {
        debugPrint('✅ Inserted ${categories.length} template categories');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inserting template categories: $e');
      }
      rethrow;
    }
  }

  /// Update template category
  Future<void> updateTemplateCategory(TemplateCategory category) async {
    try {
      await _database.updateTemplateCategory(category);
      if (kDebugMode) {
        debugPrint('✅ Updated template category: ${category.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating template category: $e');
      }
      rethrow;
    }
  }

  /// Update template category name by ID
  Future<void> updateTemplateCategoryName(String categoryId, String newName) async {
    try {
      await _database.updateTemplateCategoryName(categoryId, newName);
      if (kDebugMode) {
        debugPrint('✅ Updated template category name to: $newName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating template category name: $e');
      }
      rethrow;
    }
  }

  /// Delete template category
  Future<void> deleteTemplateCategory(String categoryId) async {
    try {
      await _database.deleteTemplateCategory(categoryId);
      if (kDebugMode) {
        debugPrint('✅ Deleted template category: $categoryId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting template category: $e');
      }
      rethrow;
    }
  }

  /// Clear all template categories
  Future<void> clearAllTemplateCategories() async {
    try {
      await _database.clearAllTemplateCategories();
      if (kDebugMode) {
        debugPrint('✅ Cleared all template categories');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing template categories: $e');
      }
      rethrow;
    }
  }

  /// Search template categories by name or key
  Future<List<TemplateCategory>> searchTemplateCategories(String query) async {
    try {
      return await _database.searchTemplateCategories(query);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching template categories: $e');
      }
      return [];
    }
  }

  /// Check if category key exists for a given template type
  Future<bool> categoryKeyExists(String key, String templateType) async {
    try {
      return await _database.categoryKeyExists(key, templateType);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking category key existence: $e');
      }
      return false;
    }
  }

  /// Get category usage count for a specific template type and category key
  /// This method provides compatibility with the existing getCategoryUsageCount interface
  Future<int> getCategoryUsageCount(String templateTypeScreenName, String categoryKey) async {
    try {
      // This is a placeholder that should be coordinated with other repositories
      // In a full implementation, this would query related tables for usage counts
      // For now, return 0 as this functionality needs coordination across repositories
      if (kDebugMode) {
        debugPrint('⚠️ getCategoryUsageCount not fully implemented in repository pattern');
        debugPrint('   Template Type: $templateTypeScreenName, Category Key: $categoryKey');
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting category usage count: $e');
      }
      return 0;
    }
  }

  /// Create a new category with automatic key generation
  Future<TemplateCategory> createCategoryWithAutoKey({
    required String name,
    required String templateType,
  }) async {
    try {
      // Generate a key from the name (lowercase, replace spaces with underscores)
      String baseKey = name.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special characters
          .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscores
      
      String key = baseKey;
      int counter = 1;
      
      // Ensure key is unique for this template type
      while (await categoryKeyExists(key, templateType)) {
        key = '${baseKey}_$counter';
        counter++;
      }
      
      final category = TemplateCategory(
        key: key,
        name: name,
        templateType: templateType,
      );
      
      await createTemplateCategory(category);
      return category;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating category with auto key: $e');
      }
      rethrow;
    }
  }

  /// Get template category statistics
  Future<Map<String, dynamic>> getTemplateCategoryStatistics() async {
    try {
      return await _database.getTemplateCategoryStatistics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting template category statistics: $e');
      }
      return {
        'error': e.toString(),
        'total_categories': 0,
        'categories_by_type': <String, int>{},
      };
    }
  }

  /// Close database connection
  Future<void> close() async {
    await _database.close();
  }
}