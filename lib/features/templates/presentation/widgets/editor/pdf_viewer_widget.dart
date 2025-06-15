import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerWidget extends StatefulWidget {
  final File pdfFile;
  final PdfViewerController controller;
  final void Function(PdfGestureDetails)? onTap;
  final ValueChanged<int>? onPageChanged;

  const PdfViewerWidget({
    super.key,
    required this.pdfFile,
    required this.controller,
    this.onTap,
    this.onPageChanged,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  int _currentPageZeroBased = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (!mounted) return;
    final page = widget.controller.pageNumber;
    if (page > 0 && (page - 1) != _currentPageZeroBased) {
      setState(() {
        _currentPageZeroBased = page - 1;
      });
      widget.onPageChanged?.call(_currentPageZeroBased);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SfPdfViewer.file(
              widget.pdfFile,
              controller: widget.controller,
              initialZoomLevel: 0,
              enableDocumentLinkAnnotation: false,
              enableTextSelection: false,
              onDocumentLoaded: (details) {
                setState(() => _totalPages = details.document.pages.count);
              },
              onTap: widget.onTap,
            ),
          ),
        ),
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  tooltip: 'First Page',
                  iconSize: 20,
                  onPressed: _currentPageZeroBased > 0
                      ? () => widget.controller.jumpToPage(1)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Page',
                  iconSize: 20,
                  onPressed: _currentPageZeroBased > 0
                      ? () => widget.controller.previousPage()
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Page ${_currentPageZeroBased + 1} of $_totalPages',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Page',
                  iconSize: 20,
                  onPressed: _currentPageZeroBased < _totalPages - 1
                      ? () => widget.controller.nextPage()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  tooltip: 'Last Page',
                  iconSize: 20,
                  onPressed: _currentPageZeroBased < _totalPages - 1
                      ? () => widget.controller.jumpToPage(_totalPages)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

