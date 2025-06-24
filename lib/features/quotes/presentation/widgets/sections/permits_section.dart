// lib/widgets/permits_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/quote_extras.dart';
import '../../services/quote_calculation_service.dart';
import '../calculator/calculator_text_field.dart';

class PermitsSection extends StatefulWidget {
  final List<PermitItem> permits;
  final bool noPermitsRequired;
  final Function(PermitItem) onPermitAdded;
  final Function(PermitItem) onPermitRemoved;
  final Function(bool) onNoPermitsRequiredChanged;

  const PermitsSection({
    super.key,
    required this.permits,
    required this.noPermitsRequired,
    required this.onPermitAdded,
    required this.onPermitRemoved,
    required this.onNoPermitsRequiredChanged,
  });

  @override
  State<PermitsSection> createState() => _PermitsSectionState();
}

class _PermitsSectionState extends State<PermitsSection> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addPermit() {
    if (!_formKey.currentState!.validate()) return;

    final permit = PermitItem(
      name: 'Permit',
      amount: double.parse(_amountController.text),
    );

    widget.onPermitAdded(permit);
    
    // Clear the input
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Permits (Required)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('No permits required for this project'),
              subtitle: Text(
                'Check this if no building permits are needed',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              value: widget.noPermitsRequired,
              onChanged: (value) {
                widget.onNoPermitsRequiredChanged(value ?? false);
              },
              activeColor: Colors.green,
            ),
            if (!widget.noPermitsRequired) ...[
              const Divider(),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: CalculatorTextField(
                        controller: _amountController,
                        labelText: 'Permit Amount',
                        prefixText: '\$ ',
                        validator: (value) {
                          if (value?.trim().isEmpty == true) return 'Required';
                          final amount = double.tryParse(value!);
                          if (amount == null || amount < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addPermit,
                      icon: const Icon(Icons.add, size: 24),
                      tooltip: 'Add Permit',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                  ],
                ),
              ),
              if (widget.permits.isEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No permits added yet. Add permits or check "No permits required"',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                ...widget.permits.map(
                  (permit) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '\$').format(permit.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          onPressed: () => widget.onPermitRemoved(permit),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            if (widget.permits.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Permits:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(
                      QuoteCalculationService.calculatePermitsTotal(widget.permits),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
