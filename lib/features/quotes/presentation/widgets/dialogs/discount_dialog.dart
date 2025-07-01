import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

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
  final bool _applyToAddons = false; // Always false - no addon discounts
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          margin: const EdgeInsets.only(top: 40),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Discount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Add percentage or fixed discount to quote',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Discount Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage Discount', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'fixed_amount',
                    child: Text('Fixed Amount Discount', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'voucher',
                    child: Text('Voucher Code', overflow: TextOverflow.ellipsis),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(_type == 'percentage'
                      ? Icons.percent
                      : Icons.attach_money),
                  suffixText: _type == 'percentage' ? '%' : null,
                  prefixText: _type == 'fixed_amount' ? '\$ ' : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
                textAlignVertical: TextAlignVertical.top,
              ),
              if (_type == 'voucher') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Voucher Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.confirmation_number),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    _expiryDate != null
                        ? DateFormat('MMM dd, yyyy').format(_expiryDate!)
                        : 'No expiry date set',
                    overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        RufkoSecondaryButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        RufkoPrimaryButton(
          onPressed: _addDiscount,
          icon: Icons.add,
          child: const Text('Add Discount'),
        ),
      ],
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
