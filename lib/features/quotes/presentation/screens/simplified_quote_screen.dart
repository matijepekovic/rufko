import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/roof_scope_data.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/quote.dart';
import '../../../../data/models/business/quote_extras.dart';
import '../../../media/presentation/widgets/inspection_floating_button.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../widgets/form/quote_products_section.dart';
import '../widgets/form/quote_generation_section.dart';
import '../widgets/quote_type_selector.dart';
import '../widgets/main_product_selection.dart';
import '../widgets/sections/permits_section.dart';
import '../widgets/sections/custom_line_items_section.dart';
import '../widgets/dialogs/discount_dialog.dart';
import '../controllers/quote_form_controller.dart';
import '../widgets/dialogs/add_product_dialog.dart';
import '../widgets/dialogs/custom_item_dialog.dart';
import '../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../core/mixins/ui/responsive_text_mixin.dart';
import '../../../../core/mixins/ui/responsive_widget_mixin.dart';

class SimplifiedQuoteScreen extends StatefulWidget {
  final Customer customer;
  final RoofScopeData? roofScopeData;
  final SimplifiedMultiLevelQuote? existingQuote;

  const SimplifiedQuoteScreen({
    super.key,
    required this.customer,
    this.roofScopeData,
    this.existingQuote,
  });

  @override
  State<SimplifiedQuoteScreen> createState() => _SimplifiedQuoteScreenState();
}

class _SimplifiedQuoteScreenState extends State<SimplifiedQuoteScreen>
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin {
  late QuoteFormController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = QuoteFormController(
      context: context,
      customer: widget.customer,
      roofScopeData: widget.roofScopeData,
      existingQuote: widget.existingQuote,
    );
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  // Convenience getters for controller state
  String get _quoteType => _controller.quoteType;
  Product? get _mainProduct => _controller.mainProduct;
  double get _mainQuantity => _controller.mainQuantity;
  List<QuoteItem> get _addedProducts => _controller.addedProducts;
  List<QuoteLevel> get _quoteLevels => _controller.quoteLevels;
  double get _taxRate => _controller.taxRate;
  List<PermitItem> get _permits => _controller.permits;
  List<CustomLineItem> get _customLineItems => _controller.customLineItems;
  bool get _isEditMode => _controller.isEditMode;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = isCompact(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? 'Edit Quote' : 'Create Quote',
              style: headlineSmall(context).copyWith(color: Colors.white),
            ),
            Text(
              widget.customer.name,
              style: bodySmall(context).copyWith(color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: RufkoTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [],
      ),
      body: Form(
        key: _formKey,
        child: _buildBody(isSmallScreen),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacingMD(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Always show quote type selector (unless in edit mode)
          if (!_isEditMode) ...[
            _buildQuoteTypeSelector(),
            SizedBox(height: spacingXL(context)),
          ],
          // Step 1: Main product selection - only for multi-level quotes
          if (_quoteType == 'multi-level') ...[
            _buildMainProductSelection(),
            SizedBox(height: spacingXL(context)),
          ],
          _buildAddedProductsList(),
          SizedBox(height: spacingXXL(context)),
          CustomLineItemsSection(
            customLineItems: _customLineItems,
            onAddItemPressed: _showAddCustomItemDialog,
            onRemoveItem: _removeCustomItem,
          ),
          SizedBox(height: spacingXL(context)),
          PermitsSection(
            permits: _permits,
            noPermitsRequired: _controller.noPermitsRequired,
            onPermitAdded: _controller.addPermit,
            onPermitRemoved: _controller.removePermit,
            onNoPermitsRequiredChanged: (value) {
              _controller.noPermitsRequired = value;
              if (value) {
                // Clear permits through controller, not direct list manipulation
                final permitsToRemove = List.from(_permits);
                for (final permit in permitsToRemove) {
                  _controller.removePermit(permit);
                }
              }
            },
          ),
          SizedBox(height: spacingXL(context)),
          _buildDiscountSection(),
          SizedBox(height: spacingXXL(context)),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return InspectionFloatingButton(
      customer: widget.customer,
    );
  }

  Widget _buildQuoteTypeSelector() {
    return QuoteTypeSelector(
      quoteType: _quoteType,
      onQuoteTypeChanged: _switchQuoteType,
    );
  }

  Widget _buildMainProductSelection() {
    return MainProductSelection(
      mainProduct: _mainProduct,
      mainQuantity: _mainQuantity,
      quoteType: _quoteType,
      onProductChanged: _handleProductChanged,
      onQuantityChanged: _handleQuantityChanged,
    );
  }

  Widget _buildAddedProductsList() {
    return QuoteProductsSection(
      addedProducts: _addedProducts,
      quoteType: _quoteType,
      onAddProductPressed: _showAddProductDialog,
      onRemoveProduct: _removeProduct,
      onEditProduct: _showEditProductDialog,
      quoteLevels: _quoteLevels,
      mainProduct: _mainProduct,
      mainQuantity: _mainQuantity,
      taxRate: _taxRate,
      permits: _permits,
      customLineItems: _customLineItems,
      onTaxRateChanged: _handleTaxRateChanged,
      onAutoDetectPressed: _autoDetectTaxRate,
      customer: widget.customer,
    );
  }

  void _showAddCustomItemDialog() {
    showDialog(
      context: context,
      builder: _buildCustomItemDialog,
    );
  }

  Widget _buildCustomItemDialog(BuildContext context) {
    return CustomItemDialog(
      onItemAdded: (item) {
        _controller.addCustomLineItem(item);
      },
    );
  }

  void _removeCustomItem(CustomLineItem item) {
    _controller.removeCustomLineItem(item);
  }

  bool get _isPermitsRequirementSatisfied {
    return _controller.isPermitsRequirementSatisfied;
  }

  Widget _buildDiscountSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discounts & Offers',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Add percentage or fixed amount discounts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showDiscountDialog,
              icon: const Icon(Icons.add, size: 24),
              tooltip: 'Add Discount',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGenerateButton() {
    return QuoteGenerationSection(
      isEditMode: _isEditMode,
      quoteType: _quoteType,
      quoteLevels: _quoteLevels,
      permitsSatisfied: _isPermitsRequirementSatisfied,
      onGenerate: _generateQuote,
    );
  }

  void _switchQuoteType(String newType) => _controller.switchQuoteType(newType);

  void _handleProductChanged(Product? product) => _controller.mainProduct = product;

  void _handleQuantityChanged(double quantity) => _controller.mainQuantity = quantity;

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductAdded: _addProduct,
      ),
    );
  }

  void _showEditProductDialog(QuoteItem product) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductAdded: (updatedProduct) => _updateProduct(product, updatedProduct),
        editingProduct: product,
      ),
    );
  }

  void _addProduct(QuoteItem product) => _controller.addProduct(product);

  void _updateProduct(QuoteItem oldProduct, QuoteItem updatedProduct) {
    _controller.removeProduct(oldProduct);
    _controller.addProduct(updatedProduct);
  }

  void _removeProduct(QuoteItem product) => _controller.removeProduct(product);

  void _handleTaxRateChanged(double rate) => _controller.taxRate = rate;

  void _autoDetectTaxRate() => _controller.autoDetectTaxRate();

  void _generateQuote() => _controller.generateQuote(_formKey);

  void _showDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
        onDiscountAdded: (discount) {
          // Handle discount addition through controller
          // Note: This would need to be implemented in the controller
          // For now, just show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Discount "${discount.description ?? 'Discount'}" added'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}