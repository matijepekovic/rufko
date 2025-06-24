import "package:flutter/material.dart";

import "../../../../../data/models/business/quote_extras.dart";
import "../../../../../shared/widgets/buttons/rufko_buttons.dart";
import "../calculator/calculator_text_field.dart";

class CustomItemDialog extends StatefulWidget {
  final Function(CustomLineItem) onItemAdded;

  const CustomItemDialog({super.key, required this.onItemAdded});

  @override
  State<CustomItemDialog> createState() => CustomItemDialogState();
}

class CustomItemDialogState extends State<CustomItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isTaxable = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.add_box, color: Colors.purple),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Custom Line Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CalculatorTextField(
                    controller: _amountController,
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.attach_money),
                    prefixText: '\$ ',
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final amount = double.tryParse(value!);
                      if (amount == null || amount < 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Taxable Item'),
                    subtitle: const Text('Include this item in tax calculations'),
                    value: _isTaxable,
                    onChanged: (value) => setState(() => _isTaxable = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: RufkoSecondaryButton(
                    onPressed: () => Navigator.pop(context),
                    isFullWidth: true,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RufkoPrimaryButton(
                    onPressed: _addCustomItem,
                    isFullWidth: true,
                    child: const Text('Add Item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomItem() {
    if (!_formKey.currentState!.validate()) return;

    final item = CustomLineItem(
      name: _nameController.text,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      isTaxable: _isTaxable,
    );

    widget.onItemAdded(item);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
