// lib/screens/simplified_quote_detail_screen.dart - ENHANCED WITH DISCOUNTS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/simplified_quote.dart';
import '../models/customer.dart';
import '../providers/app_state_provider.dart';

class SimplifiedQuoteDetailScreen extends StatefulWidget {
  final SimplifiedMultiLevelQuote quote;
  final Customer customer;

  const SimplifiedQuoteDetailScreen({
    Key? key,
    required this.quote,
    required this.customer,
  }) : super(key: key);

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
      appBar: AppBar(
        title: Text('Quote ${widget.quote.quoteNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editQuote,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'generate_pdf', child: Text('Generate PDF')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Quote')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Quote')),
            ],
          ),
        ],
      ),
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
            _buildDiscountsSection(), // NEW - Discount management
            const SizedBox(height: 24),
            _buildTotalSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDiscount,
        icon: const Icon(Icons.local_offer),
        label: const Text('Add Discount'),
        backgroundColor: Colors.green,
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
                      if (widget.customer.address != null)
                        Text(widget.customer.address!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
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

  // NEW - Discount management section
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

    final total = widget.quote.getDisplayTotalForLevel(_selectedLevelId!);
    final level = widget.quote.levels.firstWhere((l) => l.id == _selectedLevelId!);
    final subtotal = level.subtotal + widget.quote.addons.fold(0.0, (sum, addon) => sum + addon.totalPrice);
    final discountSummary = widget.quote.getDiscountSummary(_selectedLevelId!);
    final totalDiscount = discountSummary['totalDiscount'] as double;
    final discountedSubtotal = subtotal - totalDiscount;
    final tax = discountedSubtotal * (widget.quote.taxRate / 100);

    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(_currencyFormat.format(subtotal)),
              ],
            ),
            if (totalDiscount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:', style: TextStyle(color: Colors.green)),
                  Text('-${_currencyFormat.format(totalDiscount)}', style: const TextStyle(color: Colors.green)),
                ],
              ),
            if (widget.quote.taxRate > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax (${widget.quote.taxRate.toStringAsFixed(1)}%):'),
                  Text(_currencyFormat.format(tax)),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(_currencyFormat.format(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ],
            ),
          ],
        ),
      ),
    );
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
    // Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit quote functionality coming soon')),
    );
  }

  void _generatePdf() async {
    try {
      final appState = context.read<AppStateProvider>();
      final pdfPath = await appState.generateSimplifiedQuotePdf(
        widget.quote,
        widget.customer,
        selectedLevelId: _selectedLevelId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generated: $pdfPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _updateQuoteStatus() {
    // Show status update dialog
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
      // TODO: Implement duplication
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// NEW - Discount creation dialog
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
    return AlertDialog(
      title: const Text('Add Discount'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                  DropdownMenuItem(value: 'fixed_amount', child: Text('Fixed Amount')),
                  DropdownMenuItem(value: 'voucher', child: Text('Voucher Code')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _type == 'percentage' ? 'Percentage (%)' : 'Amount (\$)',
                  prefixText: _type == 'fixed_amount' ? '\$ ' : null,
                  suffixText: _type == 'percentage' ? '%' : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) return 'Enter valid positive number';
                  if (_type == 'percentage' && num > 100) return 'Percentage cannot exceed 100%';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
              ),
              if (_type == 'voucher') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Voucher Code'),
                  validator: (value) => _type == 'voucher' && (value == null || value.isEmpty) ? 'Code required for vouchers' : null,
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Apply to Add-ons'),
                value: _applyToAddons,
                onChanged: (value) => setState(() => _applyToAddons = value),
              ),
              ListTile(
                title: const Text('Expiry Date (Optional)'),
                subtitle: Text(_expiryDate != null ? DateFormat('MMM dd, yyyy').format(_expiryDate!) : 'No expiry'),
                trailing: const Icon(Icons.calendar_today),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _addDiscount,
          child: const Text('Add Discount'),
        ),
      ],
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