import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../controllers/pdf_preview_controller.dart';

/// Core PDF viewer widget with form field interactions
class PDFViewerWidget extends StatelessWidget {
  final PdfPreviewController controller;

  const PDFViewerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: controller.pdfViewerContainerKey,
      color: Colors.grey[300],
      child: Stack(
        children: [
          SfPdfViewer.file(
            File(controller.currentPdfPath),
            key: controller.pdfViewerKey,
            controller: controller.pdfController,
            enableDoubleTapZooming: true,
            enableTextSelection: false,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (details) {
              // Document loaded successfully
            },
            onDocumentLoadFailed: (details) {
              _showErrorDialog(context, 'Failed to load PDF: ${details.error}');
            },
            onFormFieldValueChanged: (details) {
              // Handle form field changes if needed
              _handleFormFieldChange(details);
            },
          ),
          if (controller.showEditingTools)
            _buildFormFieldOverlay(),
        ],
      ),
    );
  }

  Widget _buildFormFieldOverlay() {
    if (controller.formFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: controller.formFields.map((field) {
        return Positioned(
          left: field.bounds.left,
          top: field.bounds.top,
          width: field.bounds.width,
          height: field.bounds.height,
          child: _buildFieldOverlay(field),
        );
      }).toList(),
    );
  }

  Widget _buildFieldOverlay(dynamic field) {
    return GestureDetector(
      onTap: () => _handleFieldTap(field),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.5),
            width: 2,
          ),
          color: Colors.blue.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Icon(
            Icons.edit,
            color: Colors.blue.withValues(alpha: 0.7),
            size: 16,
          ),
        ),
      ),
    );
  }

  void _handleFieldTap(dynamic field) {
    // Handle field tap for editing
    if (field.name != null && field.name.isNotEmpty) {
      final currentValue = controller.getCurrentFieldValue(field.name);
      controller.dialogManager.showEditDialog(field.name, currentValue);
    }
  }

  void _handleFormFieldChange(PdfFormFieldValueChangedDetails details) {
    // Handle form field value changes
    if (details.formField.name.isNotEmpty) {
      controller.editingController.updateField(
        details.formField.name,
        details.newValue.toString(),
      );
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Exit PDF preview
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    });
  }
}