import 'package:flutter/material.dart';

import '../../../../../data/models/settings/custom_app_data.dart';

/// Reusable field action menu widget
/// Provides edit and delete actions for field items
class FieldActionMenu extends StatelessWidget {
  final CustomAppDataField field;
  final bool isVerySmall;
  final Function(String action, CustomAppDataField field) onAction;

  const FieldActionMenu({
    super.key,
    required this.field,
    required this.isVerySmall,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (action) => onAction(action, field),
      icon: Icon(
        Icons.more_vert,
        size: isVerySmall ? 16 : 18,
        color: Colors.grey[600],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}