import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../editor/mapping_mode_banner.dart';
import '../editor/pdf_viewer_widget.dart';

/// Reusable PDF viewer section for template editor
/// Combines mapping banner and PDF viewer with interaction handling
class TemplatePdfViewerSection extends StatelessWidget {
  final File? pdfFile;
  final PdfViewerController controller;
  final Function(PdfGestureDetails) onTap;
  final Function(int) onPageChanged;

  const TemplatePdfViewerSection({
    super.key,
    required this.pdfFile,
    required this.controller,
    required this.onTap,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (pdfFile == null) {
      return const Center(
        child: Text('No PDF loaded. Upload a template to begin.'),
      );
    }

    return Column(
      children: [
        const MappingModeBanner(),
        Expanded(
          child: PdfViewerWidget(
            pdfFile: pdfFile!,
            controller: controller,
            onTap: onTap,
            onPageChanged: onPageChanged,
          ),
        ),
      ],
    );
  }
}