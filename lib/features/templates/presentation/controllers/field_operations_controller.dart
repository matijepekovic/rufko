import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/custom_app_data.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../widgets/dialogs/field_dialog.dart';
import '../../../../core/utils/helpers/common_utils.dart';

/// Controller for handling field operations (add, edit, delete)
/// Extracted from FieldsTab for better separation of concerns
class FieldOperationsController extends ChangeNotifier {
  final BuildContext _context;
  
  FieldOperationsController(this._context);

  AppStateProvider get _appState => _context.read<AppStateProvider>();
  ScaffoldMessengerState get _messenger => ScaffoldMessenger.of(_context);

  /// Show dialog to add a new field
  Future<void> showAddFieldDialog() async {
    if (!_context.mounted) return;
    
    final returnedValue = await showDialog<CustomAppDataField?>(
      context: _context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _appState.getAllTemplateCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: CircularProgressIndicator(),
              );
            }

            final allCategories = snapshot.data!;
            final customFieldCategories = allCategories['custom_fields'] ?? [];

            final availableCategories = <String>[];
            final categoryNames = <String, String>{};

            for (final category in customFieldCategories) {
              final categoryKey = category['key'] as String;
              final categoryName = category['name'] as String;
              availableCategories.add(categoryKey);
              categoryNames[categoryKey] = categoryName;
            }

            return FieldDialog.add(
              categories: availableCategories,
              categoryNames: categoryNames,
            );
          },
        );
      },
    );
    
    if (returnedValue != null && _context.mounted) {
      try {
        await _appState.addCustomAppDataField(returnedValue);
      } catch (error) {
        if (_context.mounted) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Error adding field: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show dialog to edit an existing field
  Future<void> showEditFieldDialog(CustomAppDataField field) async {
    if (!_context.mounted) return;
    
    final updatedField = await showDialog<CustomAppDataField?>(
      context: _context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _appState.getAllTemplateCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: CircularProgressIndicator(),
              );
            }

            final allCategories = snapshot.data!;
            final customFieldCategories = allCategories['custom_fields'] ?? [];

            final availableCategories = <String>[field.category];
            final categoryNames = <String, String>{
              field.category: formatCategoryName(field.category)
            };

            for (final category in customFieldCategories) {
              final categoryKey = category['key'] as String;
              final categoryName = category['name'] as String;
              if (!availableCategories.contains(categoryKey)) {
                availableCategories.add(categoryKey);
                categoryNames[categoryKey] = categoryName;
              }
            }

            return FieldDialog.edit(
              field,
              categories: availableCategories,
              categoryNames: categoryNames,
            );
          },
        );
      },
    );
    
    if (updatedField != null && _context.mounted) {
      try {
        await _appState.updateCustomAppDataFieldStructure(updatedField);

        if (_context.mounted) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Updated field: ${updatedField.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (_context.mounted) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Error updating field: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show confirmation dialog and delete field
  Future<void> deleteField(CustomAppDataField field) async {
    final confirmed = await showDialog<bool>(
      context: _context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this field?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field: ${field.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${field.fieldName}'),
                    Text('Category: ${field.category}'),
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
    );
    
    if (confirmed == true && _context.mounted) {
      try {
        await _appState.deleteCustomAppDataField(field.id);

        if (_context.mounted) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Deleted field: ${field.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (_context.mounted) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Error deleting field: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Handle field menu actions
  void handleFieldAction(String action, CustomAppDataField field) {
    switch (action) {
      case 'edit':
        showEditFieldDialog(field);
        break;
      case 'delete':
        deleteField(field);
        break;
    }
  }

}