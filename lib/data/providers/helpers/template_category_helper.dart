
import '../../models/templates/template_category.dart';
import '../../../core/services/database/database_service.dart';

class TemplateCategoryHelper {
  static Future<Map<String, List<Map<String, dynamic>>>> fetchAll(
      DatabaseService db) async {
    return await db.getAllTemplateCategories();
  }

  static Future<TemplateCategory> addCategory({
    required DatabaseService db,
    required List<TemplateCategory> categories,
    required String templateTypeKey,
    required String categoryUserKey,
    required String categoryDisplayName,
  }) async {
    final newCategory = TemplateCategory(
      key: categoryUserKey,
      name: categoryDisplayName,
      templateType: templateTypeKey,
    );
    await db.saveTemplateCategory(newCategory);
    categories.add(newCategory);
    return newCategory;
  }

  static Future<TemplateCategory?> updateCategory({
    required DatabaseService db,
    required List<TemplateCategory> categories,
    required String templateTypeKey,
    required String categoryUserKey,
    required String newDisplayName,
  }) async {
    final index = categories.indexWhere(
        (c) => c.templateType == templateTypeKey && c.key == categoryUserKey);
    if (index == -1) return null;
    final category = categories[index];
    await db.updateTemplateCategory(category.id, newDisplayName);
    categories[index] =
        category.copyWith(name: newDisplayName, updatedAt: DateTime.now());
    return categories[index];
  }

  static Future<bool> deleteCategory({
    required DatabaseService db,
    required List<TemplateCategory> categories,
    required String templateTypeKey,
    required String categoryUserKey,
  }) async {
    final index = categories.indexWhere(
        (c) => c.templateType == templateTypeKey && c.key == categoryUserKey);
    if (index == -1) return false;
    final category = categories[index];
    await db.deleteTemplateCategory(category.id);
    categories.removeAt(index);
    return true;
  }

  static Future<int> usageCount(
      DatabaseService db, String templateType, String categoryKey) async {
    return await db.getCategoryUsageCount(templateType, categoryKey);
  }
}
