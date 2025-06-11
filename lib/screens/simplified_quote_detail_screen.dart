// lib/screens/simplified_quote_detail_screen.dart - ENHANCED WITH DISCOUNTS

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/pdf_generation_controller.dart';
import '../controllers/quote_detail_controller.dart';

import '../models/customer.dart';
import '../models/simplified_quote.dart';
import '../providers/app_state_provider.dart';
import '../theme/rufko_theme.dart';
import '../widgets/discounts_section.dart';
import '../widgets/level_details_card.dart';
import '../widgets/level_selector_card.dart';
import '../widgets/quote_header_card.dart';
import '../widgets/quote_total_card.dart';
import '../widgets/adaptive_quote_card.dart';
import '../widgets/responsive_level_grid.dart';
import '../widgets/adaptive_action_button.dart';
import '../mixins/responsive_breakpoints_mixin.dart';
import '../mixins/responsive_dimensions_mixin.dart';
import '../mixins/responsive_spacing_mixin.dart';
import '../mixins/responsive_text_mixin.dart';
import '../mixins/responsive_widget_mixin.dart';
import '../mixins/responsive_layout_mixin.dart';

import 'simplified_quote_screen.dart';

class SimplifiedQuoteDetailScreen extends StatefulWidget {
  final SimplifiedMultiLevelQuote quote;
  final Customer customer;

  const SimplifiedQuoteDetailScreen({
    super.key,
    required this.quote,
    required this.customer,
  });

  @override
  State<SimplifiedQuoteDetailScreen> createState() =>
      _SimplifiedQuoteDetailScreenState();
}

class _SimplifiedQuoteDetailScreenState
    extends State<SimplifiedQuoteDetailScreen>
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin,
        ResponsiveLayoutMixin {
  late final QuoteDetailController _controller;
  late PDFGenerationController _pdfController;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _controller = QuoteDetailController(
      quote: widget.quote,
      customer: widget.customer,
    );
    _pdfController = PDFGenerationController(
      context: context,
      quote: widget.quote,
      customer: widget.customer,
      selectedLevelId: _controller.selectedLevelId,
    );
    _controller.addListener(() {
      setState(() {});
      _pdfController.selectedLevelId = _controller.selectedLevelId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        visualDensity: responsiveValue(
          context,
          mobile: VisualDensity.compact,
          tablet: VisualDensity.standard,
          desktop: VisualDensity.comfortable,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: responsiveValue(
                context,
                mobile: 100,
                tablet: 120,
                desktop: 140,
              ),
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
              title: Text('Quote ${widget.quote.quoteNumber}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.preview),
                  onPressed: _pdfController.previewPdf,
                  color: Colors.white,
                  tooltip: 'Preview PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editQuote,
                  color: Colors.white,
                  tooltip: 'Edit Quote',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (action) => _controller.handleMenuAction(
                      context, action, _pdfController),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'generate_pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 18),
                          SizedBox(width: 8),
                          Text('Generate PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Quote',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
        body: windowClassBuilder(
          context: context,
          compact: _buildMobileLayout(),
          medium: _buildTabletLayout(),
          expanded: _buildDesktopLayout(),
        ),
      ),
    ),
  );
  }


  Widget _buildQuoteHeader() {
    return QuoteHeaderCard(
      quote: widget.quote,
      customer: widget.customer,
    );
  }

  Widget _buildLevelSelector() {
    return responsiveBuilder(
      context: context,
      mobile: _buildMobileLevelSelector(),
      tablet: _buildGridLevelSelector(columns: 2),
      desktop: _buildGridLevelSelector(columns: 3),
    );
  }

  Widget _buildMobileLevelSelector() {
    return LevelSelectorCard(
      levels: widget.quote.levels,
      selectedLevelId: _controller.selectedLevelId,
      onLevelSelected: _controller.selectLevel,
      currencyFormat: _currencyFormat,
      getTotalForLevel: widget.quote.getDisplayTotalForLevel,
    );
  }

  Widget _buildGridLevelSelector({required int columns}) {
    return AdaptiveQuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Quote Level:',
            style: titleMedium(context).copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacingLG(context)),
          ResponsiveLevelGrid(
            columns: columns,
            children: widget.quote.levels.map((level) {
              final isSelected = _controller.selectedLevelId == level.id;
              final total = widget.quote.getDisplayTotalForLevel(level.id);
              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(level.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _currencyFormat.format(total),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _controller.selectLevel(level.id);
                  }
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle:
                    TextStyle(color: isSelected ? Colors.white : null),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedLevelDetails() {
    final level = widget.quote.levels
        .firstWhere((l) => l.id == _controller.selectedLevelId!);
    return LevelDetailsCard(
      level: level,
      quote: widget.quote,
      currencyFormat: _currencyFormat,
    );
  }

  Widget _buildAddonsSection() {
    if (widget.quote.addons.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdaptiveQuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optional Add-ons:',
            style: titleMedium(context).copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacingLG(context)),
          ...widget.quote.addons.map(
            (addon) => ListTile(
              dense: true,
              title: Text(addon.productName),
              subtitle: Text(
                '${addon.quantity.toStringAsFixed(1)} ${addon.unit} @ ${_currencyFormat.format(addon.unitPrice)} each',
              ),
              trailing: Text(
                _currencyFormat.format(addon.totalPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add-ons Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _currencyFormat.format(
                  widget.quote.addons.fold(0.0, (sum, addon) => sum + addon.totalPrice),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountsSection() {
    return DiscountsSection(
      discounts: widget.quote.discounts,
      selectedLevelId: _controller.selectedLevelId,
      quote: widget.quote,
      onAddDiscount: _addDiscount,
      onRemoveDiscount: _removeDiscount,
      currencyFormat: _currencyFormat,
    );
  }

  // Discount item and summary UI moved to DiscountsSection widget

  Widget _buildTotalSection() {
    if (_controller.selectedLevelId == null) return const SizedBox.shrink();
    return QuoteTotalCard(
      quote: widget.quote,
      selectedLevelId: _controller.selectedLevelId!,
      currencyFormat: _currencyFormat,
    );
  }

  Widget _buildActionButtons() {
    return windowClassBuilder(
      context: context,
      compact: _buildStackedButtons(),
      medium: _buildRowButtons(),
      expanded: _buildFixedSidebarButtons(),
    );
  }

  Widget _buildStackedButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveActionButton(
          onPressed: _pdfController.generatePdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: 'Generate PDF',
        ),
        SizedBox(height: spacingMD(context)),
        AdaptiveActionButton(
          onPressed: () => _controller.updateQuoteStatus(context),
          icon: const Icon(Icons.send),
          label: _controller.getStatusButtonText(),
          backgroundColor: RufkoTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildRowButtons() {
    return Row(
      children: [
        Expanded(
          child: AdaptiveActionButton(
            onPressed: _pdfController.generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: 'Generate PDF',
          ),
        ),
        SizedBox(width: spacingLG(context)),
        Expanded(
          child: AdaptiveActionButton(
            onPressed: () => _controller.updateQuoteStatus(context),
            icon: const Icon(Icons.send),
            label: _controller.getStatusButtonText(),
            backgroundColor: RufkoTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFixedSidebarButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveActionButton(
          onPressed: _pdfController.generatePdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: 'Generate PDF',
        ),
        SizedBox(height: spacingLG(context)),
        AdaptiveActionButton(
          onPressed: () => _controller.updateQuoteStatus(context),
          icon: const Icon(Icons.send),
          label: _controller.getStatusButtonText(),
          backgroundColor: RufkoTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isExpanded(context) ? 1200 : double.infinity,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuoteHeader(),
          SizedBox(height: spacingXL(context)),
          _buildLevelSelector(),
          SizedBox(height: spacingXL(context)),
          if (_controller.selectedLevelId != null) _buildSelectedLevelDetails(),
          SizedBox(height: spacingXL(context)),
          _buildAddonsSection(),
          SizedBox(height: spacingXL(context)),
          _buildDiscountsSection(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTotalSection(),
        SizedBox(height: spacingXL(context)),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainContent(),
          SizedBox(height: spacingXXL(context)),
          _buildSidebar(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: _buildMainContent(),
          ),
        ),
        SizedBox(width: spacingLG(context)),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: _buildSidebar(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: _buildMainContent(),
          ),
        ),
        SizedBox(width: spacingLG(context)),
        SizedBox(
          width: 350,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: _buildSidebar(),
          ),
        ),
      ],
    );
  }

  void _addDiscount() {
    showDialog(
      context: context,
      builder: (context) => _DiscountDialog(
        onDiscountAdded: (discount) =>
            _controller.addDiscount(context, discount),
      ),
    );
  }

  void _removeDiscount(String discountId) {
    _controller.removeDiscount(context, discountId);
  }

  void _editQuote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteScreen(
          customer: widget.customer,
          existingQuote: widget.quote, // Pass the quote to edit
          roofScopeData: widget.quote.roofScopeDataId != null
              ? context
                  .read<AppStateProvider>()
                  .roofScopeDataList
                  .where((rs) => rs.id == widget.quote.roofScopeDataId)
                  .firstOrNull
              : null,
        ),
      ),
    );
  }

  // PDF generation, template selection and status updates are handled
  // by the dedicated controllers for clarity.
}

// Discount creation dialog
class _DiscountDialog extends StatefulWidget {
  final Function(QuoteDiscount) onDiscountAdded;

  const _DiscountDialog({required this.onDiscountAdded});

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog>
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin,
        ResponsiveLayoutMixin {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'percentage';
  bool _applyToAddons = true;
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: responsiveValue(
          context,
          mobile: screenWidth(context) * 0.9,
          tablet: 500,
          desktop: 600,
        ),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clean Header - matching your blue theme
            Container(
              padding: cardPadding(context),
              decoration: const BoxDecoration(
                color: RufkoTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.white, size: 24),
                  SizedBox(width: spacingMD(context)),
                  Expanded(
                    child: Text(
                      'Add Discount',
                      style: titleMedium(context).copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: cardPadding(context),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Discount Type Selection
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Discount Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'percentage',
                              child: Text('Percentage Discount')),
                          DropdownMenuItem(
                              value: 'fixed_amount',
                              child: Text('Fixed Amount Discount')),
                          DropdownMenuItem(
                              value: 'voucher', child: Text('Voucher Code')),
                        ],
                        onChanged: (value) => setState(() => _type = value!),
                      ),

                      SizedBox(height: spacingLG(context)),

                      // Value Input
                      TextFormField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          labelText: _type == 'percentage'
                              ? 'Percentage (%)'
                              : 'Amount (\$)',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(_type == 'percentage'
                              ? Icons.percent
                              : Icons.attach_money),
                          suffixText: _type == 'percentage' ? '%' : null,
                          prefixText: _type == 'fixed_amount' ? '\$ ' : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final num = double.tryParse(value);
                          if (num == null || num <= 0) {
                            return 'Enter valid positive number';
                          }
                          if (_type == 'percentage' && num > 100) {
                            return 'Cannot exceed 100%';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: spacingLG(context)),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),

                      // Voucher Code (conditional)
                      if (_type == 'voucher') ...[
                        SizedBox(height: spacingLG(context)),
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Voucher Code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.confirmation_number),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Code required for vouchers'
                              : null,
                        ),
                      ],

                      SizedBox(height: spacingXL(context)),

                      // Options
                      Card(
                        elevation: 0,
                        color: Colors.grey[50],
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Apply to Add-ons'),
                              subtitle: const Text(
                                  'Include add-on products in discount'),
                              value: _applyToAddons,
                              onChanged: (value) =>
                                  setState(() => _applyToAddons = value),
                            ),
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Expiry Date'),
                              subtitle: Text(
                                _expiryDate != null
                                    ? DateFormat('MMM dd, yyyy')
                                        .format(_expiryDate!)
                                    : 'No expiry date set',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now()
                                      .add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() => _expiryDate = date);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: cardPadding(context),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: spacingLG(context)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: spacingMD(context)),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _addDiscount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RufkoTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: spacingLG(context)),
                      ),
                      child: const Text('Add Discount'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDiscount() {
    if (!_formKey.currentState!.validate()) return;

    final discount = QuoteDiscount(
      type: _type,
      value: double.parse(_valueController.text),
      code: _codeController.text.isEmpty ? null : _codeController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      applyToAddons: _applyToAddons,
      expiryDate: _expiryDate,
    );

    widget.onDiscountAdded(discount);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
