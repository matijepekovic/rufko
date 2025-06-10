// lib/screens/simplified_quote_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/roof_scope_data.dart';
import '../models/simplified_quote.dart';
import '../models/quote.dart';
import '../providers/app_state_provider.dart';
import '../models/quote_extras.dart'; // NEW: For PermitItem and CustomLineItem
import '../widgets/inspection_floating_button.dart';
import '../theme/rufko_theme.dart';
import '../widgets/quote_type_selector.dart';
import '../widgets/main_product_selection.dart';
import '../widgets/permits_section.dart';
import '../widgets/tax_rate_section.dart';
import '../widgets/quote_totals_section.dart';
import '../widgets/added_products_list.dart';
import '../widgets/custom_line_items_section.dart';
import '../widgets/quote_levels_preview.dart';
import '../controllers/quote_form_controller.dart';
import '../dialogs/add_product_dialog.dart';
import '../dialogs/custom_item_dialog.dart';

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
                            QuoteLevelsPreview(
                              quoteLevels: _quoteLevels,
                              mainProduct: _mainProduct,
                              mainQuantity: _mainQuantity,
                              quoteType: _quoteType,
                            ),
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
                            CustomLineItemsSection(
                              customLineItems: _customLineItems,
                              onAddItemPressed: _showAddCustomItemDialog,
                              onRemoveItem: _removeCustomItem,
                            ),
                            const SizedBox(height: 24),
                            _buildGenerateButton(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
          floatingActionButton: InspectionFloatingButton(
            customer: widget.customer,
            appState: context.read<AppStateProvider>(),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
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


  Widget _buildAddedProductsList() {
    return Column(
      children: [
        AddedProductsList(
          addedProducts: _addedProducts,
          quoteType: _quoteType,
          onAddProductPressed: _showAddProductDialog,
          onRemoveProduct: _removeProduct,
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






  void _showAddCustomItemDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomItemDialog(
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
      builder: (context) => AddProductDialog(
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

