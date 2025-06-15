import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/templates/pdf_template.dart';

/// Reusable template tile widget
/// Extracted from PdfTemplatesTab for better maintainability
class PdfTemplateTile extends StatelessWidget {
  final PDFTemplate template;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isSmallScreen;
  final bool isVerySmall;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Function(String action) onActionSelected;

  const PdfTemplateTile({
    super.key,
    required this.template,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isSmallScreen,
    required this.isVerySmall,
    required this.primaryColor,
    required this.onTap,
    this.onLongPress,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmall ? 8 : 12,
          vertical: isVerySmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
          border: isSelected
              ? Border.all(color: primaryColor, width: 1)
              : const Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: Row(
          children: [
            _buildActiveStatusIndicator(),
            SizedBox(width: isVerySmall ? 8 : 12),
            _buildTemplateInfo(dateFormat),
            _buildTrailingWidget(),
          ],
        ),
      ),
    );
  }

  /// Build active status indicator
  Widget _buildActiveStatusIndicator() {
    return Container(
      width: isVerySmall ? 24 : 28,
      height: isVerySmall ? 24 : 28,
      decoration: BoxDecoration(
        color: template.isActive ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Icon(
        template.isActive ? Icons.check : Icons.close,
        color: Colors.white,
        size: isVerySmall ? 12 : 14,
      ),
    );
  }

  /// Build template information section
  Widget _buildTemplateInfo(DateFormat dateFormat) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.templateName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isVerySmall ? 13 : 14,
              color: isSelected ? primaryColor : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isVerySmall ? 2 : 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  template.description.isNotEmpty
                      ? template.description
                      : 'No description',
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
                dateFormat.format(template.updatedAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: isVerySmall ? 9 : 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (template.userCategoryKey != null && template.userCategoryKey!.isNotEmpty) ...[
            SizedBox(height: isVerySmall ? 2 : 3),
            Container(
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
                'Category: ${template.userCategoryKey}',
                style: TextStyle(
                  fontSize: isVerySmall ? 9 : 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build trailing widget (selection indicator or menu)
  Widget _buildTrailingWidget() {
    if (isSelectionMode) {
      return Container(
        width: isVerySmall ? 20 : 24,
        height: isVerySmall ? 20 : 24,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isSelected
            ? Icon(Icons.check, color: Colors.white, size: isVerySmall ? 12 : 14)
            : null,
      );
    } else {
      return PopupMenuButton<String>(
        onSelected: onActionSelected,
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
            value: 'preview',
            child: Row(
              children: [
                Icon(Icons.preview, size: 16),
                SizedBox(width: 8),
                Text('Preview'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle_active',
            child: Row(
              children: [
                Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(template.isActive ? 'Deactivate' : 'Activate'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16),
                SizedBox(width: 8),
                Text('Rename'),
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
}