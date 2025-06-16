import 'package:flutter/material.dart';
import '../../controllers/pdf_preview_controller.dart';

/// App bar widget for PDF preview screen
class PDFPreviewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PdfPreviewController controller;
  final VoidCallback? onToggleEditingTools;

  const PDFPreviewAppBar({
    super.key,
    required this.controller,
    this.onToggleEditingTools,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(controller.title ?? 'PDF Preview'),
      backgroundColor: Colors.black87,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final canPop = await controller.handleBackNavigation();
          if (canPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        if (controller.templateId != null && !controller.isPreview)
          IconButton(
            icon: Icon(
              controller.showEditingTools ? Icons.edit_off : Icons.edit,
              color: controller.showEditingTools ? Colors.orange : Colors.white,
            ),
            onPressed: onToggleEditingTools,
            tooltip: controller.showEditingTools ? 'Hide Editing Tools' : 'Show Editing Tools',
          ),
        if (controller.hasEdits)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: controller.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.green),
              onPressed: controller.isSaving ? null : controller.savePdf,
              tooltip: 'Save Changes',
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) async {
            switch (value) {
              case 'save':
                await controller.savePdf();
                break;
              case 'share':
                await controller.sharePdf();
                break;
              case 'info':
                _showPdfInfo(context);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!controller.isPreview)
              const PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Save PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share PDF'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('PDF Info'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPdfInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('File:', controller.suggestedFileName),
            if (controller.customer != null)
              _buildInfoRow('Customer:', controller.customer!.name),
            if (controller.quote != null)
              _buildInfoRow('Quote:', 'Quote #${controller.quote!.quoteNumber}'),
            if (controller.templateId != null)
              _buildInfoRow('Template:', controller.templateId!),
            _buildInfoRow('Editable Fields:', '${controller.editableFields.length}'),
            _buildInfoRow('Form Fields:', '${controller.formFields.length}'),
            if (controller.hasEdits)
              const Text(
                '⚠️ Contains unsaved changes',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}