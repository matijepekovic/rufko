// lib/screens/simplified_quote_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/roof_scope_data.dart';
import '../models/simplified_quote.dart';
import '../models/quote.dart'; // For QuoteItem
import '../providers/app_state_provider.dart';
// Import a placeholder for the detail screen
import 'simplified_quote_detail_screen.dart';


class SimplifiedQuoteScreen extends StatefulWidget {
  final Customer customer;
  final RoofScopeData? roofScopeData;

  const SimplifiedQuoteScreen({
    Key? key,
    required this.customer,
    this.roofScopeData,
  }) : super(key: key);

  @override
  State<SimplifiedQuoteScreen> createState() => _SimplifiedQuoteScreenState();
}

class _SimplifiedQuoteScreenState extends State<SimplifiedQuoteScreen> {
  Product? _baseProduct;
  final List<QuoteLevel> _levels = [];
  final List<QuoteItem> _overallAddons = []; // Renamed to avoid confusion
  bool _isLoading = false;

  final _screenFormKey = GlobalKey<FormState>(); // For validating the whole screen before generation

  // Level configurations
  final List<Map<String, dynamic>> _predefinedLevels = [
    {'id': 'basic', 'name': 'Basic', 'multiplier': 1.0, 'color': Colors.blue.shade600},
    {'id': 'standard', 'name': 'Standard', 'multiplier': 1.25, 'color': Colors.orange.shade700},
    {'id': 'premium', 'name': 'Premium', 'multiplier': 1.5, 'color': Colors.green.shade700},
  ];

  // --- DIALOG FOR ADDING ITEMS TO A SPECIFIC LEVEL ---
  void _showAddItemToLevelDialog(QuoteLevel level) {
    Product? dialogSelectedProduct;
    final quantityController = TextEditingController(text: '1.0');
    final itemDialogFormKey = GlobalKey<FormState>();
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    final availableProducts = appState.products.where((p) {
      bool isBase = p.id == _baseProduct?.id;
      bool alreadyIncluded = level.includedItems.any((item) => item.productId == p.id);
      return p.isActive && !isBase && !alreadyIncluded;
    }).toList();

    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more unique products available to add to this level.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Add Item to ${level.name}'),
              content: Form(
                key: itemDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
                        value: dialogSelectedProduct,
                        items: availableProducts.map((product) => DropdownMenuItem<Product>(
                          value: product,
                          child: Text(product.name),
                        )).toList(),
                        onChanged: (Product? newValue) => setDialogState(() => dialogSelectedProduct = newValue),
                        validator: (value) => value == null ? 'Please select a product' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
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
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Add Item'),
                  onPressed: () {
                    if (itemDialogFormKey.currentState!.validate()) {
                      if (dialogSelectedProduct != null) {
                        final quantity = double.parse(quantityController.text);
                        final newItem = QuoteItem(
                          productId: dialogSelectedProduct!.id,
                          productName: dialogSelectedProduct!.name,
                          quantity: quantity,
                          unitPrice: dialogSelectedProduct!.getPriceForLevel(level.id),
                          unit: dialogSelectedProduct!.unit,
                          description: dialogSelectedProduct!.description,
                        );
                        setState(() { // Main screen's setState
                          level.includedItems.add(newItem);
                          level.calculateSubtotal();
                        });
                        Navigator.of(dialogContext).pop();
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DIALOG FOR ADDING OPTIONAL ADD-ONS TO THE ENTIRE QUOTE ---
  void _showAddOptionalAddonDialog() {
    Product? dialogSelectedProduct;
    final quantityController = TextEditingController(text: '1.0');
    final addonDialogFormKey = GlobalKey<FormState>();
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    final availableProducts = appState.products.where((p) {
      bool isBase = p.id == _baseProduct?.id;
      bool alreadyAddedAsOptional = _overallAddons.any((addon) => addon.productId == p.id);
      // Typically, add-ons are specific products, or any non-base product
      return p.isActive && (p.isAddon || !isBase) && !alreadyAddedAsOptional;
    }).toList();

    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more unique products available to add as optional add-ons.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Optional Add-on to Quote'),
              content: Form(
                key: addonDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(labelText: 'Add-on Product', border: OutlineInputBorder()),
                        value: dialogSelectedProduct,
                        items: availableProducts.map((product) => DropdownMenuItem<Product>(
                          value: product,
                          child: Text('${product.name} (\$${product.unitPrice.toStringAsFixed(2)}/${product.unit})'),
                        )).toList(),
                        onChanged: (Product? newValue) => setDialogState(() => dialogSelectedProduct = newValue),
                        validator: (value) => value == null ? 'Please select a product' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
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
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Add Add-on'),
                  onPressed: () {
                    if (addonDialogFormKey.currentState!.validate()) {
                      if (dialogSelectedProduct != null) {
                        final quantity = double.parse(quantityController.text);
                        final newAddon = QuoteItem(
                          productId: dialogSelectedProduct!.id,
                          productName: dialogSelectedProduct!.name,
                          quantity: quantity,
                          unitPrice: dialogSelectedProduct!.unitPrice, // Add-ons usually use their standard price
                          unit: dialogSelectedProduct!.unit,
                          description: dialogSelectedProduct!.description,
                        );
                        setState(() { // Main screen's setState
                          _overallAddons.add(newAddon);
                        });
                        Navigator.of(dialogContext).pop();
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _generateQuote() async {
    if (!(_screenFormKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct errors before generating.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_baseProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a base product.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure at least one product level.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final newQuote = SimplifiedMultiLevelQuote(
      customerId: widget.customer.id,
      roofScopeDataId: widget.roofScopeData?.id,
      levels: _levels.map((l) { // Ensure all levels have their subtotals calculated
        l.calculateSubtotal();
        return l;
      }).toList(),
      addons: _overallAddons,
      taxRate: appState.appSettings?.taxRate ?? 0.0, // Get from AppSettings or a UI field
      discount: 0.0, // Add a UI field for this if needed
      status: 'draft',
    );

    // Calculate totals for the main quote object if it has such a method,
    // or ensure all level totals are up-to-date.
    // newQuote.calculateAllTotals(); // If you add such a method

    try {
      await appState.addSimplifiedQuote(newQuote); // This needs to be implemented in AppStateProvider
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote ${newQuote.quoteNumber} generated!'), backgroundColor: Colors.green),
      );
      // Navigate to a new SimplifiedQuoteDetailScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SimplifiedQuoteDetailScreen(quote: newQuote, customer: widget.customer),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating quote: $e'), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Quote: ${widget.customer.name}'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(semanticsLabel: "Generating quote..."))
          : Form(
        key: _screenFormKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProductSelection(),
              const SizedBox(height: 24),
              if (_baseProduct != null) _buildLevelConfiguration(),
              const SizedBox(height: 24),
              if (_baseProduct != null) _buildOverallAddonSelection(),
              const SizedBox(height: 32),
              if (_baseProduct != null && _levels.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Generate Quote'),
                  onPressed: _generateQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Select Base Product / Service',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                final products = appState.products.where((p) => p.isActive && !p.isAddon).toList(); // Only non-addons as base
                if (products.isEmpty) {
                  return const Text('No base products available. Please add non-addon products.');
                }
                return DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'Base Product', border: OutlineInputBorder()),
                  value: _baseProduct,
                  items: products.map((product) => DropdownMenuItem(value: product, child: Text(product.name))).toList(),
                  onChanged: (product) {
                    setState(() {
                      _baseProduct = product;
                      _levels.clear();
                      if (product != null) {
                        for (var i = 0; i < _predefinedLevels.length; i++) {
                          final levelConfig = _predefinedLevels[i];
                          final levelSpecificBasePrice = product.getPriceForLevel(levelConfig['id']);
                          _levels.add(QuoteLevel(
                            id: levelConfig['id'],
                            name: levelConfig['name'],
                            levelNumber: i + 1,
                            basePrice: levelSpecificBasePrice,
                            includedItems: [],
                          )..calculateSubtotal());
                        }
                      }
                    });
                  },
                  validator: (value) => value == null ? 'Please select a base product' : null,
                );
              },
            ),
            if (_baseProduct != null) ...[
              const SizedBox(height: 12),
              Text(
                'Default Price: \$${_baseProduct!.unitPrice.toStringAsFixed(2)} / ${_baseProduct!.unit}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelConfiguration() {
    if (_levels.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2. Configure Product Levels',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                final level = _levels[index];
                final levelConfig = _predefinedLevels.firstWhere(
                        (pl) => pl['id'] == level.id,
                    orElse: () => {'color': Colors.grey.shade700, 'name': level.name});
                final color = levelConfig['color'] as Color;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(8),
                    color: color.withOpacity(0.08),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: level.name,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                              decoration: InputDecoration(
                                  labelText: 'Level Name',
                                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                                  labelStyle: TextStyle(color: color.withOpacity(0.8))
                              ),
                              onChanged: (newName) => setState(() => level.name = newName),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.playlist_add, color: color),
                            tooltip: 'Add Item to ${level.name}',
                            onPressed: () => _showAddItemToLevelDialog(level),
                          ),
                          if (_levels.length > 1) // Only show remove if more than one level
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                              tooltip: 'Remove Level',
                              onPressed: () => setState(() => _levels.removeAt(index)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: level.basePrice.toStringAsFixed(2),
                        decoration: const InputDecoration(labelText: 'Base Price for this Level', prefixText: '\$', border: OutlineInputBorder(), isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          final price = double.tryParse(value);
                          if (price != null) {
                            setState(() {
                              level.basePrice = price;
                              level.calculateSubtotal();
                            });
                          }
                        },
                      ),
                      if (level.includedItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text("Included Items:", style: TextStyle(fontWeight: FontWeight.w500, color: color.withOpacity(0.9))),
                        ...level.includedItems.map((item) => ListTile(
                          title: Text(item.productName, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('${item.quantity} ${item.unit} @ \$${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                            onPressed: () => setState(() {
                              level.includedItems.remove(item);
                              level.calculateSubtotal();
                            }),
                          ),
                          dense: true, contentPadding: EdgeInsets.zero,
                        )),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Level Subtotal: \$${level.subtotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      ),
                    ],
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Custom Level'),
                onPressed: () {
                  setState(() {
                    int nextLevelNum = _levels.length + 1;
                    String newLevelId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                    _levels.add(QuoteLevel(
                      id: newLevelId, name: 'Custom Level $nextLevelNum', levelNumber: nextLevelNum,
                      basePrice: _baseProduct?.unitPrice ?? 0.0,
                    )..calculateSubtotal());
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallAddonSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. Optional Add-ons (for entire quote)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_overallAddons.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No optional add-ons selected yet.', style: TextStyle(color: Colors.grey)),
              ))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _overallAddons.length,
                itemBuilder: (context, index){
                  final addon = _overallAddons[index];
                  return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(addon.productName),
                        subtitle: Text('${addon.quantity} ${addon.unit} @ \$${addon.unitPrice.toStringAsFixed(2)} ea.'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => _overallAddons.removeAt(index)),
                        ),
                      ));
                },
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Optional Add-on'),
                onPressed: _showAddOptionalAddonDialog,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent.shade700, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}