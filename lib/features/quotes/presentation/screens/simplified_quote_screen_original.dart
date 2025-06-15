import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/roof_scope_data.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/quote.dart';
import '../../../../data/models/business/quote_extras.dart';
import '../../../media/presentation/widgets/inspection_floating_button.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../widgets/form/main_product_section.dart';
import '../widgets/form/quote_products_section.dart';
import '../widgets/form/quote_generation_section.dart';
import '../widgets/sections/permits_section.dart';
import '../widgets/sections/custom_line_items_section.dart';
import '../widgets/quote_levels_preview.dart';
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
          _buildMainProductSelection(),
          SizedBox(height: spacingXL(context)),
          _buildAddedProductsList(),
          if (_quoteType == 'multi-level') ...[
            SizedBox(height: spacingXL(context)),
            QuoteLevelsPreview(
              quoteLevels: _quoteLevels,
              mainProduct: _mainProduct,
              mainQuantity: _mainQuantity,
              quoteType: _quoteType,
            ),
          ],
          SizedBox(height: spacingXL(context)),
          PermitsSection(
            permits: _permits,
            noPermitsRequired: _controller.noPermitsRequired,
            onPermitAdded: _controller.addPermit,
            onPermitRemoved: _controller.removePermit,
            onNoPermitsRequiredChanged: (value) {
              _controller.noPermitsRequired = value;
              if (value) {
                _permits.clear();
              }
            },
          ),
          SizedBox(height: spacingXXL(context)),
          CustomLineItemsSection(
            customLineItems: _customLineItems,
            onAddItemPressed: _showAddCustomItemDialog,
            onRemoveItem: _removeCustomItem,
          ),
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

  Widget _buildMainProductSelection() {
    return MainProductSection(
      quoteType: _quoteType,
      mainProduct: _mainProduct,
      mainQuantity: _mainQuantity,
      onQuoteTypeChanged: _switchQuoteType,
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

  void _addProduct(QuoteItem product) => _controller.addProduct(product);

  void _removeProduct(QuoteItem product) => _controller.removeProduct(product);

  void _handleTaxRateChanged(double rate) => _controller.taxRate = rate;

  void _autoDetectTaxRate() => _controller.autoDetectTaxRate();

  void _generateQuote() => _controller.generateQuote(_formKey);
}