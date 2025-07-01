import 'package:flutter/material.dart';
import '../../controllers/quote_detail_ui_controller.dart';

/// Widget that handles UI concerns for quote detail operations
/// Separates UI concerns from business logic by managing dialogs, snackbars, and navigation
class QuoteDetailHandler extends StatefulWidget {
  final QuoteDetailUIController controller;
  final Widget child;

  const QuoteDetailHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<QuoteDetailHandler> createState() => _QuoteDetailHandlerState();
}

class _QuoteDetailHandlerState extends State<QuoteDetailHandler> {
  /// Public methods for backward compatibility and external access
  Future<void> updateQuoteStatus() => _showStatusUpdateDialog();
  Future<void> deleteQuote() => _showDeleteConfirmationDialog();
  void handleMenuAction(String action) => _handleMenuAction(action);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanges);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanges);
    super.dispose();
  }

  void _handleControllerChanges() {
    // Handle error messages
    final errorMessage = widget.controller.lastError;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }

    // Handle success messages
    final successMessage = widget.controller.lastSuccess;
    if (successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }
  }

  /// Show status update dialog
  Future<void> _showStatusUpdateDialog() async {
    final selectedStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Quote Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.controller.availableStatuses
              .map((status) => ListTile(
                    title: Text(status.toUpperCase()),
                    selected: status == widget.controller.quote.status,
                    onTap: () => Navigator.of(context).pop(status),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedStatus != null && mounted) {
      await widget.controller.updateQuoteStatus(selectedStatus);
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text(
          'Are you sure you want to delete quote ${widget.controller.quote.quoteNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.deleteQuote();
      if (success && mounted) {
        // Navigate back to previous screen after successful deletion
        Navigator.of(context).pop();
      }
    }
  }

  /// Show quick status update snackbar
  void _showQuickStatusUpdate() {
    final nextStatus = widget.controller.getNextLogicalStatus();
    if (nextStatus == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update status to ${nextStatus.toUpperCase()}?'),
        action: SnackBarAction(
          label: 'Update',
          onPressed: () => widget.controller.updateQuoteStatus(nextStatus),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'generate_pdf':
        _generatePdf();
        break;
      case 'rename':
        _showRenameDialog();
        break;
      case 'delete':
        _showDeleteConfirmationDialog();
        break;
      case 'quick_status_update':
        _showQuickStatusUpdate();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not implemented: $action')),
        );
        break;
    }
  }

  /// Show rename dialog (placeholder)
  void _showRenameDialog() {
    final controller = TextEditingController(text: widget.controller.quote.quoteNumber);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Quote'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Quote Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement rename functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rename functionality not implemented yet')),
              );
              controller.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            if (widget.controller.isProcessing)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Generate PDF using UI controller
  Future<void> _generatePdf() async {
    // Delegate to UI controller - it will handle success/error states
    // The screen should listen to controller changes for navigation
    await widget.controller.generatePdf(context: context);
  }
}