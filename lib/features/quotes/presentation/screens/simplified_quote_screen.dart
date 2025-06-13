import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/roof_scope_data.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/business/quote_extras.dart';
import '../../../media/presentation/widgets/inspection_floating_button.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../widgets/form/main_product_section.dart';
import '../widgets/form/quote_products_section.dart';
import '../widgets/form/quote_generation_section.dart';
import '../../../../app/constants/quote_form_constants.dart';
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
          body: _isLoading ? _buildLoadingState() : _buildMainContent(),
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildMainContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: QuoteFormConstants.appBarHeight,
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
            title: Text(
              _isEditMode
                  ? 'Edit Quote: ${_editingQuote?.quoteNumber ?? ''}'
                  : 'New Quote: ${widget.customer.name}',
            ),
            actions: [
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.all(spacingSM(context) * 4),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ];
      },
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacingSM(context) * 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMainProductSelection(),
            SizedBox(height: spacingXXL(context)),
            if (_mainProduct != null) ...[
              QuoteLevelsPreview(
                quoteLevels: _quoteLevels,
                mainProduct: _mainProduct,
                mainQuantity: _mainQuantity,
                quoteType: _quoteType,
              ),
              SizedBox(height: spacingXXL(context)),
              _buildAddedProductsList(),
              SizedBox(height: spacingXXL(context)),
              PermitsSection(
                permits: _permits,
                noPermitsRequired: _noPermitsRequired,
                onPermitAdded: (permit) => _controller.addPermit(permit),
                onPermitRemoved: (permit) => _controller.removePermit(permit),
                onNoPermitsRequiredChanged: (value) {
                  _noPermitsRequired = value;
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
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return InspectionFloatingButton(
      customer: widget.customer,
      appState: context.read<AppStateProvider>(),
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
      onAutoDetectPressed: () =>
          _autoDetectTaxRate(context.read<AppStateProvider>()),
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

  // METHODS
  void _createQuoteLevels() => _controller.createQuoteLevels();

  void _switchQuoteType(String newType) => _controller.switchQuoteType(newType);

  void _updateQuoteLevelsQuantity() => _controller.updateQuoteLevelsQuantity();

  void _removeProduct(QuoteItem product) => _controller.removeProduct(product);

  void _handleProductChanged(Product? product) {
    setState(() {
      _mainProduct = product;
      _createQuoteLevels();
    });
  }

  void _handleQuantityChanged(double quantity) {
    setState(() {
      _mainQuantity = quantity;
      _updateQuoteLevelsQuantity();
    });
  }

  void _handleTaxRateChanged(double rate) {
    setState(() {
      _taxRate = rate;
      _updateQuoteLevelsQuantity();
    });
  }

  void _autoDetectTaxRate(AppStateProvider appState) =>
      _controller.autoDetectTaxRate(appState);


  void _loadExistingQuoteData() {
    _controller.loadExistingQuoteData(context.read<AppStateProvider>());
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: _buildAddProductDialog,
    );
  }

  Widget _buildAddProductDialog(BuildContext context) {
    return AddProductDialog(
      onProductAdded: (productItem) {
        _controller.addProduct(productItem);
      },
    );
  }

  void _generateQuote() async {
    await _controller.generateQuote(
      context.read<AppStateProvider>(),
      _formKey,
    );
  }
}

