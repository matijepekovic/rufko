import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../controllers/inspection_viewer_controller.dart';
import '../widgets/inspection_viewer/empty_state_widget.dart';
import '../widgets/inspection_viewer/document_view_widget.dart';
import '../widgets/inspection_viewer/navigation_buttons_widget.dart';
import '../widgets/inspection_viewer/page_indicator_widget.dart';

class InspectionViewerScreen extends StatefulWidget {
  final Customer customer;
  final int? initialIndex;

  const InspectionViewerScreen({
    super.key,
    required this.customer,
    this.initialIndex,
  });

  @override
  State<InspectionViewerScreen> createState() => _InspectionViewerScreenState();
}

class _InspectionViewerScreenState extends State<InspectionViewerScreen> {
  late InspectionViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InspectionViewerController(
      context: context,
      customer: widget.customer,
      initialIndex: widget.initialIndex ?? 0,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _controller.documents.isEmpty
          ? const EmptyStateWidget()
          : _buildDocumentViewer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspection Documents',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            widget.customer.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        if (_controller.documents.isNotEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_controller.currentPage + 1} / ${_controller.documents.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentViewer() {
    return Stack(
      children: [
        // Document viewer
        PageView.builder(
          controller: _controller.pageController,
          itemCount: _controller.documents.length,
          onPageChanged: _controller.updateCurrentPage,
          itemBuilder: (context, index) {
            final document = _controller.documents[index];
            return DocumentViewWidget(document: document);
          },
        ),

        // Navigation buttons overlay
        NavigationButtonsWidget(
          currentPage: _controller.currentPage,
          totalPages: _controller.documents.length,
          onPrevious: _controller.goToPreviousPage,
          onNext: _controller.goToNextPage,
        ),

        // Page indicator
        PageIndicatorWidget(
          documents: _controller.documents,
          currentPage: _controller.currentPage,
          onPageTap: _controller.goToPage,
        ),
      ],
    );
  }
}