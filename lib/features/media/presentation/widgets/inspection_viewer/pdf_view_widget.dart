import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../../data/models/media/inspection_document.dart';

/// Widget for displaying PDF-type inspection documents
class PdfViewWidget extends StatelessWidget {
  final InspectionDocument document;

  const PdfViewWidget({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    if (document.filePath == null) {
      return _buildErrorView('PDF file path not found');
    }

    final file = File(document.filePath!);
    if (!file.existsSync()) {
      return _buildErrorView('PDF file not found on device');
    }

    return Column(
      children: [
        // PDF Header
        Container(
          color: Colors.grey.shade900,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.displayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (document.fileSizeBytes != null)
                      Text(
                        document.formattedFileSize,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // PDF Viewer
        Expanded(
          child: SfPdfViewer.file(
            file,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}