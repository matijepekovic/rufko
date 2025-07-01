import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../controllers/pdf_file_operations_ui_controller.dart';
import '../../../../../data/models/business/customer.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/ui/pdf_form_field.dart';

/// Widget that handles UI concerns for PDF file operations
/// Separates UI concerns from business logic by managing navigation, snackbars, and file operations
class PdfFileOperationsHandler extends StatefulWidget {
  final PdfFileOperationsUIController controller;
  final Widget child;

  const PdfFileOperationsHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<PdfFileOperationsHandler> createState() => _PdfFileOperationsHandlerState();
}

class _PdfFileOperationsHandlerState extends State<PdfFileOperationsHandler> {
  /// Public methods for backward compatibility and external access
  Future<void> savePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
  }) => _savePdf(
    currentPdfPath: currentPdfPath,
    editedValues: editedValues,
    formFields: formFields,
    suggestedFileName: suggestedFileName,
    customer: customer,
    quote: quote,
    templateId: templateId,
  );

  Future<void> sharePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    Future<void> Function({
      required File file,
      required String fileName,
      Customer? customer,
    })? shareFile,
  }) => _sharePdf(
    currentPdfPath: currentPdfPath,
    editedValues: editedValues,
    formFields: formFields,
    suggestedFileName: suggestedFileName,
    customer: customer,
    shareFile: shareFile,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanges);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanges);
    super.dispose();
  }

  void _handleControllerChanges() {
    // Handle error messages
    final errorMessage = widget.controller.lastError;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }

    // Handle success messages
    final successMessage = widget.controller.lastSuccess;
    if (successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              action: successMessage.contains('saved') &&
                      widget.controller.lastSavedFilePath != null
                  ? SnackBarAction(
                      label: 'Open',
                      textColor: Colors.white,
                      onPressed: () => _openFile(widget.controller.lastSavedFilePath!),
                    )
                  : null,
              duration: const Duration(seconds: 3), // Shorter duration for auto-navigation
            ),
          );
          
          // Auto-navigate back for save operations
          if (widget.controller.lastOperationType == 'save') {
            // Navigate back after a short delay to allow the snackbar to be seen
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          }
          
          widget.controller.clearMessages();
        }
      });
    }
  }

  /// Save PDF - navigation handled automatically by success callback
  Future<void> _savePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    SimplifiedMultiLevelQuote? quote,
    String? templateId,
  }) async {
    await widget.controller.savePdf(
      currentPdfPath: currentPdfPath,
      editedValues: editedValues,
      formFields: formFields,
      suggestedFileName: suggestedFileName,
      customer: customer,
      quote: quote,
      templateId: templateId,
    );
    // Navigation now handled automatically in _handleControllerChanges for save operations
  }

  /// Share PDF with file sharing
  Future<void> _sharePdf({
    required String currentPdfPath,
    required Map<String, String> editedValues,
    required List<PDFFormField> formFields,
    required String suggestedFileName,
    Customer? customer,
    Future<void> Function({
      required File file,
      required String fileName,
      Customer? customer,
    })? shareFile,
  }) async {
    await widget.controller.sharePdf(
      currentPdfPath: currentPdfPath,
      editedValues: editedValues,
      formFields: formFields,
      suggestedFileName: suggestedFileName,
      customer: customer,
      shareFileCallback: ({
        required String filePath,
        required String fileName,
        Customer? customer,
      }) async {
        if (shareFile != null) {
          await shareFile(
            file: File(filePath),
            fileName: fileName,
            customer: customer,
          );
        } else {
          // Default sharing behavior - open file
          await _openFile(filePath);
        }
      },
    );
  }

  /// Open file with system default application
  Future<void> _openFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
      widget.controller.openFile(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            if (widget.controller.isProcessing)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        widget.controller.isSaving 
                            ? 'Saving PDF...'
                            : 'Preparing PDF...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}