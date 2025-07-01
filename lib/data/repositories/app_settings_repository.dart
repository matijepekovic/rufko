import 'package:flutter/foundation.dart';
import '../database/app_settings_database.dart';
import '../models/settings/app_settings.dart';

/// Repository for AppSettings data access operations
/// Handles singleton settings management and CRUD operations
class AppSettingsRepository {
  final AppSettingsDatabase _database = AppSettingsDatabase();
  
  static const String singletonSettingsId = 'singleton_app_settings';

  /// Get the singleton AppSettings (creates default if none exists)
  Future<AppSettings> getAppSettings() async {
    try {
      // Try to get existing singleton settings
      AppSettings? settings = await _database.getSingletonSettings();
      
      if (settings == null) {
        // Create default settings if none exist
        settings = _createDefaultSettings();
        await _database.insertAppSettings(settings);
        if (kDebugMode) {
          debugPrint('✅ Created default AppSettings');
        }
      }
      
      return settings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting AppSettings: $e');
      }
      // Return default settings as fallback
      return _createDefaultSettings();
    }
  }

  /// Update the singleton AppSettings
  Future<void> updateAppSettings(AppSettings settings) async {
    try {
      // Ensure we're updating the singleton
      final settingsToUpdate = AppSettings(
        id: singletonSettingsId,
        productCategories: settings.productCategories,
        productUnits: settings.productUnits,
        defaultUnit: settings.defaultUnit,
        defaultQuoteLevelNames: settings.defaultQuoteLevelNames,
        taxRate: settings.taxRate,
        companyName: settings.companyName,
        companyAddress: settings.companyAddress,
        companyPhone: settings.companyPhone,
        companyEmail: settings.companyEmail,
        companyLogoPath: settings.companyLogoPath,
        discountTypes: settings.discountTypes,
        allowProductDiscountToggle: settings.allowProductDiscountToggle,
        defaultDiscountLimit: settings.defaultDiscountLimit,
        showCalculatorQuickChips: settings.showCalculatorQuickChips,
        jobTypes: settings.jobTypes,
        updatedAt: DateTime.now(),
      );

      final hasSettings = await _database.hasSettings();
      
      if (hasSettings) {
        await _database.updateAppSettings(settingsToUpdate);
        if (kDebugMode) {
          debugPrint('✅ Updated AppSettings');
        }
      } else {
        await _database.insertAppSettings(settingsToUpdate);
        if (kDebugMode) {
          debugPrint('✅ Inserted new AppSettings');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating AppSettings: $e');
      }
      rethrow;
    }
  }

  /// Save AppSettings (alias for updateAppSettings for compatibility)
  Future<void> saveAppSettings(AppSettings settings) async {
    await updateAppSettings(settings);
  }

  /// Check if AppSettings exist
  Future<bool> hasAppSettings() async {
    try {
      return await _database.hasSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking AppSettings existence: $e');
      }
      return false;
    }
  }

  /// Clear all AppSettings data
  Future<void> clearAllSettings() async {
    try {
      await _database.clearAllSettings();
      if (kDebugMode) {
        debugPrint('✅ Cleared all AppSettings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing AppSettings: $e');
      }
      rethrow;
    }
  }

  /// Get AppSettings statistics
  Future<Map<String, dynamic>> getSettingsStatistics() async {
    try {
      return await _database.getSettingsStatistics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting AppSettings statistics: $e');
      }
      return {
        'error': e.toString(),
        'settings_count': 0,
        'categories_count': 0,
        'units_count': 0,
        'level_names_count': 0,
        'discount_types_count': 0,
        'has_singleton': false,
      };
    }
  }

  /// Update specific settings fields (partial update)
  Future<void> updateSettingsFields({
    String? defaultUnit,
    double? taxRate,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companyLogoPath,
    List<String>? productCategories,
    List<String>? productUnits,
    List<String>? defaultQuoteLevelNames,
    List<String>? discountTypes,
    bool? allowProductDiscountToggle,
    double? defaultDiscountLimit,
    bool? showCalculatorQuickChips,
    List<String>? jobTypes,
  }) async {
    try {
      // Get current settings
      final currentSettings = await getAppSettings();
      
      // Create updated settings with only changed fields
      final updatedSettings = AppSettings(
        id: singletonSettingsId,
        defaultUnit: defaultUnit ?? currentSettings.defaultUnit,
        taxRate: taxRate ?? currentSettings.taxRate,
        companyName: companyName ?? currentSettings.companyName,
        companyAddress: companyAddress ?? currentSettings.companyAddress,
        companyPhone: companyPhone ?? currentSettings.companyPhone,
        companyEmail: companyEmail ?? currentSettings.companyEmail,
        companyLogoPath: companyLogoPath ?? currentSettings.companyLogoPath,
        productCategories: productCategories ?? currentSettings.productCategories,
        productUnits: productUnits ?? currentSettings.productUnits,
        defaultQuoteLevelNames: defaultQuoteLevelNames ?? currentSettings.defaultQuoteLevelNames,
        discountTypes: discountTypes ?? currentSettings.discountTypes,
        allowProductDiscountToggle: allowProductDiscountToggle ?? currentSettings.allowProductDiscountToggle,
        defaultDiscountLimit: defaultDiscountLimit ?? currentSettings.defaultDiscountLimit,
        showCalculatorQuickChips: showCalculatorQuickChips ?? currentSettings.showCalculatorQuickChips,
        jobTypes: jobTypes ?? currentSettings.jobTypes,
        updatedAt: DateTime.now(),
      );
      
      await updateAppSettings(updatedSettings);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating settings fields: $e');
      }
      rethrow;
    }
  }

  /// Add a product category (if not already exists)
  Future<void> addProductCategory(String category) async {
    try {
      final settings = await getAppSettings();
      if (!settings.productCategories.contains(category)) {
        final updatedCategories = List<String>.from(settings.productCategories)
          ..add(category);
        await updateSettingsFields(productCategories: updatedCategories);
        if (kDebugMode) {
          debugPrint('✅ Added product category: $category');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding product category: $e');
      }
      rethrow;
    }
  }

  /// Remove a product category
  Future<void> removeProductCategory(String category) async {
    try {
      final settings = await getAppSettings();
      if (settings.productCategories.contains(category)) {
        final updatedCategories = List<String>.from(settings.productCategories)
          ..remove(category);
        await updateSettingsFields(productCategories: updatedCategories);
        if (kDebugMode) {
          debugPrint('✅ Removed product category: $category');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing product category: $e');
      }
      rethrow;
    }
  }

  /// Add a product unit (if not already exists)
  Future<void> addProductUnit(String unit) async {
    try {
      final settings = await getAppSettings();
      if (!settings.productUnits.contains(unit)) {
        final updatedUnits = List<String>.from(settings.productUnits)
          ..add(unit);
        await updateSettingsFields(productUnits: updatedUnits);
        if (kDebugMode) {
          debugPrint('✅ Added product unit: $unit');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding product unit: $e');
      }
      rethrow;
    }
  }

  /// Remove a product unit
  Future<void> removeProductUnit(String unit) async {
    try {
      final settings = await getAppSettings();
      if (settings.productUnits.contains(unit)) {
        final updatedUnits = List<String>.from(settings.productUnits)
          ..remove(unit);
        
        // If removing the default unit, set a new default
        String? newDefaultUnit;
        if (settings.defaultUnit == unit && updatedUnits.isNotEmpty) {
          newDefaultUnit = updatedUnits.first;
        }
        
        await updateSettingsFields(
          productUnits: updatedUnits,
          defaultUnit: newDefaultUnit,
        );
        
        if (kDebugMode) {
          debugPrint('✅ Removed product unit: $unit');
          if (newDefaultUnit != null) {
            debugPrint('✅ Updated default unit to: $newDefaultUnit');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing product unit: $e');
      }
      rethrow;
    }
  }

  /// Update company information
  Future<void> updateCompanyInfo({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
  }) async {
    try {
      await updateSettingsFields(
        companyName: name,
        companyAddress: address,
        companyPhone: phone,
        companyEmail: email,
        companyLogoPath: logoPath,
      );
      if (kDebugMode) {
        debugPrint('✅ Updated company information');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating company info: $e');
      }
      rethrow;
    }
  }

  /// Update discount settings
  Future<void> updateDiscountSettings({
    List<String>? types,
    bool? allowToggle,
    double? discountLimit,
  }) async {
    try {
      await updateSettingsFields(
        discountTypes: types,
        allowProductDiscountToggle: allowToggle,
        defaultDiscountLimit: discountLimit,
      );
      if (kDebugMode) {
        debugPrint('✅ Updated discount settings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating discount settings: $e');
      }
      rethrow;
    }
  }

  /// Update calculator settings
  Future<void> updateCalculatorSettings({
    bool? showQuickChips,
  }) async {
    try {
      await updateSettingsFields(
        showCalculatorQuickChips: showQuickChips,
      );
      if (kDebugMode) {
        debugPrint('✅ Updated calculator settings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating calculator settings: $e');
      }
      rethrow;
    }
  }

  /// Create default AppSettings
  AppSettings _createDefaultSettings() {
    return AppSettings(
      id: singletonSettingsId,
      productCategories: [
        'Materials',
        'Roofing',
        'Gutters',
        'Flashing',
        'Labor',
        'Other'
      ],
      productUnits: [
        'sq ft',
        'lin ft',
        'each',
        'hour',
        'day',
        'bundle',
        'roll',
        'sheet'
      ],
      defaultUnit: 'sq ft',
      defaultQuoteLevelNames: ['Basic', 'Standard', 'Premium'],
      taxRate: 0.0,
      discountTypes: ['percentage', 'fixed_amount', 'voucher'],
      allowProductDiscountToggle: true,
      defaultDiscountLimit: 25.0,
      showCalculatorQuickChips: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Close database connection
  Future<void> close() async {
    await _database.close();
  }
}