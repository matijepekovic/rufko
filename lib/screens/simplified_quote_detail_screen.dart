// lib/screens/simplified_quote_detail_screen.dart - ENHANCED WITH DISCOUNTS


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/simplified_quote.dart';
import '../models/customer.dart';
import '../providers/app_state_provider.dart';
import '../models/pdf_template.dart';
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
  String? _selectedLevelId;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _selectedLevelId = widget.quote.levels.isNotEmpty ? widget.quote.levels.first.id : null;
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
              title: Text('Quote ${widget.quote.quoteNumber}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.preview),
                  onPressed: _previewPdf,
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
                  onSelected: _handleMenuAction,
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
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate Quote'),
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
              if (_selectedLevelId != null) _buildSelectedLevelDetails(),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: ${widget.customer.name}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (widget.customer.fullDisplayAddress.isNotEmpty && widget.customer.fullDisplayAddress != 'No address provided')
                        Padding( // Optional: Add some padding for the address
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(widget.customer.fullDisplayAddress, style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      Text('Quote ID: ${widget.quote.id}', style: Theme.of(context).textTheme.bodySmall),
                      Text('Created: ${DateFormat('MMM dd, yyyy').format(widget.quote.createdAt)}'),
                      Text('Valid Until: ${DateFormat('MMM dd, yyyy').format(widget.quote.validUntil)}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.quote.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.quote.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    if (widget.quote.levels.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No levels configured.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Quote Level:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: widget.quote.levels.map((level) {
                final isSelected = _selectedLevelId == level.id;
                final total = widget.quote.getDisplayTotalForLevel(level.id);

                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(level.name, style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(_currencyFormat.format(total),
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedLevelId = level.id);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLevelDetails() {
    final level = widget.quote.levels.firstWhere((l) => l.id == _selectedLevelId!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${level.name} Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Base Product
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base Product: ${widget.quote.baseProductName ?? "N/A"}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Quantity: ${level.baseQuantity.toStringAsFixed(1)} ${widget.quote.baseProductUnit ?? "units"}'),
                      Text('Unit Price: ${_currencyFormat.format(level.basePrice)}'),
                    ],
                  ),
                  Text(_currencyFormat.format(level.baseProductTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),

            if (level.includedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Additional Items:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...level.includedItems.map((item) => ListTile(
                dense: true,
                title: Text(item.productName),
                subtitle: Text('${item.quantity.toStringAsFixed(1)} ${item.unit} @ ${_currencyFormat.format(item.unitPrice)} each'),
                trailing: Text(_currencyFormat.format(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ],

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Level Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_currencyFormat.format(level.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
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
    if (widget.quote.discounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('No discounts applied', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _addDiscount,
                icon: const Icon(Icons.add),
                label: const Text('Add Discount or Voucher'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Applied Discounts:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addDiscount,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.quote.discounts.map((discount) => _buildDiscountItem(discount)),
            if (_selectedLevelId != null) ...[
              const Divider(),
              _buildDiscountSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountItem(QuoteDiscount discount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: discount.isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: discount.isValid ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            discount.isValid ? Icons.check_circle : Icons.error,
            color: discount.isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discount.description ?? '${discount.type.toUpperCase()} Discount',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  discount.type == 'percentage'
                      ? '${discount.value.toStringAsFixed(1)}% off'
                      : _currencyFormat.format(discount.value),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (discount.code != null)
                  Text('Code: ${discount.code}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (discount.isExpired)
                  Text('EXPIRED', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeDiscount(discount.id),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSummary() {
    final summary = widget.quote.getDiscountSummary(_selectedLevelId!);
    final totalDiscount = summary['totalDiscount'] as double;

    if (totalDiscount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Level Discount:', style: TextStyle(fontSize: 12)),
              Text('-${_currencyFormat.format(summary['levelDiscount'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
            ],
          ),
          if (summary['addonDiscount'] > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add-on Discount:', style: TextStyle(fontSize: 12)),
                Text('-${_currencyFormat.format(summary['addonDiscount'])}',
                    style: const TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          const Divider(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Savings:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('-${_currencyFormat.format(totalDiscount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    if (_selectedLevelId == null) return const SizedBox.shrink();

    final level = widget.quote.levels.firstWhere((l) => l.id == _selectedLevelId!);
    final levelSubtotal = level.subtotal;
    final addonSubtotal = widget.quote.addons.fold(0.0, (sum, addon) => sum + addon.totalPrice);
    final combinedSubtotal = levelSubtotal + addonSubtotal;

    // Get discount information
    final discountSummary = widget.quote.getDiscountSummary(_selectedLevelId!);
    final totalDiscount = discountSummary['totalDiscount'] as double;
    final subtotalAfterDiscount = combinedSubtotal - totalDiscount;

    // 🔧 FIX: Ensure tax rate is properly retrieved and calculated
    final taxRate = widget.quote.taxRate;
    final taxAmount = subtotalAfterDiscount * (taxRate / 100);
    final finalTotal = subtotalAfterDiscount + taxAmount;

    // 🐛 DEBUG: Print values to console
    debugPrint('🧮 TAX CALCULATION DEBUG:');
    debugPrint('   Level Subtotal: \$${levelSubtotal.toStringAsFixed(2)}');
    debugPrint('   Addon Subtotal: \$${addonSubtotal.toStringAsFixed(2)}');
    debugPrint('   Combined Subtotal: \$${combinedSubtotal.toStringAsFixed(2)}');
    debugPrint('   Total Discount: \$${totalDiscount.toStringAsFixed(2)}');
    debugPrint('   Subtotal After Discount: \$${subtotalAfterDiscount.toStringAsFixed(2)}');
    debugPrint('   Tax Rate: ${taxRate.toStringAsFixed(2)}%');
    debugPrint('   Tax Amount: \$${taxAmount.toStringAsFixed(2)}');
    debugPrint('   Final Total: \$${finalTotal.toStringAsFixed(2)}');

    return Card(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Subtotal row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                Text(
                  _currencyFormat.format(combinedSubtotal),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            // Discount row (only show if discount > 0)
            if (totalDiscount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:', style: TextStyle(color: Colors.green, fontSize: 16)),
                  Text(
                    '-${_currencyFormat.format(totalDiscount)}',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ],
              ),
            ],

            // Tax row (only show if tax rate > 0)
            if (taxRate > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (${taxRate.toStringAsFixed(1)}%):',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    _currencyFormat.format(taxAmount),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),

            // Final Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currencyFormat.format(finalTotal),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _previewPdf() async {
    try {
      final appState = context.read<AppStateProvider>();

      // Find existing PDF for this quote
      final existingPdf = appState.projectMedia.where((media) =>
      media.customerId == widget.customer.id &&
          media.quoteId == widget.quote.id &&
          media.isPdf &&
          media.tags.contains('quote')
      ).toList();

      if (existingPdf.isEmpty) {
        // No existing PDF found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved PDF found. Use "Generate PDF" to create one first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Use the most recent PDF
      final latestPdf = existingPdf.last;

      // Check if file still exists
      final file = File(latestPdf.filePath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF file not found: ${latestPdf.fileName}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Open existing PDF in preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: latestPdf.filePath,
            suggestedFileName: latestPdf.fileName,
            quote: widget.quote,
            customer: widget.customer,
            title: 'Saved PDF Preview',
            isPreview: true,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _generatePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _updateQuoteStatus,
            icon: const Icon(Icons.send),
            label: Text(_getStatusButtonText()),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.grey;
      case 'sent': return Colors.blue;
      case 'accepted': return Colors.green;
      case 'declined': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusButtonText() {
    switch (widget.quote.status.toLowerCase()) {
      case 'draft': return 'Send Quote';
      case 'sent': return 'Mark Accepted';
      case 'accepted': return 'Mark Complete';
      default: return 'Update Status';
    }
  }

  void _addDiscount() {
    showDialog(
      context: context,
      builder: (context) => _DiscountDialog(
        onDiscountAdded: (discount) {
          setState(() {
            widget.quote.addDiscount(discount);
          });
          context.read<AppStateProvider>().updateSimplifiedQuote(widget.quote);
        },
      ),
    );
  }

  void _removeDiscount(String discountId) {
    setState(() {
      widget.quote.removeDiscount(discountId);
    });
    context.read<AppStateProvider>().updateSimplifiedQuote(widget.quote);
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

  // Add this to your existing lib/screens/simplified_quote_detail_screen.dart

// Update the _generatePdf method to include template selection:
  // In lib/screens/simplified_quote_detail_screen.dart
// REPLACE the _generatePdf method with this fixed version:

  void _generatePdf() async {
    try {
      final appState = context.read<AppStateProvider>();

      // Show template selection dialog
      final availableTemplates = appState.activePDFTemplates
          .where((t) => t.templateType == 'quote')
          .toList();

      debugPrint('🔍 Found ${availableTemplates.length} available templates');

      final selectedOption = await _showTemplateSelectionDialog(availableTemplates);

      if (selectedOption == 'cancelled') {
        debugPrint('👤 User cancelled PDF generation');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      String pdfPath;
      String? templateId;
      Map<String, String>? customData;

      if (selectedOption != null && selectedOption != 'standard') {
        // Generate using selected template
        debugPrint('📄 Generating PDF using template: $selectedOption');
        templateId = selectedOption;
        customData = {
          'generated_from': 'template',
          'template_id': selectedOption,
          'generation_date': DateTime.now().toIso8601String(),
        };

        pdfPath = await appState.generatePDFFromTemplate(
          templateId: selectedOption,
          quote: widget.quote,
          customer: widget.customer,
          selectedLevelId: _selectedLevelId,
          customData: customData,
        );
      } else {
        // Generate using standard method
        debugPrint('📄 Generating PDF using standard method');
        customData = {
          'generated_from': 'standard',
          'generation_date': DateTime.now().toIso8601String(),
        };

        pdfPath = await appState.generateSimplifiedQuotePdf(
          widget.quote,
          widget.customer,
          selectedLevelId: _selectedLevelId,
        );
      }

      Navigator.pop(context); // Close loading dialog

      // 🚀 NEW: Navigate to PDF Preview Screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: pdfPath,
            suggestedFileName: _generateSuggestedFileName(),
            quote: widget.quote,
            customer: widget.customer,
            templateId: templateId,
            selectedLevelId: _selectedLevelId,
            originalCustomData: customData,
          ),
        ),
      );

      // Handle result from preview screen
      if (result == true) {
        // PDF was saved successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('PDF saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (result == false) {
        // PDF was discarded
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('PDF was discarded'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      // If result is null, user just navigated back without action

    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

// ADD this helper method to generate suggested filename
  String _generateSuggestedFileName() {
    final quoteNumber = widget.quote.quoteNumber.replaceAll(RegExp(r'[^\w\s-]'), '');
    final customerName = widget.customer.name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return 'Quote_${quoteNumber}_${customerName}_$dateStr.pdf';
  }

// REPLACE the _showTemplateSelectionDialog method with this improved version:

  Future<String?> _showTemplateSelectionDialog(List<PDFTemplate> templates) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose PDF Generation Method'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How would you like to generate the PDF?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // 📋 Standard PDF option (ALWAYS available)
              Card(
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: const Text('Standard PDF'),
                  subtitle: const Text('Use the built-in PDF format'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.pop(context, 'standard'),
                ),
              ),

              if (templates.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Custom Templates (${templates.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),

                // 📄 Template options
                ...templates.map((template) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(template.templateName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (template.description.isNotEmpty)
                          Text(template.description),
                        Text(
                          '${template.fieldMappings.length} mapped fields',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: template.description.isNotEmpty,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.preview, size: 20),
                          onPressed: () => _previewTemplateInDialog(template),
                          tooltip: 'Preview template',
                        ),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, template.id),
                  ),
                )),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(height: 8),
                      Text(
                        'No custom templates available',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create templates in Settings → PDF Templates',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancelled'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'standard'),
            child: const Text('Use Standard PDF'),
          ),
        ],
      ),
    );
  }

// Add this new method to show template selection dialog:


  void _previewTemplateInDialog(PDFTemplate template) async {
    try {
      // Close the selection dialog first
      Navigator.pop(context);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating preview...'),
            ],
          ),
        ),
      );

      // Generate preview with current quote data
      final previewPath = await context.read<AppStateProvider>().generatePDFFromTemplate(
        templateId: template.id,
        quote: widget.quote,
        customer: widget.customer,
        selectedLevelId: _selectedLevelId,
        customData: {'preview': 'true', 'watermark': 'PREVIEW'},
      );

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preview generated: ${previewPath.split('/').last}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // TODO: Open PDF
            },
          ),
        ),
      );

      // Reshow the template selection dialog
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final templates = context.read<AppStateProvider>().activePDFTemplates
            .where((t) => t.templateType == 'quote')
            .toList();
        _showTemplateSelectionDialog(templates);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuoteStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Quote Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['draft', 'sent', 'accepted', 'declined'].map((status) =>
              ListTile(
                title: Text(status.toUpperCase()),
                onTap: () {
                  setState(() {
                    widget.quote.status = status;
                    widget.quote.updatedAt = DateTime.now();
                  });
                  context.read<AppStateProvider>().updateSimplifiedQuote(widget.quote);
                  Navigator.pop(context);
                },
              ),
          ).toList(),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'generate_pdf':
        _generatePdf();
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate functionality coming soon')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text('Are you sure you want to delete quote ${widget.quote.quoteNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteSimplifiedQuote(widget.quote.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
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
                color: Color(0xFF2E86AB),
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
                        backgroundColor: const Color(0xFF2E86AB),
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
  Widget _buildTypeCard(String value, String label, IconData icon) {
    final isSelected = _type == value;

    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.green.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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