import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../data/models/ui/pdf_form_field.dart';
import 'pdf_editing_controller.dart';

class PdfViewerUIBuilder {
  PdfViewerUIBuilder(this.context,
      {required this.pdfViewerKey,
      required this.pdfController,
      required this.editingController,
      required this.getCurrentFieldValue,
      required this.showTemplateFieldEditDialog});

  final BuildContext context;
  final GlobalKey<SfPdfViewerState> pdfViewerKey;
  final PdfViewerController pdfController;
  final PdfEditingController editingController;
  final String Function(String fieldName) getCurrentFieldValue;
  final void Function(String fieldName, String currentValue)
      showTemplateFieldEditDialog;

  Widget buildStatusBar({
    required bool hasEdits,
    required bool isLoadingFields,
    required List<PDFFormField> formFields,
    required VoidCallback discardEdits,
  }) {
    return Container(
      color: hasEdits
          ? Colors.orange.shade100
          : (isLoadingFields ? Colors.blue.shade100 : Colors.grey.shade100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (isLoadingFields) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Text('Loading form fields...', style: TextStyle(fontSize: 12)),
          ] else ...[
              Icon(
                hasEdits ? Icons.edit : Icons.touch_app,
                size: 16,
                color:
                    hasEdits ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasEdits
                    ? '${editingController.editedValues.length} fields edited - direct PDF mapping active'
                    : formFields.isNotEmpty
                        ? '${formFields.length} form fields detected - click directly to edit'
                        : 'No editable form fields detected',
                style: TextStyle(
                  fontSize: 12,
                  color: hasEdits ? Colors.orange.shade800 : Colors.blue.shade800,
                ),
              ),
            ),
          ],
          if (hasEdits)
            TextButton(
              onPressed: discardEdits,
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPdfViewerWithOverlays({
    required String currentPdfPath,
    required bool showEditingTools,
    required VoidCallback exitTemplateMode,
    required Widget Function(String fieldName, String displayName) quickEditButton,
  }) {
    final file = File(currentPdfPath);

    if (!file.existsSync()) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'PDF file not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The PDF file may have been moved or deleted.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.file(
          file,
          key: pdfViewerKey,
          controller: pdfController,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          onFormFieldValueChanged: (PdfFormFieldValueChangedDetails details) {
            final fieldName = details.formField.name;
            final newValue = details.newValue?.toString() ?? '';
            final oldValue = details.oldValue?.toString() ?? '';

            if (kDebugMode) {
              debugPrint('📝 Direct field edit: "$fieldName" = "$newValue"');
            }

            editingController.addEdit(fieldName, oldValue, newValue);
          },
        ),
        if (showEditingTools)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.orange.shade600.withAlpha((0.9 * 255).round()),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Template Edit Mode: Use buttons below to edit template fields',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: exitTemplateMode,
                    child: const Text(
                      'Exit Template Mode',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (showEditingTools)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withAlpha((0.1 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Quick Edit Template Fields:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      quickEditButton('customerName', 'Customer Name'),
                      quickEditButton('customerPhone', 'Phone'),
                      quickEditButton('customerEmail', 'Email'),
                      quickEditButton('notes', 'Notes'),
                      quickEditButton('terms', 'Terms'),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget buildQuickEditButton(String fieldName, String displayName) {
    final hasEdit = editingController.editedValues.containsKey(fieldName);

    return OutlinedButton.icon(
      onPressed: () {
        final currentValue =
            editingController.editedValues[fieldName] ??
                getCurrentFieldValue(fieldName);
        showTemplateFieldEditDialog(fieldName, currentValue);
      },
      icon: Icon(
        hasEdit ? Icons.edit : Icons.edit_outlined,
        size: 16,
        color: hasEdit ? Colors.green : null,
      ),
      label: Text(
        displayName,
        style: TextStyle(
          color: hasEdit ? Colors.green : null,
          fontWeight: hasEdit ? FontWeight.bold : null,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: hasEdit ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
