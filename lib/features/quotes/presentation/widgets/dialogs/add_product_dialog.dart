import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../../../data/models/business/product.dart";
import "../../../../../data/models/business/quote.dart";
import "../../../../../data/providers/state/app_state_provider.dart";

class AddProductDialog extends StatefulWidget {
  final Function(QuoteItem) onProductAdded;

  const AddProductDialog({super.key, required this.onProductAdded});

  @override
  State<AddProductDialog> createState() => AddProductDialogState();
}

class AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1.0');

  Product? _selectedProduct;
  ProductLevelPrice? _selectedLevel;
  String _expandedCategory = '';

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.add_shopping_cart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Product to Quote',
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

            // Product Selection
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Product:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Product Categories
                    Expanded(
                      child: Consumer<AppStateProvider>(
                        builder: (context, appState, child) {
                          final productsByCategory = _groupProductsByCategory(appState.products);

                          return ListView(
                            children: productsByCategory.entries.map((entry) {
                              final category = entry.key;
                              final products = entry.value;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    title: Text(
                                      '$category (${products.length})',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    leading: Icon(_getCategoryIcon(category)),
                                    initiallyExpanded: _expandedCategory == category,
                                    onExpansionChanged: (expanded) {
                                      setState(() {
                                        _expandedCategory = expanded ? category : '';
                                      });
                                    },
                                    children: products.map((product) {
                                      final isSelected = _selectedProduct?.id == product.id;

                                      return ListTile(
                                        title: Text(product.name),
                                        subtitle: Text(
                                          '\$${product.unitPrice.toStringAsFixed(2)}/${product.unit}${product.enhancedLevelPrices.isNotEmpty
                                                  ? ' (${product.enhancedLevelPrices.length} levels)'
                                                  : ''}',
                                        ),
                                        leading: Radio<Product>(
                                          value: product,
                                          groupValue: _selectedProduct,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedProduct = value;
                                              _selectedLevel = null;
                                            });
                                          },
                                        ),
                                        selected: isSelected,
                                        onTap: () {
                                          setState(() {
                                            _selectedProduct = product;
                                            _selectedLevel = null;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Level Selection
                    if (_selectedProduct != null && _selectedProduct!.enhancedLevelPrices.isNotEmpty) ...[
                      const Text(
                        'Select Level:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ProductLevelPrice>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.layers),
                        ),
                        value: _selectedLevel,
                        hint: const Text('Choose level/option'),
                        items: _selectedProduct!.enhancedLevelPrices.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text('${level.levelName} - \$${level.price.toStringAsFixed(2)}/${_selectedProduct!.unit}'),
                          );
                        }).toList(),
                        onChanged: (level) {
                          setState(() {
                            _selectedLevel = level;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a level' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quantity Input
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calculate),
                        suffixText: _selectedProduct?.unit ?? '',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter quantity';
                        final qty = double.tryParse(value);
                        if (qty == null || qty <= 0) return 'Enter a valid positive quantity';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            const Divider(),
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
                    onPressed: _addProduct,
                    child: const Text('Add to Quote'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Product>> _groupProductsByCategory(List<Product> products) {
    final grouped = <String, List<Product>>{};

    for (final product in products) {
      if (!product.isActive) continue;
      if (product.pricingType == ProductPricingType.mainDifferentiator) continue;

      final category = product.category;
      grouped.putIfAbsent(category, () => []).add(product);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final result = <String, List<Product>>{};
    for (final entry in sortedEntries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
      result[entry.key] = entry.value;
    }

    return result;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'materials':
      case 'roofing':
        return Icons.roofing;
      case 'gutters':
        return Icons.water_drop;
      case 'labor':
        return Icons.engineering;
      case 'flashing':
        return Icons.flash_on;
      default:
        return Icons.category;
    }
  }

  void _addProduct() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    // Determine price to use
    double unitPrice;
    String productName = _selectedProduct!.name;

    if (_selectedProduct!.enhancedLevelPrices.isNotEmpty) {
      if (_selectedLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a level for this product')),
        );
        return;
      }
      unitPrice = _selectedLevel!.price;
      productName += ' (${_selectedLevel!.levelName})';
    } else {
      unitPrice = _selectedProduct!.unitPrice;
    }

    final quantity = double.parse(_quantityController.text);

    final quoteItem = QuoteItem(
      productId: _selectedProduct!.id,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      unit: _selectedProduct!.unit,
      description: _selectedLevel?.description,
    );

    widget.onProductAdded(quoteItem);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $productName to all quote levels'),
        backgroundColor: Colors.green,
      ),
    );
  }

}
