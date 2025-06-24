import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/media/inspection_document.dart';

/// Reusable component for displaying inspection documents (notes and PDFs)
/// Extracted from InspectionTab for better maintainability
class InspectionDocumentsSection extends StatelessWidget {
  final List<InspectionDocument> documents;
  final VoidCallback onAddNote;
  final VoidCallback onAddPdf;
  final Function(String) onDeleteDocument;
  final Function(InspectionDocument) onEditNote;

  const InspectionDocumentsSection({
    super.key,
    required this.documents,
    required this.onAddNote,
    required this.onAddPdf,
    required this.onDeleteDocument,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 16),
            if (documents.isEmpty)
              _buildEmptyState()
            else
              _buildDocumentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Inspection Documents',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No inspection documents yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add notes or PDF documents to document your inspection findings',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    final notes = documents.where((doc) => doc.isNote).toList();
    final pdfs = documents.where((doc) => !doc.isNote).toList();

    return Column(
      children: [
        if (notes.isNotEmpty) ...[
          _buildDocumentCategory('Notes', notes, Icons.note, Colors.blue),
          const SizedBox(height: 16),
        ],
        if (pdfs.isNotEmpty) ...[
          _buildDocumentCategory('PDF Documents', pdfs, Icons.picture_as_pdf, Colors.red),
        ],
      ],
    );
  }

  Widget _buildDocumentCategory(String title, List<InspectionDocument> docs, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$title (${docs.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...docs.map((doc) => _buildDocumentTile(doc, color)),
      ],
    );
  }

  Widget _buildDocumentTile(InspectionDocument document, Color themeColor) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.05),
        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: document.isNote ? null : () => _viewDocument(document),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  document.isNote ? Icons.note : Icons.picture_as_pdf,
                  size: 16,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: themeColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
                  onSelected: (action) => _handleDocumentAction(action, document),
                  itemBuilder: (context) => [
                    if (document.isNote)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (!document.isNote)
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 16),
                            SizedBox(width: 8),
                            Text('Open'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(document.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            if (document.isNote && (document.content?.isNotEmpty == true)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                width: double.infinity,
                child: Text(
                  (document.content?.length ?? 0) > 100
                      ? '${document.content!.substring(0, 100)}...'
                      : document.content ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            if (!document.isNote && (document.fileSizeBytes ?? 0) > 0) ...[
              const SizedBox(height: 4),
              Text(
                _formatFileSize(document.fileSizeBytes ?? 0),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleDocumentAction(String action, InspectionDocument document) {
    switch (action) {
      case 'edit':
        if (document.isNote) {
          onEditNote(document);
        }
        break;
      case 'view':
        if (!document.isNote) {
          _viewDocument(document);
        }
        break;
      case 'delete':
        onDeleteDocument(document.id);
        break;
    }
  }

  void _viewDocument(InspectionDocument document) {
    // This would typically navigate to a document viewer
    // For now, we'll just show the inspection viewer screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => InspectionViewerScreen(document: document),
    //   ),
    // );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}