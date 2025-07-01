import 'package:flutter/material.dart';

/// Reusable error handling widget for media operations
/// Extracted from MediaTabController for better maintainability
class MediaErrorHandler extends StatelessWidget {
  final String? error;
  final VoidCallback onClearError;

  const MediaErrorHandler({
    super.key,
    required this.error,
    required this.onClearError,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    // Show error as snackbar when error appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: onClearError,
            ),
          ),
        );
        onClearError();
      }
    });

    return const SizedBox.shrink();
  }

  /// Static method to show error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Static method to show success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}