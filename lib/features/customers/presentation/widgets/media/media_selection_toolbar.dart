import 'package:flutter/material.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

class MediaSelectionToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final bool isDeleteEnabled;

  const MediaSelectionToolbar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onDelete,
    required this.onCancel,
    required this.isDeleteEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '$selectedCount selected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            RufkoTextButton(
              onPressed: onSelectAll,
              size: ButtonSize.small,
              child: const Text(
                'Select All',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            RufkoTextButton(
              onPressed: isDeleteEnabled ? onDelete : null,
              icon: Icons.delete,
              size: ButtonSize.small,
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCancel,
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}