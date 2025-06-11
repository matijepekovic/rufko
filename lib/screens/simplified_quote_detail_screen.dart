// lib/screens/simplified_quote_detail_screen.dart - ENHANCED WITH DISCOUNTS


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/pdf_generation_controller.dart';
import '../controllers/quote_detail_controller.dart';
import '../dialogs/template_selection_dialog.dart';
import '../models/customer.dart';
import '../models/simplified_quote.dart';
import '../providers/app_state_provider.dart';
import '../theme/rufko_theme.dart';
import '../widgets/discounts_section.dart';
import '../widgets/level_details_card.dart';
import '../widgets/level_selector_card.dart';
import '../widgets/quote_header_card.dart';
import '../widgets/quote_total_card.dart';
import 'pdf_preview_screen.dart';
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
  State<SimplifiedQuoteDetailScreen> createState() => _SimplifiedQuoteDetailScreenState();
}

class _SimplifiedQuoteDetailScreenState extends State<SimplifiedQuoteDetailScreen> {
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
                  onSelected: (action) =>
                      _controller.handleMenuAction(context, action, _pdfController),
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
                          Text('Delete Quote', style: TextStyle(color: Colors.red)),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuoteHeader(),
              const SizedBox(height: 24),
              _buildLevelSelector(),
              const SizedBox(height: 24),
              if (_controller.selectedLevelId != null) _buildSelectedLevelDetails(),
              const SizedBox(height: 24),
              _buildAddonsSection(),
              const SizedBox(height: 24),
              _buildDiscountsSection(),
              const SizedBox(height: 24),
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
    final level = widget.quote.levels.firstWhere((l) => l.id == _controller.selectedLevelId!);
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optional Add-ons:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...widget.quote.addons.map((addon) => ListTile(
              dense: true,
              title: Text(addon.productName),
              subtitle: Text('${addon.quantity.toStringAsFixed(1)} ${addon.unit} @ ${_currencyFormat.format(addon.unitPrice)} each'),
              trailing: Text(_currencyFormat.format(addon.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add-ons Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_currencyFormat.format(widget.quote.addons.fold(0.0, (sum, addon) => sum + addon.totalPrice)),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pdfController.generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF'),
          ),
        ),
        const SizedBox(width: 12),
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
              ? context.read<AppStateProvider>().roofScopeDataList
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

class _DiscountDialogState extends State<_DiscountDialog> {
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
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clean Header - matching your blue theme
            Container(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Discount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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
                padding: const EdgeInsets.all(20),
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
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage Discount')),
                          DropdownMenuItem(value: 'fixed_amount', child: Text('Fixed Amount Discount')),
                          DropdownMenuItem(value: 'voucher', child: Text('Voucher Code')),
                        ],
                        onChanged: (value) => setState(() => _type = value!),
                      ),

                      const SizedBox(height: 16),

                      // Value Input
                      TextFormField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          labelText: _type == 'percentage' ? 'Percentage (%)' : 'Amount (\$)',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(_type == 'percentage' ? Icons.percent : Icons.attach_money),
                          suffixText: _type == 'percentage' ? '%' : null,
                          prefixText: _type == 'fixed_amount' ? '\$ ' : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final num = double.tryParse(value);
                          if (num == null || num <= 0) return 'Enter valid positive number';
                          if (_type == 'percentage' && num > 100) return 'Cannot exceed 100%';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Voucher Code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.confirmation_number),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) => value == null || value.isEmpty ? 'Code required for vouchers' : null,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Options
                      Card(
                        elevation: 0,
                        color: Colors.grey[50],
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Apply to Add-ons'),
                              subtitle: const Text('Include add-on products in discount'),
                              value: _applyToAddons,
                              onChanged: (value) => setState(() => _applyToAddons = value),
                            ),
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Expiry Date'),
                              subtitle: Text(
                                _expiryDate != null
                                    ? DateFormat('MMM dd, yyyy').format(_expiryDate!)
                                    : 'No expiry date set',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) setState(() => _expiryDate = date);
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
              padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _addDiscount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RufkoTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
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