import 'package:flutter/material.dart';

/// Widget for displaying detected placeholders in templates
/// Extracted from EmailTemplateEditorScreen for reusability
class PlaceholderDisplayWidget extends StatelessWidget {
  final List<String> placeholders;
  final bool showHeader;
  final Color? themeColor;

  const PlaceholderDisplayWidget({
    super.key,
    required this.placeholders,
    this.showHeader = true,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildHeader(context),
            if (showHeader) const SizedBox(height: 8),
            _buildPlaceholderChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final color = themeColor ?? Colors.orange.shade600;
    return Row(
      children: [
        Icon(Icons.data_object, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          'Fields (${placeholders.length})',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderChips() {
    final color = themeColor ?? Colors.orange.shade600;
    
    if (placeholders.isEmpty) {
      return Text(
        'No fields detected',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: placeholders.map((placeholder) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.data_object, size: 12, color: color),
              const SizedBox(width: 2),
              Text(
                '{$placeholder}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}