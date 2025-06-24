import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quote_form_controller.dart';
import '../../../../../data/models/business/customer.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

class TaxRateDialogs {
  static Future<void> showManualTaxRateDialog(
    BuildContext context,
    Customer customer,
    QuoteFormController controller,
  ) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Tax Rate Not Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('No tax rate found in the local database.'),
              const SizedBox(height: 16),
              const Text('You can:'),
              const SizedBox(height: 8),
              const Text('• Enter the tax rate manually for this quote'),
              const Text('• Add this location to your tax database in Settings'),
              const SizedBox(height: 24),
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
                    child: RufkoSecondaryButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showAddTaxRateDialog(context, customer, controller);
                      },
                      isFullWidth: true,
                      child: const Text('Add to Database'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RufkoPrimaryButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter tax rate manually in the field above'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      isFullWidth: true,
                      child: const Text('Enter Manually'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.add_location, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Tax Rate to Database',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
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
                    flex: 2,
                    child: RufkoPrimaryButton(
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
