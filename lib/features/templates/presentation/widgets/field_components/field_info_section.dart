import 'package:flutter/material.dart';

import '../../../../../data/models/settings/custom_app_data.dart';
import '../../services/field_type_service.dart';

/// Reusable field information section widget
/// Shows field display name, field name, type, and current value
class FieldInfoSection extends StatelessWidget {
  final CustomAppDataField field;
  final bool isSelected;
  final bool isVerySmall;
  final Color primaryColor;

  const FieldInfoSection({
    super.key,
    required this.field,
    required this.isSelected,
    required this.isVerySmall,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDisplayName(),
          SizedBox(height: isVerySmall ? 2 : 3),
          _buildFieldNameAndType(),
          if (field.currentValue.isNotEmpty) ...[
            SizedBox(height: isVerySmall ? 2 : 3),
            _buildCurrentValue(),
          ],
        ],
      ),
    );
  }

  /// Build field display name
  Widget _buildDisplayName() {
    return Text(
      field.displayName,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: isVerySmall ? 13 : 14,
        color: isSelected ? primaryColor : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build field name and type row
  Widget _buildFieldNameAndType() {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.fieldName,
            style: TextStyle(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.7)
                  : Colors.grey[600],
              fontSize: isVerySmall ? 10 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          field.fieldType,
          style: TextStyle(
            color: FieldTypeService.getFieldTypeColor(field.fieldType),
            fontSize: isVerySmall ? 9 : 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build current value indicator
  Widget _buildCurrentValue() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 4 : 6,
        vertical: isVerySmall ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.2)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        field.currentValue,
        style: TextStyle(
          fontSize: isVerySmall ? 9 : 10,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}