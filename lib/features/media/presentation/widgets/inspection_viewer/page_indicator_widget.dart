import 'package:flutter/material.dart';
import '../../../../../data/models/media/inspection_document.dart';

/// Page indicator widget showing current document and navigation dots
class PageIndicatorWidget extends StatelessWidget {
  final List<InspectionDocument> documents;
  final int currentPage;
  final Function(int) onPageTap;

  const PageIndicatorWidget({
    super.key,
    required this.documents,
    required this.currentPage,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.length <= 1) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Document type and title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                documents[currentPage].displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                documents.length,
                (index) => GestureDetector(
                  onTap: () => onPageTap(index),
                  child: Container(
                    width: index == currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == currentPage
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}