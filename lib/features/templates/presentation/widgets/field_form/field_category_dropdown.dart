import 'package:flutter/material.dart';
import '../../controllers/field_dialog_controller.dart';

/// Reusable category dropdown widget with inline category creation
/// Extracted from FieldDialog for better maintainability
class FieldCategoryDropdown extends StatelessWidget {
  final FieldDialogController controller;

  const FieldCategoryDropdown({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return DropdownButtonFormField<String>(
          value: controller.selectedFieldCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: _buildDropdownItems(),
          onChanged: controller.onCategoryChanged,
          validator: controller.validateCategory,
        );
      },
    );
  }

  /// Build dropdown items including create new category option
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    
    // Add existing categories
    for (final categoryValue in controller.currentCategories) {
      items.add(
        DropdownMenuItem<String>(
          value: categoryValue,
          child: Text(
            controller.currentCategoryNames[categoryValue] ?? categoryValue,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }
    
    // Add divider if categories exist
    if (controller.currentCategories.isNotEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          enabled: false,
          value: null,
          child: Divider(height: 1),
        ),
      );
    }
    
    // Add create new category option
    items.add(
      DropdownMenuItem<String>(
        value: FieldDialogController.createNewCategoryValue,
        child: Row(
          children: [
            Icon(
              Icons.add,
              color: const Color(0xFF2196F3), // RufkoTheme.primaryColor
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text(
              'Create New Category...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
    
    return items;
  }
}