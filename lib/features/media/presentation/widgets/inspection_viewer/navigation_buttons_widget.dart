import 'package:flutter/material.dart';

/// Navigation buttons overlay for document navigation
class NavigationButtonsWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const NavigationButtonsWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Stack(
      children: [
        // Left navigation button
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: currentPage > 0 ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: currentPage > 0 ? onPrevious : null,
                  tooltip: 'Previous document',
                ),
              ),
            ),
          ),
        ),

        // Right navigation button
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: currentPage < totalPages - 1 ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: currentPage < totalPages - 1 ? onNext : null,
                  tooltip: 'Next document',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}