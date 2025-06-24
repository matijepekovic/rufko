// lib/widgets/tax_rate_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/business/customer.dart';
import '../../../../../data/providers/state/app_state_provider.dart';

class TaxRateSection extends StatelessWidget {
  final double taxRate;
  final Customer customer;
  final Function(double) onTaxRateChanged;
  final VoidCallback onAutoDetectPressed;

  const TaxRateSection({
    super.key,
    required this.taxRate,
    required this.customer,
    required this.onTaxRateChanged,
    required this.onAutoDetectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.percent,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tax Rate',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: taxRate.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Tax Rate (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                      prefixIcon: Icon(Icons.calculate),
                      helperText: 'Enter tax rate for this quote',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final rate = double.tryParse(value);
                      if (rate != null && rate >= 0 && rate <= 100) {
                        onTaxRateChanged(rate);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter tax rate';
                      final rate = double.tryParse(value);
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Enter valid tax rate (0-100%)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Consumer<AppStateProvider>(
                    builder: (context, appState, child) {
                      return FilledButton.icon(
                        onPressed: onAutoDetectPressed,
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('Auto-Detect'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (taxRate > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tax rate: ${taxRate.toStringAsFixed(2)}% will be applied.',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
