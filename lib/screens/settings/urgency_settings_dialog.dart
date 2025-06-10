import 'package:flutter/material.dart';

class UrgencySettingsDialog extends StatefulWidget {
  final int yellowDays;
  final int orangeDays;
  final int redDays;
  final Function(int, int, int) onSave;

  const UrgencySettingsDialog({
    super.key,
    required this.yellowDays,
    required this.orangeDays,
    required this.redDays,
    required this.onSave,
  });

  @override
  State<UrgencySettingsDialog> createState() => _UrgencySettingsDialogState();
}

class _UrgencySettingsDialogState extends State<UrgencySettingsDialog> {
  late TextEditingController _yellowController;
  late TextEditingController _orangeController;
  late TextEditingController _redController;

  @override
  void initState() {
    super.initState();
    _yellowController = TextEditingController(text: widget.yellowDays.toString());
    _orangeController = TextEditingController(text: widget.orangeDays.toString());
    _redController = TextEditingController(text: widget.redDays.toString());
  }

  @override
  void dispose() {
    _yellowController.dispose();
    _orangeController.dispose();
    _redController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber, color: Colors.red.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Urgency Thresholds'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildField(_yellowController, 'Yellow after (days)', Colors.yellow.shade600),
          const SizedBox(height: 12),
          _buildField(_orangeController, 'Orange after (days)', Colors.orange.shade600),
          const SizedBox(height: 12),
          _buildField(_redController, 'Red after (days)', Colors.red.shade600),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final yellow = int.tryParse(_yellowController.text) ?? widget.yellowDays;
            final orange = int.tryParse(_orangeController.text) ?? widget.orangeDays;
            final red = int.tryParse(_redController.text) ?? widget.redDays;
            widget.onSave(yellow, orange, red);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, Color color) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.timer, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
    );
  }
}
