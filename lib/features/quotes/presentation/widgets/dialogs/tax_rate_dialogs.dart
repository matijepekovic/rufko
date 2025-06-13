import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quote_form_controller.dart';
import '../../../../../data/models/business/customer.dart';
import '../../../../../data/providers/state/app_state_provider.dart';

class TaxRateDialogs {
  static Future<void> showManualTaxRateDialog(
    BuildContext context,
    Customer customer,
    QuoteFormController controller,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Rate Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('No tax rate found in the local database.'),
            SizedBox(height: 16),
            Text('You can:'),
            SizedBox(height: 8),
            Text('• Enter the tax rate manually for this quote'),
            Text('• Add this location to your tax database in Settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showAddTaxRateDialog(context, customer, controller);
            },
            child: const Text('Add to Database'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enter tax rate manually in the field above'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Enter Manually'),
          ),
        ],
      ),
    );
  }

  static Future<void> showAddTaxRateDialog(
    BuildContext context,
    Customer customer,
    QuoteFormController controller,
  ) async {
    final taxRateController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tax Rate to Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add tax rate for: ${customer.fullDisplayAddress}'),
            const SizedBox(height: 16),
            TextField(
              controller: taxRateController,
              decoration: const InputDecoration(
                labelText: 'Tax Rate (%)',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final appState = context.read<AppStateProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              final rateText = taxRateController.text.trim();
              final rate = double.tryParse(rateText);

              if (rate == null || rate < 0 || rate > 100) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid tax rate (0-100%)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (customer.zipCode?.isNotEmpty == true) {
                await appState.saveZipCodeTaxRate(customer.zipCode!, rate);
              } else if (customer.stateAbbreviation?.isNotEmpty == true) {
                await appState.saveStateTaxRate(customer.stateAbbreviation!, rate);
              }

              navigator.pop();
              controller.taxRate = rate;
              controller.updateQuoteLevelsQuantity();

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Tax rate ${rate.toStringAsFixed(2)}% saved and applied'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }
}
