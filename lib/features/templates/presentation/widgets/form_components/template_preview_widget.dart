import 'package:flutter/material.dart';

/// Widget for displaying template preview
/// Extracted from EmailTemplateEditorScreen for reusability
class TemplatePreviewWidget extends StatelessWidget {
  final String subject;
  final String content;
  final bool isHtml;

  const TemplatePreviewWidget({
    super.key,
    required this.subject,
    required this.content,
    this.isHtml = false,
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
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildPreview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.preview, color: Colors.orange.shade600, size: 18),
        const SizedBox(width: 6),
        Text(
          'Preview',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (subject.isEmpty && content.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          'Enter content to see preview',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subject.isNotEmpty) ...[
            Text(
              'Subject: $subject',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}