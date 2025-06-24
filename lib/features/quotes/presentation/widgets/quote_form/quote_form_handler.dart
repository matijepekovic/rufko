import 'package:flutter/material.dart';
import '../../controllers/quote_form_controller.dart';
import '../../controllers/quote_form_ui_controller.dart';
import '../../screens/simplified_quote_detail_screen.dart';
import '../dialogs/tax_rate_dialogs.dart';

/// Widget that handles UI concerns for quote form operations
/// Separates UI concerns from business logic by managing dialogs, snackbars, and navigation
class QuoteFormHandler extends StatefulWidget {
  final QuoteFormUIController controller;
  final Widget child;

  const QuoteFormHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<QuoteFormHandler> createState() => _QuoteFormHandlerState();
}

class _QuoteFormHandlerState extends State<QuoteFormHandler> {
  /// Public methods for backward compatibility and external access
  Future<void> autoDetectTaxRate() => _autoDetectTaxRate();
  Future<void> generateQuote(GlobalKey<FormState> formKey) => _generateQuote(formKey);

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
    if (widget.controller.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final error = widget.controller.lastError!;
          
          // Special handling for manual tax rate entry
          if (error == 'Manual tax rate entry required') {
            _showManualTaxRateDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          
          widget.controller.clearMessages();
        }
      });
    }

    // Handle success messages
    if (widget.controller.lastSuccess != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final success = widget.controller.lastSuccess!;
          Color backgroundColor = Colors.green;
          
          // Use orange for fallback/default tax rates
          if (success.contains('default tax rate')) {
            backgroundColor = Colors.orange;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success),
              backgroundColor: backgroundColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }
  }

  /// Auto-detect tax rate with manual fallback
  Future<void> _autoDetectTaxRate() async {
    await widget.controller.autoDetectTaxRate();
    // The controller will handle success/error states automatically
    // Manual tax rate dialog will be triggered via error handling if needed
  }

  /// Generate quote with validation and navigation
  Future<void> _generateQuote(GlobalKey<FormState> formKey) async {
    // Validate form
    if (!(formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.isEditMode
              ? 'Please fix errors before updating quote'
              : 'Please fix errors before generating quote'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generate quote
    final quote = await widget.controller.generateQuote();
    
    if (quote != null && mounted) {
      // Navigate to quote detail screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SimplifiedQuoteDetailScreen(
            quote: quote,
            customer: widget.controller.customer,
          ),
        ),
      );
    }
  }

  /// Show manual tax rate dialog
  void _showManualTaxRateDialog() {
    // Create a QuoteFormController wrapper for compatibility
    final wrapperController = QuoteFormController(
      context: context,
      customer: widget.controller.customer,
    );
    
    // Sync the tax rate from UI controller to wrapper
    wrapperController.taxRate = widget.controller.taxRate;
    
    TaxRateDialogs.showManualTaxRateDialog(
      context,
      widget.controller.customer,
      wrapperController,
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
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        widget.controller.isEditMode
                            ? 'Updating quote...'
                            : 'Generating quote...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

