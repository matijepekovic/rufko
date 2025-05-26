// lib/screens/simplified_quote_screen.dart - ENHANCED FOR 3-TIER PRODUCTS

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
  Product? _mainDifferentiatorProduct; // The product that sets quote columns
  final List<QuoteLevel> _levels = [];
  final List<QuoteItem> _overallAddons = [];
  final List<Product> _selectedSubLeveledProducts = []; // Products with independent options
  final List<Product> _selectedSimpleProducts = []; // Same-price-everywhere products
  bool _isLoading = false;

  final _baseQuantityController = TextEditingController(text: '1.0');
  double _currentBaseQuantity = 1.0;
  final _screenFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _baseQuantityController.dispose();
    super.dispose();
  }

  void _updateBaseQuantity(double newQuantity) {
    setState(() {
      _currentBaseQuantity = newQuantity;
      for (final level in _levels) {
        level.baseQuantity = newQuantity;
        level.calculateSubtotal();
      }
    });
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
              _buildMainDifferentiatorSelection(),
              const SizedBox(height: 24),
              if (_mainDifferentiatorProduct != null) _buildLevelConfiguration(),
              const SizedBox(height: 24),
              if (_mainDifferentiatorProduct != null) _buildSubLeveledProductsSection(),
              const SizedBox(height: 24),
              if (_mainDifferentiatorProduct != null) _buildSimpleProductsSection(),
              const SizedBox(height: 24),
              if (_mainDifferentiatorProduct != null) _buildOverallAddonSelection(),
              const SizedBox(height: 32),
              if (_mainDifferentiatorProduct != null && _levels.isNotEmpty)
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

  Widget _buildMainDifferentiatorSelection() {
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.roofing, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 1. Select Main Product (Sets Quote Columns)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'This product will create Builder/Homeowner/Premium columns',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                final mainDifferentiators = appState.products.where((p) =>
                p.isActive && p.pricingType == ProductPricingType.MAIN_DIFFERENTIATOR
                ).toList();

                if (mainDifferentiators.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 48),
                        const SizedBox(height: 8),
                        Text('No Main Differentiator Products Found',
                            style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Create a product with "Main Differentiator" type first.',
                            style: TextStyle(color: Colors.orange.shade700)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/products'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Main Product'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    DropdownButtonFormField<Product>(
                      decoration: const InputDecoration(
                        labelText: 'Main Product (Sets Quote Structure)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.architecture),
                      ),
                      value: _mainDifferentiatorProduct,
                      items: mainDifferentiators.map((product) => DropdownMenuItem(
                        value: product,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('${product.availableMainLevels.length} levels: ${product.availableMainLevels.map((l) => l.levelName).join(", ")}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      )).toList(),
                      onChanged: (product) {
                        setState(() {
                          _mainDifferentiatorProduct = product;
                          _levels.clear();
                          if (product != null) {
                            _initializeLevelsFromMainProduct(appState, product);
                          }
                        });
                      },
                      validator: (value) => value == null ? 'Please select a main product' : null,
                    ),
                    if (_mainDifferentiatorProduct != null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _baseQuantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: const OutlineInputBorder(),
                          suffixText: _mainDifferentiatorProduct!.unit,
                          helperText: 'Amount of ${_mainDifferentiatorProduct!.name} needed',
                          prefixIcon: const Icon(Icons.calculate_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          final quantity = double.tryParse(value);
                          if (quantity != null && quantity > 0) {
                            _updateBaseQuantity(quantity);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter quantity';
                          final qty = double.tryParse(value);
                          if (qty == null || qty <= 0) return 'Enter a valid positive quantity';
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

  Widget _buildSubLeveledProductsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final subLeveledProducts = appState.products.where((p) =>
        p.isActive && p.pricingType == ProductPricingType.SUB_LEVELED
        ).toList();

        if (subLeveledProducts.isEmpty) return const SizedBox.shrink();

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
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune, color: Colors.orange.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🌧️ 2. Select Optional Products (Independent Choices)',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Each has internal options - customer picks ONE per product',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...subLeveledProducts.map((product) => _buildSubLeveledProductCard(product)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddSubLeveledProductDialog(subLeveledProducts),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sub-Leveled Product'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubLeveledProductCard(Product product) {
    final isSelected = _selectedSubLeveledProducts.any((p) => p.id == product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? Colors.orange.shade300 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.orange.shade50 : Colors.white,
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSelected ? Colors.orange.shade600 : Colors.grey.shade400,
        ),
        title: Text(product.name),
        subtitle: Text('${product.availableSubLevels.length} options: ${product.availableSubLevels.map((l) => l.levelName).join(", ")}'),
        trailing: isSelected ? IconButton(
          icon: Icon(Icons.remove_circle, color: Colors.red.shade400),
          onPressed: () => setState(() => _selectedSubLeveledProducts.removeWhere((p) => p.id == product.id)),
        ) : null,
        onTap: isSelected ? null : () => setState(() => _selectedSubLeveledProducts.add(product)),
      ),
    );
  }

  Widget _buildSimpleProductsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final simpleProducts = appState.products.where((p) =>
        p.isActive && p.pricingType == ProductPricingType.SIMPLE && !p.isAddon
        ).toList();

        if (simpleProducts.isEmpty) return const SizedBox.shrink();

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
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.build, color: Colors.green.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👷 3. Add Supporting Materials & Labor',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Same price across all quote levels',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedSimpleProducts.isEmpty)
                  const Center(child: Text('No supporting products added yet', style: TextStyle(color: Colors.grey)))
                else
                  ..._selectedSimpleProducts.map((product) => _buildSimpleProductItem(product)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddSimpleProductDialog(simpleProducts),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material/Labor'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleProductItem(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(product.name),
        subtitle: Text('\$${product.unitPrice.toStringAsFixed(2)}/${product.unit}'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          onPressed: () => setState(() => _selectedSimpleProducts.removeWhere((p) => p.id == product.id)),
        ),
      ),
    );
  }

  // NEW: Initialize levels from main differentiator product
  void _initializeLevelsFromMainProduct(AppStateProvider appState, Product mainProduct) {
    final mainLevels = mainProduct.availableMainLevels;

    for (var i = 0; i < mainLevels.length; i++) {
      final mainLevel = mainLevels[i];

      _levels.add(QuoteLevel(
        id: mainLevel.levelId,
        name: mainLevel.levelName,
        levelNumber: i + 1,
        basePrice: mainLevel.price,
        baseQuantity: _currentBaseQuantity,
        includedItems: [],
      )..calculateSubtotal());
    }
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
              '📊 Quote Level Preview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // FIXED: Simple preview instead of broken DataTable
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
                  Text(
                    '${_mainDifferentiatorProduct?.name ?? 'Main Product'} (${_currentBaseQuantity.toStringAsFixed(1)} ${_mainDifferentiatorProduct?.unit ?? 'units'})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _levels.map((level) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            level.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${(level.basePrice * level.baseQuantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
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
              '➕ 4. Optional Add-ons (for entire quote)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_overallAddons.isEmpty)
              const Center(child: Text('No optional add-ons selected yet.', style: TextStyle(color: Colors.grey)))
            else
              ..._overallAddons.map((addon) => Card(
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
                        onPressed: () => setState(() => _overallAddons.remove(addon)),
                      ),
                    ],
                  ),
                ),
              )),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Optional Add-on'),
              onPressed: _showAddOptionalAddonDialog,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showAddSubLeveledProductDialog(List<Product> availableProducts) {
    // Implementation for adding sub-leveled products
  }

  void _showAddSimpleProductDialog(List<Product> availableProducts) {
    // Implementation for adding simple products
  }

  void _showAddOptionalAddonDialog() {
    // Implementation for adding optional addons
  }

  void _generateQuote() async {
    if (!(_screenFormKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct errors before generating.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_mainDifferentiatorProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a main product.'), backgroundColor: Colors.red),
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
      baseProductId: _mainDifferentiatorProduct!.id,
      baseProductName: _mainDifferentiatorProduct!.name,
      baseProductUnit: _mainDifferentiatorProduct!.unit,
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
}