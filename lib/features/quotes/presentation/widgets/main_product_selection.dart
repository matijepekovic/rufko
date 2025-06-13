// lib/widgets/main_product_selection.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class MainProductSelection extends StatelessWidget {
  final Product? mainProduct;
  final double mainQuantity;
  final String quoteType;
  final Function(Product?) onProductChanged;
  final Function(double) onQuantityChanged;

  const MainProductSelection({
    super.key,
    required this.mainProduct,
    required this.mainQuantity,
    required this.quoteType,
    required this.onProductChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final quantityController =
        TextEditingController(text: mainQuantity.toStringAsFixed(1));

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
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.roofing,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quoteType == 'multi-level'
                            ? 'Step 1: Select Main Product'
                            : 'Step 1: Select Product',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        quoteType == 'multi-level'
                            ? 'This creates your quote levels (Builder/Homeowner/Platinum)'
                            : 'Select any product for your single-tier quote',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                final availableProducts = quoteType == 'multi-level'
                    ? appState.products
                        .where((p) => p.isActive &&
                            p.pricingType == ProductPricingType.mainDifferentiator)
                        .toList()
                    : appState.products.where((p) => p.isActive).toList();

                if (availableProducts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.warning_amber,
                            color: Colors.orange.shade600, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          quoteType == 'multi-level'
                              ? 'No Main Products Found'
                              : 'No Products Found',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quoteType == 'multi-level'
                              ? 'Create a main differentiator product first.'
                              : 'Add some products in the Products section first.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    DropdownButtonFormField<Product>(
                      decoration: InputDecoration(
                        labelText:
                            quoteType == 'multi-level' ? 'Main Product' : 'Product',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.architecture),
                      ),
                      value: mainProduct,
                      items: availableProducts.map((product) => DropdownMenuItem(
                            value: product,
                            child: Text(
                              quoteType == 'multi-level'
                                  ? '${product.name} (${product.availableMainLevels.length} levels)'
                                  : product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          )).toList(),
                      onChanged: onProductChanged,
                      validator: (value) =>
                          value == null ? 'Please select a product' : null,
                    ),
                    if (mainProduct != null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: const OutlineInputBorder(),
                          suffixText: mainProduct!.unit,
                          prefixIcon: const Icon(Icons.calculate_outlined),
                          helperText: 'Amount of ${mainProduct!.name} needed',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          final quantity = double.tryParse(value);
                          if (quantity != null && quantity > 0) {
                            onQuantityChanged(quantity);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final qty = double.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Enter a valid positive quantity';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
