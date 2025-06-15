import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/templates/email_template.dart';

/// Reusable email template tile widget
/// Extracted from EmailTemplatesTab for better maintainability
class EmailTemplateTile extends StatelessWidget {
  final EmailTemplate template;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isVerySmall;
  final Color primaryColor;
  final IconData tabIcon;
  final VoidCallback onTap;
  final Function(String action, EmailTemplate template) onAction;

  const EmailTemplateTile({
    super.key,
    required this.template,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isVerySmall,
    required this.primaryColor,
    required this.tabIcon,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

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
              : const Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: Row(
          children: [
            _buildStatusIndicator(),
            SizedBox(width: isVerySmall ? 8 : 12),
            _buildTemplateInfo(dateFormat),
            _buildActionSection(),
          ],
        ),
      ),
    );
  }

  /// Build active status indicator
  Widget _buildStatusIndicator() {
    return Container(
      width: isVerySmall ? 24 : 28,
      height: isVerySmall ? 24 : 28,
      decoration: BoxDecoration(
        color: template.isActive ? primaryColor : Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Icon(
        tabIcon,
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
          _buildTemplateName(),
          SizedBox(height: isVerySmall ? 2 : 3),
          _buildDescriptionAndDate(dateFormat),
          if (template.subject.isNotEmpty || template.emailContent.isNotEmpty)
            _buildContentPreview(),
          if (template.isHtml)
            _buildHtmlIndicator(),
        ],
      ),
    );
  }

  /// Build template name
  Widget _buildTemplateName() {
    return Text(
      template.templateName,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: isVerySmall ? 13 : 14,
        color: isSelected ? primaryColor : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build description and date row
  Widget _buildDescriptionAndDate(DateFormat dateFormat) {
    return Row(
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
    );
  }

  /// Build content preview section
  Widget _buildContentPreview() {
    return Padding(
      padding: EdgeInsets.only(top: isVerySmall ? 2 : 3),
      child: Container(
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
          template.subject.isNotEmpty
              ? 'Subject: ${template.subject.length > 30 ? '${template.subject.substring(0, 30)}...' : template.subject}'
              : template.emailContent.length > 50
              ? '${template.emailContent.substring(0, 50)}...'
              : template.emailContent,
          style: TextStyle(
            fontSize: isVerySmall ? 9 : 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Build HTML indicator
  Widget _buildHtmlIndicator() {
    return Padding(
      padding: EdgeInsets.only(top: isVerySmall ? 2 : 3),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmall ? 3 : 4,
          vertical: isVerySmall ? 1 : 1,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'HTML',
          style: TextStyle(
            fontSize: isVerySmall ? 8 : 9,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  /// Build action section (selection indicator or menu)
  Widget _buildActionSection() {
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
    }

    return PopupMenuButton<String>(
      onSelected: (action) => onAction(action, template),
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
          value: 'test_send',
          child: Row(
            children: [
              Icon(Icons.send, size: 16),
              SizedBox(width: 8),
              Text('Test Send'),
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
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Duplicate'),
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