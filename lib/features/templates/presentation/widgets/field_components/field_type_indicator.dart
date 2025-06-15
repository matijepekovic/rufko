import 'package:flutter/material.dart';

import '../../services/field_type_service.dart';

/// Reusable field type indicator widget
/// Shows colored circle with field type icon
class FieldTypeIndicator extends StatelessWidget {
  final String fieldType;
  final bool isSmall;

  const FieldTypeIndicator({
    super.key,
    required this.fieldType,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmall ? 24 : 28,
      height: isSmall ? 24 : 28,
      decoration: BoxDecoration(
        color: FieldTypeService.getFieldTypeColor(fieldType),
        shape: BoxShape.circle,
      ),
      child: Icon(
        FieldTypeService.getFieldTypeIcon(fieldType),
        color: Colors.white,
        size: isSmall ? 12 : 14,
      ),
    );
  }
}