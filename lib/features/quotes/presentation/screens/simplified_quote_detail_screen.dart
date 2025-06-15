// lib/screens/simplified_quote_detail_screen.dart - ENHANCED WITH DISCOUNTS

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/pdf_generation_controller.dart';
import '../controllers/quote_detail_controller.dart';
import '../controllers/quote_totals_controller.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../core/mixins/ui/responsive_text_mixin.dart';
import '../../../../core/mixins/ui/responsive_widget_mixin.dart';
import '../widgets/sections/discounts_section.dart';
import '../widgets/cards/level_details_card.dart';
import '../widgets/cards/level_selector_card.dart';
import '../widgets/cards/quote_header_card.dart';
import '../widgets/cards/quote_total_card.dart';
import '../widgets/sections/addons_section.dart';
import '../widgets/dialogs/discount_dialog.dart';

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
        ResponsiveWidgetMixin {
  late final QuoteDetailController _controller;
  late PDFGenerationController _pdfController;
  late QuoteTotalsController _totalsController;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _controller = QuoteDetailController(
      quote: widget.quote,
      customer: widget.customer,
    );
    _totalsController = QuoteTotalsController(
      quote: widget.quote,
      selectedLevelId: _controller.selectedLevelId ?? '',
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
      if (_controller.selectedLevelId != null) {
        _totalsController.selectedLevelId = _controller.selectedLevelId!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
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
        body: SingleChildScrollView(
          padding: EdgeInsets.all(spacingSM(context) * 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuoteHeader(),
              SizedBox(height: spacingXL(context)),
              _buildLevelSelector(),
              SizedBox(height: spacingXL(context)),
              if (_controller.selectedLevelId != null)
                _buildSelectedLevelDetails(),
              SizedBox(height: spacingXL(context)),
              AddonsSection(
                  quote: widget.quote, currencyFormat: _currencyFormat),
              SizedBox(height: spacingXL(context)),
              _buildDiscountsSection(),
              SizedBox(height: spacingXL(context)),
              _buildTotalSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
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
    return LevelSelectorCard(
      levels: widget.quote.levels,
      selectedLevelId: _controller.selectedLevelId,
      onLevelSelected: _controller.selectLevel,
      currencyFormat: _currencyFormat,
      getTotalForLevel: widget.quote.getDisplayTotalForLevel,
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
      controller: _totalsController,
      currencyFormat: _currencyFormat,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pdfController.generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF'),
          ),
        ),
        SizedBox(width: spacingMD(context)),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _controller.updateQuoteStatus(context),
            icon: const Icon(Icons.send),
            label: Text(_controller.getStatusButtonText()),
          ),
        ),
      ],
    );
  }

  void _addDiscount() {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
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
