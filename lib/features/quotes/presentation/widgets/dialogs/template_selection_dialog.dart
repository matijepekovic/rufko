import 'package:flutter/material.dart';

import '../../../../../data/models/templates/pdf_template.dart';

class TemplateSelectionDialog extends StatelessWidget {
  final List<PDFTemplate> templates;
  final Function(PDFTemplate) onPreviewTemplate;

  const TemplateSelectionDialog({
    super.key,
    required this.templates,
    required this.onPreviewTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose PDF Generation Method'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you like to generate the PDF?',
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text('Standard PDF'),
                subtitle: const Text('Use the built-in PDF format'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pop(context, 'standard'),
              ),
            ),
            if (templates.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Custom Templates (${templates.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  )),
              const SizedBox(height: 8),
              ...templates.map(
                (template) => Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(template.templateName),
                    subtitle: template.description.isNotEmpty
                        ? Text(template.description)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.preview, size: 20),
                          onPressed: () => onPreviewTemplate(template),
                          tooltip: 'Preview template',
                        ),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, template.id),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(height: 8),
                    Text('No custom templates available',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        )),
                    const SizedBox(height: 4),
                    Text('Create templates in Settings → PDF Templates',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancelled'),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 'standard'),
          child: const Text('Use Standard PDF'),
        ),
      ],
    );
  }
}
