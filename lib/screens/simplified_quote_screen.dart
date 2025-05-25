// lib/screens/simplified_quote_screen.dart - UPDATED WITH BASE QUANTITY SUPPORT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/roof_scope_data.dart';
import '../models/simplified_quote.dart';
import '../models/quote.dart'; // For QuoteItem
import '../providers/app_state_provider.dart';
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
  final List<QuoteItem> _overallAddons = [];
  bool _isLoading = false;

  // NEW: Base product quantity controller
  final _baseQuantityController = TextEditingController(text: '1.0');
  double _currentBaseQuantity = 1.0;

  final _screenFormKey = GlobalKey<FormState>();

  // Level configurations
  final List<Map<String, dynamic>> _predefinedLevels = [
    {'id': 'basic', 'name': 'Basic', 'multiplier': 1.0, 'color': Colors.blue.shade600},
    {'id': 'standard', 'name': 'Standard', 'multiplier': 1.25, 'color': Colors.orange.shade700},
    {'id': 'premium', 'name': 'Premium', 'multiplier': 1.5, 'color': Colors.green.shade700},
  ];

  @override
  void dispose() {
    _baseQuantityController.dispose();
    super.dispose();
  }

  // UPDATED: Update base quantity across all levels
  void _updateBaseQuantity(double newQuantity) {
    setState(() {
      _currentBaseQuantity = newQuantity;
      for (final level in _levels) {
        level.baseQuantity = newQuantity;
        level.calculateSubtotal();
      }
    });
  }

  // Add items to ALL levels at once
  void _showAddItemToAllLevelsDialog() {
    Product? dialogSelectedProduct;
    final quantityController = TextEditingController(text: '1.0');
    final itemDialogFormKey = GlobalKey<FormState>();
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    final Set<String> alreadyAddedProductIds = {};
    for (final level in _levels) {
      for (final item in level.includedItems) {
        alreadyAddedProductIds.add(item.productId);
      }
    }

    final availableProducts = appState.products.where((p) {
      bool isBase = p.id == _baseProduct?.id;
      bool alreadyIncluded = alreadyAddedProductIds.contains(p.id);
      return p.isActive && !isBase && !alreadyIncluded;
    }).toList();

    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more unique products available to add to levels.'),
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
              title: const Text('Add Product to All Levels'),
              content: Form(
                key: itemDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(
                            labelText: 'Product',
                            border: OutlineInputBorder(),
                            helperText: 'This product will be added to all quote levels'
                        ),
                        value: dialogSelectedProduct,
                        items: availableProducts.map((product) => DropdownMenuItem<Product>(
                          value: product,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                'Base: \$${product.unitPrice.toStringAsFixed(2)}/${product.unit}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (Product? newValue) => setDialogState(() => dialogSelectedProduct = newValue),
                        validator: (value) => value == null ? 'Please select a product' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          helperText: 'Number of units for each level',
                          suffixIcon: Icon(Icons.calculate_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter quantity';
                          final qty = double.tryParse(value);
                          if (qty == null || qty <= 0) return 'Enter a valid positive quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Will be added to:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _levels.map((level) => Chip(
                                label: Text(level.name),
                                backgroundColor: _predefinedLevels
                                    .firstWhere((pl) => pl['id'] == level.id, orElse: () => {'color': Colors.grey})['color']
                                    .withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: _predefinedLevels
                                      .firstWhere((pl) => pl['id'] == level.id, orElse: () => {'color': Colors.grey})['color'],
                                  fontSize: 12,
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
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
                  child: const Text('Add to All Levels'),
                  onPressed: () {
                    if (itemDialogFormKey.currentState!.validate()) {
                      if (dialogSelectedProduct != null) {
                        final quantity = double.parse(quantityController.text);

                        setState(() {
                          for (final level in _levels) {
                            final newItem = QuoteItem(
                              productId: dialogSelectedProduct!.id,
                              productName: dialogSelectedProduct!.name,
                              quantity: quantity,
                              unitPrice: dialogSelectedProduct!.getPriceForLevel(level.id),
                              unit: dialogSelectedProduct!.unit,
                              description: dialogSelectedProduct!.description,
                            );
                            level.includedItems.add(newItem);
                            level.calculateSubtotal();
                          }
                        });
                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Added ${quantity.toStringAsFixed(1)} ${dialogSelectedProduct!.unit} of "${dialogSelectedProduct!.name}" to all ${_levels.length} levels'
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
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

  // Add items to a specific level
  void _showAddItemToSpecificLevelDialog(QuoteLevel level) {
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
        SnackBar(
          content: Text('No more unique products available to add to ${level.name}.'),
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
              title: Text('Add Product to ${level.name} Only'),
              content: Form(
                key: itemDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(
                          labelText: 'Product',
                          border: OutlineInputBorder(),
                        ),
                        value: dialogSelectedProduct,
                        items: availableProducts.map((product) => DropdownMenuItem<Product>(
                          value: product,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                '${level.name} Price: \$${product.getPriceForLevel(level.id).toStringAsFixed(2)}/${product.unit}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (Product? newValue) => setDialogState(() => dialogSelectedProduct = newValue),
                        validator: (value) => value == null ? 'Please select a product' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calculate_outlined),
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
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: Text('Add to ${level.name}'),
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
                        setState(() {
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

  // Enhanced optional add-ons dialog
  void _showAddOptionalAddonDialog() {
    Product? dialogSelectedProduct;
    final quantityController = TextEditingController(text: '1.0');
    final addonDialogFormKey = GlobalKey<FormState>();
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    final availableProducts = appState.products.where((p) {
      bool isBase = p.id == _baseProduct?.id;
      bool alreadyAddedAsOptional = _overallAddons.any((addon) => addon.productId == p.id);
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
              title: const Text('Add Optional Add-on'),
              content: Form(
                key: addonDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(
                            labelText: 'Add-on Product',
                            border: OutlineInputBorder(),
                            helperText: 'Optional add-on for the entire quote'
                        ),
                        value: dialogSelectedProduct,
                        items: availableProducts.map((product) => DropdownMenuItem<Product>(
                          value: product,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                  if (product.isAddon)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ADDON',
                                        style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '\$${product.unitPrice.toStringAsFixed(2)}/${product.unit}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (Product? newValue) => setDialogState(() => dialogSelectedProduct = newValue),
                        validator: (value) => value == null ? 'Please select a product' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calculate_outlined),
                          helperText: dialogSelectedProduct != null
                              ? 'Total: \$${(dialogSelectedProduct!.unitPrice * (double.tryParse(quantityController.text) ?? 1)).toStringAsFixed(2)}'
                              : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) => setDialogState(() {}),
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
                          unitPrice: dialogSelectedProduct!.unitPrice,
                          unit: dialogSelectedProduct!.unit,
                          description: dialogSelectedProduct!.description,
                        );
                        setState(() {
                          _overallAddons.add(newAddon);
                        });
                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Added ${quantity.toStringAsFixed(1)} ${dialogSelectedProduct!.unit} of "${dialogSelectedProduct!.name}" as optional add-on'
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
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
      levels: _levels.map((l) {
        l.calculateSubtotal();
        return l;
      }).toList(),
      addons: _overallAddons,
      taxRate: appState.appSettings?.taxRate ?? 0.0,
      discount: 0.0,
      status: 'draft',
      // NEW: Store base product information
      baseProductId: _baseProduct!.id,
      baseProductName: _baseProduct!.name,
      baseProductUnit: _baseProduct!.unit,
    );

    try {
      await appState.addSimplifiedQuote(newQuote);
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote ${newQuote.quoteNumber} generated!'), backgroundColor: Colors.green),
      );
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
                final products = appState.products.where((p) => p.isActive && !p.isAddon).toList();
                if (products.isEmpty) {
                  return const Text('No base products available. Please add non-addon products.');
                }
                return Column(
                  children: [
                    DropdownButtonFormField<Product>(
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
                                baseQuantity: _currentBaseQuantity, // NEW: Set base quantity
                                includedItems: [],
                              )..calculateSubtotal());
                            }
                          }
                        });
                      },
                      validator: (value) => value == null ? 'Please select a base product' : null,
                    ),
                    if (_baseProduct != null) ...[
                      const SizedBox(height: 16),
                      // NEW: Base quantity input
                      TextFormField(
                        controller: _baseQuantityController,
                        decoration: InputDecoration(
                          labelText: 'Base Product Quantity',
                          border: const OutlineInputBorder(),
                          suffixText: _baseProduct!.unit,
                          helperText: 'Number of ${_baseProduct!.unit} for the base service/product',
                          prefixIcon: Icon(Icons.calculate_outlined, color: Theme.of(context).primaryColor.withOpacity(0.7)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          final quantity = double.tryParse(value);
                          if (quantity != null && quantity > 0) {
                            _updateBaseQuantity(quantity);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter base quantity';
                          final qty = double.tryParse(value);
                          if (qty == null || qty <= 0) return 'Enter a valid positive quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Base Product Summary:',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 8),
                            Text('Product: ${_baseProduct!.name}'),
                            Text('Quantity: ${_currentBaseQuantity.toStringAsFixed(1)} ${_baseProduct!.unit}'),
                            Text('Unit Price: \$${_baseProduct!.unitPrice.toStringAsFixed(2)}/${_baseProduct!.unit}'),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Base Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '\$${(_baseProduct!.unitPrice * _currentBaseQuantity).toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildLevelConfiguration() {
    if (_levels.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '2. Configure Product Levels',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add to All Levels'),
                  onPressed: _showAddItemToAllLevelsDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
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
                            icon: Icon(Icons.add, color: color),
                            tooltip: 'Add Item to ${level.name} Only',
                            onPressed: () => _showAddItemToSpecificLevelDialog(level),
                          ),
                          if (_levels.length > 1)
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
                        decoration: InputDecoration(
                          labelText: 'Unit Price for ${_baseProduct?.name ?? "Base Product"}',
                          prefixText: '\$',
                          suffixText: _baseProduct?.unit ?? 'unit',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
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

                      // NEW: Show base product calculation
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Base Product: ${level.baseQuantity.toStringAsFixed(1)} × \$${level.basePrice.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: color),
                            ),
                            Text(
                              '\$${level.baseProductTotal.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                            ),
                          ],
                        ),
                      ),

                      if (level.includedItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text("Additional Items:", style: TextStyle(fontWeight: FontWeight.w500, color: color.withOpacity(0.9))),
                        ...level.includedItems.map((item) => Card(
                          margin: const EdgeInsets.only(top: 4),
                          child: ListTile(
                            title: Text(item.productName, style: const TextStyle(fontSize: 14)),
                            subtitle: Text('${item.quantity.toStringAsFixed(1)} ${item.unit} @ \$${item.unitPrice.toStringAsFixed(2)} ea.', style: const TextStyle(fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\$${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                                  onPressed: () => setState(() {
                                    level.includedItems.remove(item);
                                    level.calculateSubtotal();
                                  }),
                                ),
                              ],
                            ),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        )),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Level Subtotal: \$${level.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
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
                      id: newLevelId,
                      name: 'Custom Level $nextLevelNum',
                      levelNumber: nextLevelNum,
                      basePrice: _baseProduct?.unitPrice ?? 0.0,
                      baseQuantity: _currentBaseQuantity, // NEW: Set base quantity
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
                        subtitle: Text('${addon.quantity.toStringAsFixed(1)} ${addon.unit} @ \$${addon.unitPrice.toStringAsFixed(2)} ea.'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${addon.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => setState(() => _overallAddons.removeAt(index)),
                            ),
                          ],
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