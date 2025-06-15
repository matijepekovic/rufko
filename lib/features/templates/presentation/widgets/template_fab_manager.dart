import 'package:flutter/material.dart';
import '../../../../app/theme/rufko_theme.dart';

typedef FabCallback = void Function();

class TemplateFabManager extends StatelessWidget {
  final TabController controller;
  final FabCallback onCreatePdf;
  final FabCallback onCreateMessage;
  final FabCallback onCreateEmail;
  final FabCallback onCreateField;

  const TemplateFabManager({
    super.key,
    required this.controller,
    required this.onCreatePdf,
    required this.onCreateMessage,
    required this.onCreateEmail,
    required this.onCreateField,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        switch (controller.index) {
          case 0:
            return FloatingActionButton.extended(
              heroTag: 'pdf_fab',
              onPressed: onCreatePdf,
              icon: const Icon(Icons.add),
              label: const Text('New PDF Template'),
              backgroundColor: RufkoTheme.primaryColor,
            );
          case 1:
            return FloatingActionButton.extended(
              heroTag: 'message_fab',
              onPressed: onCreateMessage,
              icon: const Icon(Icons.add),
              label: const Text('New Message Template'),
              backgroundColor: Colors.green,
            );
          case 2:
            return FloatingActionButton.extended(
              heroTag: 'email_fab',
              onPressed: onCreateEmail,
              icon: const Icon(Icons.add),
              label: const Text('New Email Template'),
              backgroundColor: Colors.orange,
            );
          default:
            return FloatingActionButton.extended(
              heroTag: 'field_fab',
              onPressed: onCreateField,
              icon: const Icon(Icons.add),
              label: const Text('New Field'),
              backgroundColor: RufkoTheme.primaryColor,
            );
        }
      },
    );
  }
}
