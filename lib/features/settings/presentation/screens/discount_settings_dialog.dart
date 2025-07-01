import 'package:flutter/material.dart';
import '../../../../shared/widgets/buttons/rufko_dialog_actions.dart';
class DiscountSettingsDialog extends StatefulWidget {
  final List<String> discountTypes;
  final double defaultDiscountLimit;
  final Function(List<String>, double) onSave;

  const DiscountSettingsDialog({super.key,
    required this.discountTypes,
    required this.defaultDiscountLimit,
    required this.onSave,
  });

  @override
  State<DiscountSettingsDialog> createState() => DiscountSettingsDialogState();
}

class DiscountSettingsDialogState extends State<DiscountSettingsDialog> {
  late List<String> _discountTypes;
  late double _discountLimit;
  final TextEditingController _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _discountTypes = List.from(widget.discountTypes);
    _discountLimit = widget.defaultDiscountLimit;
    _limitController.text = _discountLimit.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _limitController.dispose();
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
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.discount, color: Colors.orange.shade600),
          ),
          const SizedBox(width: 12),
          const Text('Discount Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _limitController,
            decoration: InputDecoration(
              labelText: 'Maximum Discount Percentage',
              prefixIcon: Icon(Icons.percent, color: Colors.orange.shade600),
              suffixText: '%',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              _discountLimit = double.tryParse(value) ?? _discountLimit;
            },
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Discount Types:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                ...['percentage', 'fixed_amount', 'voucher'].map((type) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: CheckboxListTile(
                      title: Text(
                        type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _discountTypes.contains(type),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (!_discountTypes.contains(type)) {
                              _discountTypes.add(type);
                            }
                          } else {
                            _discountTypes.remove(type);
                          }
                        });
                      },
                      activeColor: Colors.orange.shade600,
                      dense: true,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      actions: [
        RufkoDialogActions(
          onCancel: () => Navigator.pop(context),
          onConfirm: () {
            widget.onSave(_discountTypes, _discountLimit);
            Navigator.pop(context);
          },
          confirmText: 'Save',
        ),
      ],
    );
  }

}
