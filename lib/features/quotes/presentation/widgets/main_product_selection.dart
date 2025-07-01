// lib/widgets/main_product_selection.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/utils/helpers/common_utils.dart';
import 'calculator/calculator_text_field.dart';

class MainProductSelection extends StatefulWidget {
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
  State<MainProductSelection> createState() => _MainProductSelectionState();
}

class _MainProductSelectionState extends State<MainProductSelection> {
  late TextEditingController _quantityController;
  late FocusNode _quantityFocusNode;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: formatQuantity(widget.mainQuantity));
    _quantityFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(MainProductSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the text if the field is not focused (user is not actively typing)
    if (oldWidget.mainQuantity != widget.mainQuantity && !_quantityFocusNode.hasFocus) {
      _quantityController.text = formatQuantity(widget.mainQuantity);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.roofing,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.quoteType == 'multi-level'
                            ? 'Select Main Product'
                            : 'Select Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.quoteType == 'multi-level'
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
            const SizedBox(height: 20),
            Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                final availableProducts = widget.quoteType == 'multi-level'
                    ? appState.products
                        .where((p) => p.isActive &&
                            p.pricingType == ProductPricingType.mainDifferentiator)
                        .toList()
                    : appState.products.where((p) => p.isActive).toList();

                if (availableProducts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.quoteType == 'multi-level'
                              ? 'No Main Products Found'
                              : 'No Products Found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.quoteType == 'multi-level'
                              ? 'Create a main differentiator product first.'
                              : 'Add some products in the Products section first.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
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
                            widget.quoteType == 'multi-level' ? 'Main Product' : 'Product',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.architecture),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                      isExpanded: true,
                      value: widget.mainProduct,
                      items: availableProducts.map((product) => DropdownMenuItem(
                            value: product,
                            child: Text(
                              widget.quoteType == 'multi-level'
                                  ? '${product.name} (${product.availableMainLevels.length} levels)'
                                  : product.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          )).toList(),
                      onChanged: widget.onProductChanged,
                      validator: (value) =>
                          value == null ? 'Please select a product' : null,
                    ),
                    if (widget.mainProduct != null) ...[
                      const SizedBox(height: 16),
                      CalculatorTextField(
                        controller: _quantityController,
                        labelText: 'Quantity',
                        unit: widget.mainProduct!.unit,
                        helperText: 'Amount of ${widget.mainProduct!.name} needed',
                        prefixIcon: const Icon(Icons.calculate_outlined),
                        onChanged: (value) {
                          final quantity = double.tryParse(value);
                          if (quantity != null && quantity > 0) {
                            widget.onQuantityChanged(quantity);
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
