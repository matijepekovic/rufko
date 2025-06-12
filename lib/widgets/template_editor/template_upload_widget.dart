import 'package:flutter/material.dart';

class TemplateUploadWidget extends StatelessWidget {
  final VoidCallback onUpload;

  const TemplateUploadWidget({super.key, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Upload PDF to Start', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Upload a PDF form. The system will detect its fillable fields.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose PDF File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

