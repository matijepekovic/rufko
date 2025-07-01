import 'package:flutter/material.dart';
import '../customer_edit_dialog.dart';
import '../../controllers/customer_actions_ui_controller.dart';
import 'customer_delete_dialog.dart';
import 'customer_quick_actions_sheet.dart';

/// Widget that handles UI actions for customer operations
/// Separates UI concerns from business logic by managing dialogs and navigation
class CustomerActionsHandler extends StatefulWidget {
  final CustomerActionsUIController controller;
  final Widget child;
  final VoidCallback? onNavigateToCreateQuote;
  final VoidCallback? onShowCommunication;
  final VoidCallback? onNavigateBack;

  const CustomerActionsHandler({
    super.key,
    required this.controller,
    required this.child,
    this.onNavigateToCreateQuote,
    this.onShowCommunication,
    this.onNavigateBack,
  });

  @override
  State<CustomerActionsHandler> createState() => _CustomerActionsHandlerState();

  /// Static method to access handler methods
  static CustomerActionsHandler? of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<CustomerActionsHandler>();
  }
}

class _CustomerActionsHandlerState extends State<CustomerActionsHandler> {
  /// Expose methods for backward compatibility
  void showEditDialog() => _showEditDialog();
  void showDeleteDialog() => _showDeleteDialog();
  void showQuickActions() => _showQuickActions();
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
              backgroundColor: successMessage.contains('deleted') 
                  ? Colors.red 
                  : Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.controller.clearMessages();
          
          // Navigate back if customer was deleted
          if (successMessage.contains('deleted')) {
            widget.onNavigateBack?.call();
          }
        }
      });
    }
  }

  /// Show edit customer dialog
  void _showEditDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomerEditDialog(
        customer: widget.controller.customer,
        onCustomerUpdated: widget.controller.onCustomerUpdated,
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerDeleteDialog(
        customer: widget.controller.customer,
        onConfirm: () => widget.controller.deleteCustomer(context),
      ),
    );
  }

  /// Show quick actions bottom sheet
  void _showQuickActions() {
    widget.controller.loadCustomerStats(context);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => CustomerQuickActionsSheet(
        customer: widget.controller.customer,
        customerStats: widget.controller.customerStats,
        onEditCustomer: () {
          Navigator.pop(context);
          _showEditDialog();
        },
        onDeleteCustomer: () {
          Navigator.pop(context);
          _showDeleteDialog();
        },
        onCreateQuote: () {
          Navigator.pop(context);
          widget.onNavigateToCreateQuote?.call();
        },
        onShowCommunication: () {
          Navigator.pop(context);
          widget.onShowCommunication?.call();
        },
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
            if (widget.controller.isLoading)
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
}