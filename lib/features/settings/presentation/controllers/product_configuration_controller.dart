import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/settings/product_configuration_service.dart';
import '../screens/category_manager_dialog.dart';
import '../screens/quote_levels_manager_dialog.dart';
import '../screens/units_manager_dialog.dart';
import '../screens/job_type_manager_dialog.dart';

class ProductConfigurationController {
  ProductConfigurationController(this.context)
      : appState = context.read<AppStateProvider>(),
        settings = context.read<AppStateProvider>().appSettings ?? AppSettings();

  final BuildContext context;
  final AppStateProvider appState;
  final AppSettings settings;

  void showCategoriesManager() {
    showDialog(
      context: context,
      builder: (context) => CategoryManagerDialog(
        categories: List.from(settings.productCategories),
        onSave: (updated) => ProductConfigurationService.updateProductCategories(
          appState: appState,
          settings: settings,
          updatedCategories: updated,
        ),
      ),
    );
  }

  void showUnitsManager() {
    showDialog(
      context: context,
      builder: (context) => UnitsManagerDialog(
        units: List.from(settings.productUnits),
        defaultUnit: settings.defaultUnit,
        onSave: (units, def) => ProductConfigurationService.updateProductUnits(
          appState: appState,
          settings: settings,
          units: units,
          defaultUnit: def,
        ),
      ),
    );
  }

  void showQuoteLevelsManager() {
    showDialog(
      context: context,
      builder: (context) => QuoteLevelsManagerDialog(
        levelNames: List.from(settings.defaultQuoteLevelNames),
        onSave: (levels) => ProductConfigurationService.updateQuoteLevels(
          appState: appState,
          settings: settings,
          levels: levels,
        ),
      ),
    );
  }

  void showJobTypesManager() {
    showDialog(
      context: context,
      builder: (context) => JobTypeManagerDialog(
        jobTypes: List.from(settings.jobTypes),
        onSave: (types) => ProductConfigurationService.updateJobTypes(
          appState: appState,
          settings: settings,
          jobTypes: types,
        ),
      ),
    );
  }
}
