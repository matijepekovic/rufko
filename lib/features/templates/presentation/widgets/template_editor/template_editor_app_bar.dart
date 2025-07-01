import 'package:flutter/material.dart';

import '../../../../../data/models/templates/pdf_template.dart';
import '../../../../../app/theme/rufko_theme.dart';

/// Reusable app bar for template editor
/// Handles title display and action buttons (save, preview)
class TemplateEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PDFTemplate? currentTemplate;
  final VoidCallback? onSave;
  final VoidCallback? onPreview;

  const TemplateEditorAppBar({
    super.key,
    required this.currentTemplate,
    this.onSave,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_buildTitle()),
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: _buildActions(),
    );
  }

  /// Build dynamic title based on template state
  String _buildTitle() {
    return currentTemplate == null
        ? 'Create New Template'
        : 'Edit: ${currentTemplate?.templateName ?? "Template"}';
  }

  /// Build action buttons when template is loaded
  List<Widget> _buildActions() {
    if (currentTemplate == null) return [];
    
    return [
      if (onSave != null)
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
          tooltip: 'Save Template',
        ),
      if (onPreview != null)
        IconButton(
          icon: const Icon(Icons.preview),
          onPressed: onPreview,
          tooltip: 'Preview (with sample data)',
        ),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}