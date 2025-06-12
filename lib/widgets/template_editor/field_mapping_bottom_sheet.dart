import 'package:flutter/material.dart';
import '../../models/pdf_template.dart';

class FieldMappingBottomSheet extends StatelessWidget {
  final String pdfFieldName;
  final FieldMapping? currentMapping;
  final VoidCallback onChangeMapping;
  final VoidCallback? onUnlink;

  const FieldMappingBottomSheet({
    super.key,
    required this.pdfFieldName,
    this.currentMapping,
    required this.onChangeMapping,
    this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDF Field: $pdfFieldName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (currentMapping != null)
            Text(
                'Linked to: ${PDFTemplate.getFieldDisplayName(currentMapping!.appDataType)}'),
          const SizedBox(height: 24),
          if (currentMapping != null)
            ElevatedButton.icon(
              onPressed: onUnlink,
              icon: const Icon(Icons.link_off),
              label: const Text('Unlink Field'),
            ),
          ElevatedButton.icon(
            onPressed: onChangeMapping,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Change Mapping'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
