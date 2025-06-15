import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../app/theme/rufko_theme.dart';

class DiscountDialog extends StatefulWidget {
  final ValueChanged<QuoteDiscount> onDiscountAdded;

  const DiscountDialog({super.key, required this.onDiscountAdded});

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog>
    with ResponsiveBreakpointsMixin, ResponsiveSpacingMixin {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'percentage';
  bool _applyToAddons = true;
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildContent(context),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacingSM(context) * 5),
      decoration: const BoxDecoration(
        color: RufkoTheme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.white, size: 24),
          SizedBox(width: spacingMD(context)),
          const Expanded(
            child: Text(
              'Add Discount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacingSM(context) * 5),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Discount Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage Discount'),
                  ),
                  DropdownMenuItem(
                    value: 'fixed_amount',
                    child: Text('Fixed Amount Discount'),
                  ),
                  DropdownMenuItem(
                    value: 'voucher',
                    child: Text('Voucher Code'),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText:
                      _type == 'percentage' ? 'Percentage (%)' : 'Amount (\$)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_type == 'percentage'
                      ? Icons.percent
                      : Icons.attach_money),
                  suffixText: _type == 'percentage' ? '%' : null,
                  prefixText: _type == 'fixed_amount' ? '\$ ' : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Enter valid positive number';
                  }
                  if (_type == 'percentage' && num > 100) {
                    return 'Cannot exceed 100%';
                  }
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
              if (_type == 'voucher') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Voucher Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Code required for vouchers'
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.grey[50],
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Apply to Add-ons'),
                      subtitle:
                          const Text('Include add-on products in discount'),
                      value: _applyToAddons,
                      onChanged: (value) =>
                          setState(() => _applyToAddons = value),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Expiry Date'),
                      subtitle: Text(
                        _expiryDate != null
                            ? DateFormat('MMM dd, yyyy').format(_expiryDate!)
                            : 'No expiry date set',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (!mounted) return;
                        if (date != null) setState(() => _expiryDate = date);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacingSM(context) * 5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: spacingMD(context)),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _addDiscount,
              style: ElevatedButton.styleFrom(
                backgroundColor: RufkoTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Add Discount'),
            ),
          ),
        ],
      ),
    );
  }

  void _addDiscount() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final discount = QuoteDiscount(
      type: _type,
      value: double.parse(_valueController.text),
      code: _codeController.text.isEmpty ? null : _codeController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      applyToAddons: _applyToAddons,
      expiryDate: _expiryDate,
    );

    widget.onDiscountAdded(discount);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
