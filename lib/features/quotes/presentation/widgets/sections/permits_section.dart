// lib/widgets/permits_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/quote_extras.dart';
import '../../services/quote_calculation_service.dart';

class PermitsSection extends StatelessWidget {
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

  void _showAddPermitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _PermitDialog(onPermitAdded: onPermitAdded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('No permits required for this project'),
              subtitle: Text(
                'Check this if no building permits are needed',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              value: noPermitsRequired,
              onChanged: (value) {
                onNoPermitsRequiredChanged(value ?? false);
              },
              activeColor: Colors.green,
            ),
            if (!noPermitsRequired) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Required Permits:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPermitDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Permit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (permits.isEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 12),
                ...permits.map(
                  (permit) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: Icon(
                        Icons.assignment,
                        color: Colors.orange.shade700,
                      ),
                      title: Text(permit.name),
                      subtitle: permit.description?.isNotEmpty == true
                          ? Text(permit.description!)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            NumberFormat.currency(symbol: '\$')
                                .format(permit.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => onPermitRemoved(permit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
            if (permits.isNotEmpty) ...[
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
                      QuoteCalculationService.calculatePermitsTotal(permits),
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

class _PermitDialog extends StatefulWidget {
  final Function(PermitItem) onPermitAdded;

  const _PermitDialog({required this.onPermitAdded});

  @override
  State<_PermitDialog> createState() => _PermitDialogState();
}

class _PermitDialogState extends State<_PermitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

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
                Icon(Icons.assignment, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Permit',
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
                      labelText: 'Permit Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assignment),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '\$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final amount = double.tryParse(value!);
                      if (amount == null || amount < 0) {
                        return 'Enter valid amount';
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addPermit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Add Permit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addPermit() {
    if (!_formKey.currentState!.validate()) return;

    final permit = PermitItem(
      name: _nameController.text,
      amount: double.parse(_amountController.text),
      description:
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    widget.onPermitAdded(permit);
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
