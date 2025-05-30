// lib/screens/simplified_quote_screen.dart - CLEAN REBUILD

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/roof_scope_data.dart';
import '../models/simplified_quote.dart';
import '../models/quote.dart';
import '../providers/app_state_provider.dart';
import 'simplified_quote_detail_screen.dart';
import '../services/tax_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1.0');
  double _taxRate = 0.0;
  Product? _mainProduct;
  double _mainQuantity = 1.0;
  final List<QuoteLevel> _quoteLevels = [];
  final List<QuoteItem> _addedProducts = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize tax rate from customer address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectTaxRate(context.read<AppStateProvider>());
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2E86AB),
                        Color(0xFF1B5E7F),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text('New Quote: ${widget.customer.name}'),
              actions: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ];
        },
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMainProductSelection(),
                const SizedBox(height: 24),
                if (_mainProduct != null) ...[
                  _buildQuoteLevelsPreview(),
                  const SizedBox(height: 24),
                  _buildAddedProductsList(),
                  const SizedBox(height: 24),
                  _buildGenerateButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainProductSelection() {
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                        'Step 1: Select Main Product',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'This creates your quote levels (Builder/Homeowner/Platinum)',
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
                final mainProducts = appState.products.where((p) =>
                p.isActive && p.pricingType == ProductPricingType.MAIN_DIFFERENTIATOR
                ).toList();

                if (mainProducts.isEmpty) {
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
                        Text(
                          'No Main Products Found',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a main differentiator product first.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    DropdownButtonFormField<Product>(
                      decoration: const InputDecoration(
                        labelText: 'Main Product',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.architecture),
                      ),
                      value: _mainProduct,
                      items: mainProducts.map((product) => DropdownMenuItem(
                        value: product,
                        child: Text(
                          '${product.name} (${product.availableMainLevels.length} levels)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      )).toList(),
                      onChanged: (product) {
                        setState(() {
                          _mainProduct = product;
                          _createQuoteLevels();
                        });
                      },
                      validator: (value) => value == null ? 'Please select a main product' : null,
                    ),

                    if (_mainProduct != null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: const OutlineInputBorder(),
                          suffixText: _mainProduct!.unit,
                          prefixIcon: const Icon(Icons.calculate_outlined),
                          helperText: 'Amount of ${_mainProduct!.name} needed',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          final quantity = double.tryParse(value);
                          if (quantity != null && quantity > 0) {
                            setState(() {
                              _mainQuantity = quantity;
                              _updateQuoteLevelsQuantity();
                            });
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

  Widget _buildQuoteLevelsPreview() {
    if (_quoteLevels.isEmpty) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quote Levels Created',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  Text(
                    '${_mainProduct!.name} (${_mainQuantity.toStringAsFixed(1)} ${_mainProduct!.unit})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _quoteLevels.map((level) {
                      return Container(
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
                              currencyFormat.format(level.baseProductTotal),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedProductsList() {
    return Column(
      children: [
        // Added Products Section
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 2: Add Products',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddProductDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_addedProducts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No additional products added yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Product" to add materials, labor, etc.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Added to ALL quote levels:',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._addedProducts.map((product) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        product.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${product.quantity.toStringAsFixed(1)} ${product.unit} @ ${NumberFormat.currency(symbol: '\$').format(product.unitPrice)} each',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.currency(symbol: '\$').format(product.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'per level',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeProduct(product),
                            tooltip: 'Remove from all levels',
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),

        // Quote Totals Section
        if (_quoteLevels.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTaxRateSection(),  // ADD TAX RATE HERE
          const SizedBox(height: 16),
          _buildQuoteTotalsSection(),
        ],
      ],
    );
  }

  Widget _buildTaxRateSection() {
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
                    initialValue: _taxRate.toStringAsFixed(2),
                    decoration: InputDecoration(
                      labelText: 'Tax Rate (%)',
                      border: const OutlineInputBorder(),
                      suffixText: '%',
                      prefixIcon: const Icon(Icons.calculate),
                      helperText: 'Enter tax rate for this quote',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final rate = double.tryParse(value);
                      if (rate != null && rate >= 0 && rate <= 100) {
                        setState(() {
                          _taxRate = rate;
                          _updateQuoteLevelsQuantity(); // Recalculate totals
                        });
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
                      return ElevatedButton.icon(
                        onPressed: () => _autoDetectTaxRate(appState),
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('Auto-Detect from Address'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            if (_taxRate > 0) ...[
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
                      'Tax rate: ${_taxRate.toStringAsFixed(2)}% will be applied to all quote levels',
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

  Widget _buildQuoteTotalsSection() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Quote Totals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mobile-friendly layout
            Column(
              children: _quoteLevels.map((level) {
                // Calculate tax for this level
                final subtotal = level.subtotal;
                final taxAmount = subtotal * (_taxRate / 100);
                final totalWithTax = subtotal + taxAmount;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Main product
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${_mainProduct!.name} (${_mainQuantity.toStringAsFixed(1)} ${_mainProduct!.unit})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            currencyFormat.format(level.baseProductTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      // Added products
                      ..._addedProducts.map((product) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${product.productName} (${product.quantity.toStringAsFixed(1)} ${product.unit})',
                              ),
                            ),
                            Text(currencyFormat.format(product.totalPrice)),
                          ],
                        ),
                      )),

                      const Divider(),

                      // SUBTOTAL
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SUBTOTAL:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            currencyFormat.format(subtotal),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),

                      // TAX (only show if tax rate > 0)
                      if (_taxRate > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TAX (${_taxRate.toStringAsFixed(2)}%):',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              currencyFormat.format(taxAmount),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalWithTax),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    if (_quoteLevels.isEmpty) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: _generateQuote,
      icon: const Icon(Icons.rocket_launch),
      label: const Text('Generate Quote'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // METHODS
  void _createQuoteLevels() {
    if (_mainProduct == null) return;

    _quoteLevels.clear();
    final mainLevels = _mainProduct!.availableMainLevels;

    for (var i = 0; i < mainLevels.length; i++) {
      final mainLevel = mainLevels[i];

      final quoteLevel = QuoteLevel(
        id: mainLevel.levelId,
        name: mainLevel.levelName,
        levelNumber: i + 1,
        basePrice: mainLevel.price,
        baseQuantity: _mainQuantity,
        includedItems: List.from(_addedProducts),
      );

      quoteLevel.calculateSubtotal();
      _quoteLevels.add(quoteLevel);
    }
  }

  void _updateQuoteLevelsQuantity() {
    for (final level in _quoteLevels) {
      level.baseQuantity = _mainQuantity;
      level.calculateSubtotal();
    }
  }

  void _removeProduct(QuoteItem product) {
    setState(() {
      _addedProducts.remove(product);
      // Update all quote levels
      for (final level in _quoteLevels) {
        level.includedItems.remove(product);
        level.calculateSubtotal();
      }
    });
  }

  // REPLACE the _autoDetectTaxRate() method in simplified_quote_screen.dart
// Around line 570-620

  void _autoDetectTaxRate(AppStateProvider appState) {
    final customer = widget.customer;

    print('🔍 AUTO-DETECTING TAX RATE FOR:');
    print('   Customer: ${customer.name}');
    print('   ZIP: ${customer.zipCode}');
    print('   State: ${customer.stateAbbreviation}');
    print('   City: ${customer.city}');

    // Try to get tax rate from local database
    final detectedRate = TaxService.getTaxRateByAddress(
      city: customer.city,
      stateAbbreviation: customer.stateAbbreviation,
      zipCode: customer.zipCode,
    );

    if (detectedRate != null && detectedRate > 0) {
      // Found rate in database
      setState(() {
        _taxRate = detectedRate;
        _updateQuoteLevelsQuantity(); // Recalculate with new tax rate
      });

      String source = '';
      if (customer.zipCode != null && customer.zipCode!.isNotEmpty) {
        source = 'ZIP ${customer.zipCode}';
      } else if (customer.stateAbbreviation != null) {
        source = 'state ${customer.stateAbbreviation}';
      }

      print('✅ TAX RATE DETECTED: ${detectedRate.toStringAsFixed(2)}% from $source');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tax rate set to ${detectedRate.toStringAsFixed(2)}% from $source'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // No rate found - try fallback to app default or prompt user
      final fallbackRate = appState.appSettings?.taxRate ?? 0.0;

      if (fallbackRate > 0) {
        setState(() {
          _taxRate = fallbackRate;
          _updateQuoteLevelsQuantity();
        });

        print('📝 USING FALLBACK TAX RATE: ${fallbackRate.toStringAsFixed(2)}%');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default tax rate: ${fallbackRate.toStringAsFixed(2)}%'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // No rate found anywhere - prompt user to enter manually
        print('⚠️ NO TAX RATE FOUND - prompting user');
        _showManualTaxRateDialog();
      }
    }
  }

  void _showManualTaxRateDialog() {
    final customer = widget.customer;
    final locationText = customer.zipCode?.isNotEmpty == true
        ? 'ZIP ${customer.zipCode}'
        : customer.stateAbbreviation?.isNotEmpty == true
        ? 'state ${customer.stateAbbreviation}'
        : 'this location';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Rate Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No tax rate found for $locationText in the local database.'),
            const SizedBox(height: 16),
            const Text('You can:'),
            const SizedBox(height: 8),
            const Text('• Enter the tax rate manually for this quote'),
            const Text('• Add this location to your tax database in Settings'),
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
              _showAddTaxRateDialog();
            },
            child: const Text('Add to Database'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Just keep current tax rate (user can manually edit in the field)
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

  void _showAddTaxRateDialog() {
    final customer = widget.customer;
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
              final rateText = taxRateController.text.trim();
              final rate = double.tryParse(rateText);

              if (rate == null || rate < 0 || rate > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid tax rate (0-100%)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Save to database
              if (customer.zipCode?.isNotEmpty == true) {
                await TaxService.setZipCodeRate(customer.zipCode!, rate);
              } else if (customer.stateAbbreviation?.isNotEmpty == true) {
                await TaxService.setStateRate(customer.stateAbbreviation!, rate);
              }

              // Set for current quote
              setState(() {
                _taxRate = rate;
                _updateQuoteLevelsQuantity();
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
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

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        onProductAdded: (productItem) {
          setState(() {
            _addedProducts.add(productItem);
            // Add this product to ALL quote levels equally
            for (final level in _quoteLevels) {
              level.includedItems.add(productItem);
              level.calculateSubtotal();
            }
          });
        },
      ),
    );
  }

  // REPLACE the _generateQuote() method in simplified_quote_screen.dart
// Around line 720-760

  void _generateQuote() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix errors before generating quote'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mainProduct == null || _quoteLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a main product first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = context.read<AppStateProvider>();

      final newQuote = SimplifiedMultiLevelQuote(
        customerId: widget.customer.id,
        roofScopeDataId: widget.roofScopeData?.id,
        levels: _quoteLevels.map((level) {
          level.calculateSubtotal();
          return level;
        }).toList(),
        addons: [],
        taxRate: _taxRate, // 🔧 FIX: Use the quote-specific tax rate instead of global setting
        baseProductId: _mainProduct!.id,
        baseProductName: _mainProduct!.name,
        baseProductUnit: _mainProduct!.unit,
      );

      await appState.addSimplifiedQuote(newQuote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quote ${newQuote.quoteNumber} generated with ${_taxRate.toStringAsFixed(2)}% tax!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SimplifiedQuoteDetailScreen(
              quote: newQuote,
              customer: widget.customer,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ADD PRODUCT DIALOG
class _AddProductDialog extends StatefulWidget {
  final Function(QuoteItem) onProductAdded;

  const _AddProductDialog({required this.onProductAdded});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
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
      if (product.pricingType == ProductPricingType.MAIN_DIFFERENTIATOR) continue;

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