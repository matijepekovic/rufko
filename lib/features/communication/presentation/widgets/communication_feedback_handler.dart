import 'package:flutter/material.dart';
import '../controllers/communication_ui_controller.dart';

/// Widget that handles UI feedback for communication operations
/// Separates UI concerns from business logic by listening to controller events
class CommunicationFeedbackHandler extends StatefulWidget {
  final CommunicationUIController controller;
  final Widget child;

  const CommunicationFeedbackHandler({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<CommunicationFeedbackHandler> createState() => _CommunicationFeedbackHandlerState();
}

class _CommunicationFeedbackHandlerState extends State<CommunicationFeedbackHandler> {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.controller.lastError!),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }

    // Handle success messages
    if (widget.controller.lastSuccess != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.controller.lastSuccess!),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.controller.clearMessages();
        }
      });
    }
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