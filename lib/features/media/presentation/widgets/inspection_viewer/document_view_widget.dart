import 'package:flutter/material.dart';
import '../../../../../data/models/media/inspection_document.dart';
import 'note_view_widget.dart';
import 'pdf_view_widget.dart';

/// Widget for displaying different types of inspection documents
class DocumentViewWidget extends StatelessWidget {
  final InspectionDocument document;

  const DocumentViewWidget({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    if (document.isNote) {
      return NoteViewWidget(document: document);
    } else if (document.isPdf) {
      return PdfViewWidget(document: document);
    } else {
      return _buildErrorView('Unknown document type');
    }
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