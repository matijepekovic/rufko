import 'package:flutter/material.dart';
import '../../../../../data/models/templates/pdf_template.dart';
import '../../../../../core/utils/helpers/pdf_field_utils.dart';

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
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.green.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDF Field: ${formatPdfFieldName(pdfFieldName)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (currentMapping != null && currentMapping!.pdfFormFieldName.isNotEmpty)
                      Text(
                        'Linked to: ${PDFTemplate.getFieldDisplayName(currentMapping!.appDataType)}',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (currentMapping != null && currentMapping!.pdfFormFieldName.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onUnlink?.call();
                },
                icon: const Icon(Icons.link_off),
                label: const Text('Unlink Field'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onChangeMapping,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Change Mapping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: content,
      ),
    );
  }
}
