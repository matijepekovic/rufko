import 'package:flutter/material.dart';

import '../../../../../data/models/settings/custom_app_data.dart';
import 'field_type_indicator.dart';
import 'field_info_section.dart';
import 'field_action_menu.dart';
import 'field_selection_indicator.dart';

/// Reusable field tile widget
/// Combines all field components into a complete list item
class FieldTile extends StatelessWidget {
  final CustomAppDataField field;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isSmallScreen;
  final bool isVerySmall;
  final Color primaryColor;
  final VoidCallback onTap;
  final Function(String action, CustomAppDataField field) onAction;

  const FieldTile({
    super.key,
    required this.field,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isSmallScreen,
    required this.isVerySmall,
    required this.primaryColor,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmall ? 8 : 12,
          vertical: isVerySmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
          border: isSelected
              ? Border.all(color: primaryColor, width: 1)
              : const Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: Row(
          children: [
            // Field type indicator
            FieldTypeIndicator(
              fieldType: field.fieldType,
              isSmall: isVerySmall,
            ),

            SizedBox(width: isVerySmall ? 8 : 12),

            // Field info section
            FieldInfoSection(
              field: field,
              isSelected: isSelected,
              isVerySmall: isVerySmall,
              primaryColor: primaryColor,
            ),

            // Selection indicator or action menu
            if (isSelectionMode)
              FieldSelectionIndicator(
                isSelected: isSelected,
                isVerySmall: isVerySmall,
                primaryColor: primaryColor,
              )
            else
              FieldActionMenu(
                field: field,
                isVerySmall: isVerySmall,
                onAction: onAction,
              ),
          ],
        ),
      ),
    );
  }
}