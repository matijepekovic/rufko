import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/category_manager_dialog.dart';
import '../screens/quote_levels_manager_dialog.dart';
import '../screens/units_manager_dialog.dart';

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
        onSave: (updated) {
          settings.updateProductCategories(updated);
          appState.updateAppSettings(settings);
        },
      ),
    );
  }

  void showUnitsManager() {
    showDialog(
      context: context,
      builder: (context) => UnitsManagerDialog(
        units: List.from(settings.productUnits),
        defaultUnit: settings.defaultUnit,
        onSave: (units, def) {
          settings.updateProductUnits(units);
          settings.updateDefaultUnit(def);
          appState.updateAppSettings(settings);
        },
      ),
    );
  }

  void showQuoteLevelsManager() {
    showDialog(
      context: context,
      builder: (context) => QuoteLevelsManagerDialog(
        levelNames: List.from(settings.defaultQuoteLevelNames),
        onSave: (levels) {
          settings.updateDefaultQuoteLevelNames(levels);
          appState.updateAppSettings(settings);
        },
      ),
    );
  }
}
