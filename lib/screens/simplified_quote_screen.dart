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
import '../models/quote_extras.dart'; // NEW: For PermitItem and CustomLineItem
import 'package:rufko/screens/inspection_viewer_screen.dart';
import '../theme/rufko_theme.dart';

class SimplifiedQuoteScreen extends StatefulWidget {
  final Customer customer;
  final RoofScopeData? roofScopeData;
  final SimplifiedMultiLevelQuote? existingQuote; // NEW: For editing mode

  const SimplifiedQuoteScreen({
    super.key,
    required this.customer,
    this.roofScopeData,
    this.existingQuote, // NEW: Pass existing quote for editing
  });

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

  // NEW: Quote type selection
  String _quoteType = 'multi-level'; // 'multi-level' or 'single-tier'

  final List<PermitItem> _permits = [];
  bool _noPermitsRequired = false;
  final List<CustomLineItem> _customLineItems = [];

  // NEW: Edit mode detection
  bool get _isEditMode => widget.existingQuote != null;
  SimplifiedMultiLevelQuote? get _editingQuote => widget.existingQuote;

  @override
  void initState() {
    super.initState();

    // NEW: Load existing quote data if in edit mode
    if (_isEditMode) {
      _loadExistingQuoteData();
    } else {
      // Initialize tax rate from customer address for new quotes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoDetectTaxRate(context.read<AppStateProvider>());
      });
    }
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
              backgroundColor: RufkoTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        RufkoTheme.primaryColor,
                        RufkoTheme.primaryDarkColor,
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(_isEditMode
                  ? 'Edit Quote: ${_editingQuote!.quoteNumber}'
                  : 'New Quote: ${widget.customer.name}'),
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
                  _buildPermitsSection(),
                  const SizedBox(height: 24),
                  _buildCustomLineItemsSection(),
                  const SizedBox(height: 24),
                  _buildGenerateButton(),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildInspectionFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildInspectionFloatingButton() {
    // Check if there are any inspection documents for this customer
    final appState = context.read<AppStateProvider>();
    final inspectionDocs = appState.getInspectionDocumentsForCustomer(widget.customer.id);

    if (inspectionDocs.isEmpty) {
      return const SizedBox.shrink(); // Don't show button if no inspection docs
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 60), // Offset to avoid overlapping
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Badge showing document count
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                '${inspectionDocs.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Main button
          FloatingActionButton.extended(
            onPressed: _showInspectionModal,
            icon: const Icon(Icons.assignment),
            label: const Text('Inspection'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 4,
            tooltip: 'View ${inspectionDocs.length} inspection document${inspectionDocs.length == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }

  void _showInspectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inspection Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Reference while building quote',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close inspection viewer',
                    ),
                  ],
                ),
              ),

              // Inspection viewer content - THIS IS THE FIX
              Expanded(
                child: InspectionViewerScreen(
                  customer: widget.customer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainProductSelection() {
    return Column(
      children: [
        // NEW: Quote Type Selection Card
        Card(
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
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize,
                        color: Colors.purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quote Type',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quote type selection
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchQuoteType('multi-level'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _quoteType == 'multi-level' ? Theme.of(context).primaryColor : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _quoteType == 'multi-level' ? Theme.of(context).primaryColor : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.layers,
                                color: _quoteType == 'multi-level' ? Colors.white : Colors.grey[600],
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Multi-Level Quote',
                                style: TextStyle(
                                  color: _quoteType == 'multi-level' ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Builder/Homeowner/Platinum',
                                style: TextStyle(
                                  color: _quoteType == 'multi-level' ? Colors.white70 : Colors.grey[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchQuoteType('single-tier'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _quoteType == 'single-tier' ? Theme.of(context).primaryColor : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _quoteType == 'single-tier' ? Theme.of(context).primaryColor : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.description,
                                color: _quoteType == 'single-tier' ? Colors.white : Colors.grey[600],
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Single-Tier Quote',
                                style: TextStyle(
                                  color: _quoteType == 'single-tier' ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'One price level only',
                                style: TextStyle(
                                  color: _quoteType == 'single-tier' ? Colors.white70 : Colors.grey[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Main Product Selection Card
        Card(
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
                            _quoteType == 'multi-level' ? 'Step 1: Select Main Product' : 'Step 1: Select Product',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _quoteType == 'multi-level'
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
                    // For multi-level: only show main differentiator products
                    // For single-tier: show all active products
                    final availableProducts = _quoteType == 'multi-level'
                        ? appState.products.where((p) =>
                    p.isActive && p.pricingType == ProductPricingType.mainDifferentiator
                    ).toList()
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
                            Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              _quoteType == 'multi-level' ? 'No Main Products Found' : 'No Products Found',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _quoteType == 'multi-level'
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
                            labelText: _quoteType == 'multi-level' ? 'Main Product' : 'Product',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.architecture),
                          ),
                          value: _mainProduct,
                          items: availableProducts.map((product) => DropdownMenuItem(
                            value: product,
                            child: Text(
                              _quoteType == 'multi-level'
                                  ? '${product.name} (${product.availableMainLevels.length} levels)'
                                  : product.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          )).toList(),
                          onChanged: (product) {
                            setState(() {
                              _mainProduct = product;
                              _createQuoteLevels();
                            });
                          },
                          validator: (value) => value == null ? 'Please select a product' : null,
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
        ),
      ],
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
            Row(
              children: [
                Icon(
                  _quoteType == 'multi-level' ? Icons.layers : Icons.description,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _quoteType == 'multi-level' ? 'Quote Levels Created' : 'Quote Created',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _quoteType == 'multi-level' ? Colors.blue.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _quoteType == 'multi-level' ? Colors.blue.shade200 : Colors.green.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_mainProduct!.name} (${_mainQuantity.toStringAsFixed(1)} ${_mainProduct!.unit})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  if (_quoteType == 'multi-level') ...[
                    // Multi-level display (existing)
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
                  ] else ...[
                    // Single-tier display (NEW)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unit Price: ${currencyFormat.format(_mainProduct!.unitPrice)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Quantity: ${_mainQuantity.toStringAsFixed(1)} ${_mainProduct!.unit}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormat.format(_quoteLevels.first.baseProductTotal),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      _quoteType == 'multi-level' ? 'Step 2: Add Products' : 'Step 2: Add Additional Products',
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
                    _quoteType == 'multi-level' ? 'Added to ALL quote levels:' : 'Additional products:',
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
      color: _quoteType == 'multi-level' ? Colors.blue.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: _quoteType == 'multi-level' ? Colors.blue.shade700 : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  _quoteType == 'multi-level' ? 'Quote Totals' : 'Quote Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _quoteType == 'multi-level' ? Colors.blue.shade800 : Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_quoteType == 'multi-level') ...[
              // Multi-level layout (existing)
              Column(
                children: _quoteLevels.map((level) {
                  // Calculate totals including permits and custom items
                  final levelSubtotal = level.subtotal;
                  final permitsTotal = _permits.fold(0.0, (sum, permit) => sum + permit.amount);
                  final taxableCustomItems = _customLineItems.where((item) => item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);
                  final nonTaxableCustomItems = _customLineItems.where((item) => !item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);

                  final taxableSubtotal = levelSubtotal + permitsTotal + taxableCustomItems;
                  final nonTaxableSubtotal = nonTaxableCustomItems;
                  final totalSubtotal = taxableSubtotal + nonTaxableSubtotal;
                  final taxAmount = taxableSubtotal * (_taxRate / 100);
                  final totalWithTax = totalSubtotal + taxAmount;

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

// NEW: Show permits if any
                        if (_permits.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'PERMITS:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(permitsTotal),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                ..._permits.map((permit) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '  ${permit.name}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(permit.amount),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],

// NEW: Show custom line items if any
                        if (_customLineItems.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CUSTOM ITEMS:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(_customLineItems.fold(0.0, (sum, item) => sum + item.amount)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                ..._customLineItems.map((item) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '  ${item.name}${item.isTaxable ? '' : ' (non-taxable)'}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(item.amount),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],

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
                              currencyFormat.format(totalSubtotal),
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
            ] else ...[
              // Single-tier layout (NEW)
              _buildSingleTierTotal(currencyFormat),
            ],
          ],
        ),
      ),
    );
  }

// NEW: Add this helper method right after _buildQuoteTotalsSection
  Widget _buildSingleTierTotal(NumberFormat currencyFormat) {
    final level = _quoteLevels.first;
    final levelSubtotal = level.subtotal;

    // Calculate permits total (taxable)
    final permitsTotal = _permits.fold(0.0, (sum, permit) => sum + permit.amount);

    // Calculate custom items (separate taxable and non-taxable)
    final taxableCustomItems = _customLineItems.where((item) => item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);
    final nonTaxableCustomItems = _customLineItems.where((item) => !item.isTaxable).fold(0.0, (sum, item) => sum + item.amount);

    // Calculate subtotal before tax
    final taxableSubtotal = levelSubtotal + permitsTotal + taxableCustomItems; // Include permits in taxable
    final nonTaxableSubtotal = nonTaxableCustomItems;
    final totalSubtotal = taxableSubtotal + nonTaxableSubtotal;

    // Calculate tax (on taxable items including permits)
    final taxAmount = taxableSubtotal * (_taxRate / 100);
    final totalWithTax = totalSubtotal + taxAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main product
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_mainProduct!.name} (${_mainQuantity.toStringAsFixed(1)} ${_mainProduct!.unit})',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ),
              Text(
                currencyFormat.format(level.baseProductTotal),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          // Added products
          // Added products
          ..._addedProducts.map((product) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${product.productName} (${product.quantity.toStringAsFixed(1)} ${product.unit})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  currencyFormat.format(product.totalPrice),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          )),

// NEW: Show permits if any
          if (_permits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PERMITS:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currencyFormat.format(permitsTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  ..._permits.map((permit) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '  ${permit.name}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          currencyFormat.format(permit.amount),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

// NEW: Show custom line items if any
          if (_customLineItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CUSTOM ITEMS:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currencyFormat.format(_customLineItems.fold(0.0, (sum, item) => sum + item.amount)),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  ..._customLineItems.map((item) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '  ${item.name}${item.isTaxable ? '' : ' (non-taxable)'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          currencyFormat.format(item.amount),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),

          // SUBTOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUBTOTAL:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                currencyFormat.format(totalSubtotal),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),

          // TAX (only show if tax rate > 0)
          if (_taxRate > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TAX (${_taxRate.toStringAsFixed(2)}%):',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  currencyFormat.format(taxAmount),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  currencyFormat.format(totalWithTax),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
// NEW: Permits section
  Widget _buildPermitsSection() {
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Permits (Required)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // No permits required checkbox
            CheckboxListTile(
              title: const Text('No permits required for this project'),
              subtitle: Text(
                'Check this if no building permits are needed',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              value: _noPermitsRequired,
              onChanged: (value) {
                setState(() {
                  _noPermitsRequired = value ?? false;
                  if (_noPermitsRequired) {
                    _permits.clear(); // Clear permits if none required
                  }
                });
              },
              activeColor: Colors.green,
            ),

            if (!_noPermitsRequired) ...[
              const Divider(),

              // Add permit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Required Permits:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddPermitDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Permit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              // Permits list
              if (_permits.isEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No permits added yet. Add permits or check "No permits required"',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                ..._permits.map((permit) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: Icon(Icons.assignment, color: Colors.orange.shade700),
                    title: Text(permit.name),
                    subtitle: permit.description?.isNotEmpty == true
                        ? Text(permit.description!)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '\$').format(permit.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removePermit(permit),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ],

            // Show permit total if any permits
            if (_permits.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Permits:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(
                      _permits.fold(0.0, (sum, permit) => sum + permit.amount),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

// NEW: Custom line items section
  Widget _buildCustomLineItemsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_box,
                          color: Colors.purple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Custom Line Items (Optional)',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCustomItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_customLineItems.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_box_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No custom items added',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add custom fees, rentals, or special services',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Custom items:',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ..._customLineItems.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.purple.shade50,
                child: ListTile(
                  leading: Icon(
                    item.isTaxable ? Icons.monetization_on : Icons.money_off,
                    color: Colors.purple.shade700,
                  ),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.description?.isNotEmpty == true)
                        Text(item.description!),
                      Text(
                        item.isTaxable ? 'Taxable' : 'Non-taxable',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: '\$').format(item.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeCustomItem(item),
                      ),
                    ],
                  ),
                  isThreeLine: item.description?.isNotEmpty == true,
                ),
              )),

              // Show custom items total
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Custom Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(
                      _customLineItems.fold(0.0, (sum, item) => sum + item.amount),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  void _showAddPermitDialog() {
    showDialog(
      context: context,
      builder: (context) => _PermitDialog(
        onPermitAdded: (permit) {
          setState(() {
            _permits.add(permit);
          });
        },
      ),
    );
  }

  void _removePermit(PermitItem permit) {
    setState(() {
      _permits.remove(permit);
    });
  }

  void _showAddCustomItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomItemDialog(
        onItemAdded: (item) {
          setState(() {
            _customLineItems.add(item);
          });
        },
      ),
    );
  }

  void _removeCustomItem(CustomLineItem item) {
    setState(() {
      _customLineItems.remove(item);
    });
  }

// NEW: Check if permits requirement is satisfied
  bool get _isPermitsRequirementSatisfied {
    return _noPermitsRequired || _permits.isNotEmpty;
  }
  Widget _buildGenerateButton() {
    if (_quoteLevels.isEmpty) return const SizedBox.shrink();

    String buttonText;
    if (_isEditMode) {
      buttonText = _quoteType == 'single-tier' ? 'Update Single-Tier Quote' : 'Update Multi-Level Quote';
    } else {
      buttonText = _quoteType == 'single-tier' ? 'Generate Single-Tier Quote' : 'Generate Multi-Level Quote';
    }

    // Check if permits requirement is satisfied
    final permitsSatisfied = _isPermitsRequirementSatisfied;

    return Column(
      children: [
        // Show validation warning if permits not satisfied
        if (!permitsSatisfied) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permits required: Please add permits or check "No permits required"',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Generate button
        ElevatedButton.icon(
          onPressed: permitsSatisfied ? _generateQuote : null, // Disable if permits not satisfied
          icon: Icon(_isEditMode ? Icons.save : Icons.rocket_launch),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: permitsSatisfied
                ? (_quoteType == 'single-tier' ? Colors.green.shade600 : Theme.of(context).primaryColor)
                : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // METHODS
  void _createQuoteLevels() {
    if (_mainProduct == null) return;

    _quoteLevels.clear();

    if (_quoteType == 'multi-level') {
      // Multi-level logic (existing)
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
    } else {
      // Single-tier logic (NEW)
      final quoteLevel = QuoteLevel(
        id: 'single-tier-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Quote',
        levelNumber: 1,
        basePrice: _mainProduct!.unitPrice,
        baseQuantity: _mainQuantity,
        includedItems: List.from(_addedProducts),
      );

      quoteLevel.calculateSubtotal();
      _quoteLevels.add(quoteLevel);
    }
  }

  void _switchQuoteType(String newType) {
    if (_quoteType == newType) return; // No change needed

    setState(() {
      _quoteType = newType;

      // Reset everything when switching types
      _mainProduct = null;
      _quoteLevels.clear();
      _addedProducts.clear();
      _quantityController.text = '1.0';
      _mainQuantity = 1.0;

      // NEW: Reset permits and custom items too
      _permits.clear();
      _noPermitsRequired = false;
      _customLineItems.clear();
    });

    debugPrint('🔄 Switched to $_quoteType quote type - form reset');
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

    debugPrint('🔍 AUTO-DETECTING TAX RATE FOR:');
    debugPrint('   Customer: ${customer.name}');
    debugPrint('   ZIP: ${customer.zipCode}');
    debugPrint('   State: ${customer.stateAbbreviation}');
    debugPrint('   City: ${customer.city}');

    // Try to get tax rate from local database
    final detectedRate = appState.detectTaxRate(
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

      debugPrint('✅ TAX RATE DETECTED: ${detectedRate.toStringAsFixed(2)}% from $source');

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

        debugPrint('📝 USING FALLBACK TAX RATE: ${fallbackRate.toStringAsFixed(2)}%');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default tax rate: ${fallbackRate.toStringAsFixed(2)}%'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // No rate found anywhere - prompt user to enter manually
        debugPrint('⚠️ NO TAX RATE FOUND - prompting user');
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

              // Save to database
              if (customer.zipCode?.isNotEmpty == true) {
                await appState.saveZipCodeTaxRate(customer.zipCode!, rate);
              } else if (customer.stateAbbreviation?.isNotEmpty == true) {
                await appState.saveStateTaxRate(customer.stateAbbreviation!, rate);
              }

              // Set for current quote
              setState(() {
                _taxRate = rate;
                _updateQuoteLevelsQuantity();
              });

              navigator.pop();

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

// NEW: Load existing quote data for editing
  // NEW: Load existing quote data for editing
  void _loadExistingQuoteData() {
    if (_editingQuote == null) return;

    final appState = context.read<AppStateProvider>();

    // Load basic quote data
    _taxRate = _editingQuote!.taxRate;

    // Determine quote type based on existing quote structure
    if (_editingQuote!.levels.length == 1 && _editingQuote!.levels.first.name == 'Quote') {
      _quoteType = 'single-tier';
    } else {
      _quoteType = 'multi-level';
    }

    // Find the main product
    if (_editingQuote!.baseProductId != null) {
      _mainProduct = appState.products.firstWhere(
            (p) => p.id == _editingQuote!.baseProductId,
        orElse: () => throw Exception('Main product not found'),
      );
    }

    // Load quote levels (these contain the main product quantity and additional items)
    _quoteLevels.clear();
    _quoteLevels.addAll(_editingQuote!.levels);

    // Get main quantity from first level
    if (_quoteLevels.isNotEmpty) {
      _mainQuantity = _quoteLevels.first.baseQuantity;
      _quantityController.text = _mainQuantity.toStringAsFixed(1);
    }

    // Load additional products from the first level (they should be the same across all levels)
    // Load additional products from the first level (they should be the same across all levels)
    _addedProducts.clear();
    if (_quoteLevels.isNotEmpty) {
      _addedProducts.addAll(_quoteLevels.first.includedItems);
    }

// NEW: Load permits and custom line items
    _permits.clear();
    _permits.addAll(_editingQuote!.permits);
    _noPermitsRequired = _editingQuote!.noPermitsRequired;

    _customLineItems.clear();
    _customLineItems.addAll(_editingQuote!.customLineItems);

    setState(() {});

    debugPrint('📝 Loaded existing quote data:');
    debugPrint('   Quote Type: $_quoteType');
    debugPrint('   Tax Rate: $_taxRate%');
    debugPrint('   Main Product: ${_mainProduct?.name}');
    debugPrint('   Main Quantity: $_mainQuantity');
    debugPrint('   Quote Levels: ${_quoteLevels.length}');
    debugPrint('   Additional Products: ${_addedProducts.length}');
    debugPrint('   Permits: ${_permits.length}');
    debugPrint('   No Permits Required: $_noPermitsRequired');
    debugPrint('   Custom Line Items: ${_customLineItems.length}');
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
        SnackBar(
          content: Text(_isEditMode ? 'Please fix errors before updating quote' : 'Please fix errors before generating quote'),
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

      if (_isEditMode) {
        // UPDATE existing quote
        // UPDATE existing quote
        final updatedQuote = _editingQuote!;
        updatedQuote.levels = _quoteLevels.map((level) {
          level.calculateSubtotal();
          return level;
        }).toList();
        updatedQuote.taxRate = _taxRate;
        updatedQuote.baseProductId = _mainProduct!.id;
        updatedQuote.baseProductName = _mainProduct!.name;
        updatedQuote.baseProductUnit = _mainProduct!.unit;
        updatedQuote.roofScopeDataId = widget.roofScopeData?.id;
        updatedQuote.permits = List.from(_permits); // NEW: Update permits
        updatedQuote.noPermitsRequired = _noPermitsRequired; // NEW: Update permit flag
        updatedQuote.customLineItems = List.from(_customLineItems); // NEW: Update custom items
        updatedQuote.updatedAt = DateTime.now();

        await appState.updateSimplifiedQuote(updatedQuote);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_quoteType == 'single-tier' ? 'Single-tier' : 'Multi-level'} quote ${updatedQuote.quoteNumber} updated with ${_taxRate.toStringAsFixed(2)}% tax!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SimplifiedQuoteDetailScreen(
                quote: updatedQuote,
                customer: widget.customer,
              ),
            ),
          );
        }
      } else {
        // CREATE new quote
        // CREATE new quote
        final newQuote = SimplifiedMultiLevelQuote(
          customerId: widget.customer.id,
          roofScopeDataId: widget.roofScopeData?.id,
          levels: _quoteLevels.map((level) {
            level.calculateSubtotal();
            return level;
          }).toList(),
          addons: [],
          taxRate: _taxRate,
          baseProductId: _mainProduct!.id,
          baseProductName: _mainProduct!.name,
          baseProductUnit: _mainProduct!.unit,
          permits: List.from(_permits), // NEW: Add permits
          noPermitsRequired: _noPermitsRequired, // NEW: Add permit flag
          customLineItems: List.from(_customLineItems), // NEW: Add custom items
        );

        await appState.addSimplifiedQuote(newQuote);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_quoteType == 'single-tier' ? 'Single-tier' : 'Multi-level'} quote ${newQuote.quoteNumber} generated with ${_taxRate.toStringAsFixed(2)}% tax!'),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Error updating ${_quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e'
                : 'Error generating ${_quoteType == 'single-tier' ? 'single-tier' : 'multi-level'} quote: $e'),
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

}// NEW: Permit dialog
class _PermitDialog extends StatefulWidget {
  final Function(PermitItem) onPermitAdded;

  const _PermitDialog({required this.onPermitAdded});

  @override
  State<_PermitDialog> createState() => _PermitDialogState();
}

class _PermitDialogState extends State<_PermitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Permit',
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Permit Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assignment),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final amount = double.tryParse(value!);
                      if (amount == null || amount < 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    onPressed: _addPermit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Add Permit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addPermit() {
    if (!_formKey.currentState!.validate()) return;

    final permit = PermitItem(
      name: _nameController.text,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    widget.onPermitAdded(permit);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// NEW: Custom item dialog
class _CustomItemDialog extends StatefulWidget {
  final Function(CustomLineItem) onItemAdded;

  const _CustomItemDialog({required this.onItemAdded});

  @override
  State<_CustomItemDialog> createState() => _CustomItemDialogState();
}

class _CustomItemDialogState extends State<_CustomItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isTaxable = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.add_box, color: Colors.purple),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Custom Line Item',
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final amount = double.tryParse(value!);
                      if (amount == null || amount < 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Taxable Item'),
                    subtitle: const Text('Include this item in tax calculations'),
                    value: _isTaxable,
                    onChanged: (value) => setState(() => _isTaxable = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    onPressed: _addCustomItem,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text('Add Item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomItem() {
    if (!_formKey.currentState!.validate()) return;

    final item = CustomLineItem(
      name: _nameController.text,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      isTaxable: _isTaxable,
    );

    widget.onItemAdded(item);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}