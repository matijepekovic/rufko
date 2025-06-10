// lib/screens/simplified_quote_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/roof_scope_data.dart';
import '../models/simplified_quote.dart';
import '../models/quote.dart';
import '../providers/app_state_provider.dart';
import '../models/quote_extras.dart'; // NEW: For PermitItem and CustomLineItem
import 'package:rufko/screens/inspection_viewer_screen.dart';
import '../theme/rufko_theme.dart';
import '../widgets/quote_type_selector.dart';
import '../widgets/main_product_selection.dart';
import '../widgets/permits_section.dart';
import '../widgets/tax_rate_section.dart';
import '../widgets/quote_totals_section.dart';
import '../controllers/quote_form_controller.dart';

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
  late QuoteFormController _controller;

  double get _taxRate => _controller.taxRate;
  set _taxRate(double v) => _controller.taxRate = v;

  Product? get _mainProduct => _controller.mainProduct;
  set _mainProduct(Product? p) => _controller.mainProduct = p;

  double get _mainQuantity => _controller.mainQuantity;
  set _mainQuantity(double q) => _controller.mainQuantity = q;

  List<QuoteLevel> get _quoteLevels => _controller.quoteLevels;
  List<QuoteItem> get _addedProducts => _controller.addedProducts;

  bool get _isLoading => _controller.isLoading;

  String get _quoteType => _controller.quoteType;

  List<PermitItem> get _permits => _controller.permits;
  bool get _noPermitsRequired => _controller.noPermitsRequired;
  set _noPermitsRequired(bool v) => _controller.noPermitsRequired = v;
  List<CustomLineItem> get _customLineItems => _controller.customLineItems;

  bool get _isEditMode => _controller.isEditMode;
  SimplifiedMultiLevelQuote? get _editingQuote => _controller.editingQuote;

  @override
  void initState() {
    super.initState();

    _controller = QuoteFormController(
      context: context,
      customer: widget.customer,
      roofScopeData: widget.roofScopeData,
      existingQuote: widget.existingQuote,
    );

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
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
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
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
                            PermitsSection(
                              permits: _permits,
                              noPermitsRequired: _noPermitsRequired,
                              onPermitAdded: (permit) {
                                _controller.addPermit(permit);
                              },
                              onPermitRemoved: (permit) {
                                _controller.removePermit(permit);
                              },
                              onNoPermitsRequiredChanged: (value) {
                                _noPermitsRequired = value;
                                if (value) {
                                  _permits.clear();
                                }
                              },
                            ),
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
      },
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
        QuoteTypeSelector(
          quoteType: _quoteType,
          onQuoteTypeChanged: _switchQuoteType,
        ),

        const SizedBox(height: 16),

        MainProductSelection(
          mainProduct: _mainProduct,
          mainQuantity: _mainQuantity,
          quoteType: _quoteType,
          onProductChanged: (product) {
            setState(() {
              _mainProduct = product;
              _createQuoteLevels();
            });
          },
          onQuantityChanged: (quantity) {
            setState(() {
              _mainQuantity = quantity;
              _updateQuoteLevelsQuantity();
            });
          },
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
          TaxRateSection(
            taxRate: _taxRate,
            customer: widget.customer,
            onTaxRateChanged: (rate) {
              setState(() {
                _taxRate = rate;
                _updateQuoteLevelsQuantity();
              });
            },
            onAutoDetectPressed: () =>
                _autoDetectTaxRate(context.read<AppStateProvider>()),
          ),
          const SizedBox(height: 16),
          QuoteTotalsSection(
            quoteLevels: _quoteLevels,
            mainProduct: _mainProduct,
            mainQuantity: _mainQuantity,
            taxRate: _taxRate,
            permits: _permits,
            customLineItems: _customLineItems,
            quoteType: _quoteType,
          ),
        ],
      ],
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

  void _showAddCustomItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomItemDialog(
        onItemAdded: (item) {
          _controller.addCustomLineItem(item);
        },
      ),
    );
  }

  void _removeCustomItem(CustomLineItem item) {
    _controller.removeCustomLineItem(item);
  }

// NEW: Check if permits requirement is satisfied
  bool get _isPermitsRequirementSatisfied {
    return _controller.isPermitsRequirementSatisfied;
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
  void _createQuoteLevels() => _controller.createQuoteLevels();

  void _switchQuoteType(String newType) => _controller.switchQuoteType(newType);

  void _updateQuoteLevelsQuantity() => _controller.updateQuoteLevelsQuantity();

  void _removeProduct(QuoteItem product) => _controller.removeProduct(product);

  // REPLACE the _autoDetectTaxRate() method in simplified_quote_screen.dart
// Around line 570-620

  void _autoDetectTaxRate(AppStateProvider appState) =>
      _controller.autoDetectTaxRate(appState);


// NEW: Load existing quote data for editing
  // NEW: Load existing quote data for editing
  void _loadExistingQuoteData() {
    _controller.loadExistingQuoteData(context.read<AppStateProvider>());
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        onProductAdded: (productItem) {
          _controller.addProduct(productItem);
        },
      ),
    );
  }

  // REPLACE the _generateQuote() method in simplified_quote_screen.dart
// Around line 720-760

  void _generateQuote() async {
    await _controller.generateQuote(
      context.read<AppStateProvider>(),
      _formKey,
    );
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
