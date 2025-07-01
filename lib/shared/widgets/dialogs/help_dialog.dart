import 'package:flutter/material.dart';
import '../../../core/utils/settings_constants.dart';
import '../buttons/rufko_buttons.dart';

/// Displays general help information for the application.
class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.help, color: Colors.green.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Help & Support'),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(helpText, style: const TextStyle(fontSize: 16)),
      ),
      actions: [
        RufkoTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Opens the [HelpDialog].
Future<void> showHelpDialog(BuildContext context) async {
  return showDialog(context: context, builder: (c) => const HelpDialog());
}
